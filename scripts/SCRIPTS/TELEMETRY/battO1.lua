-- FPVStats v5.1 - RadioMaster Boxer B&W · EdgeTX · ELRS
-- Generic: auto-detects 1S-6S LiPo/HV LiPo
--
-- Install: SD card → SCRIPTS/TELEMETRY/fpvstats.lua
--
-- Changelog (v5.1):
--   - Fix: Battery health no longer resets on disarm or RX loss.
--     Health resets only on confirmed battery swap or manual long-press
--     ENTER (same trigger as timer reset — simple, predictable).
--   - Simplified: Removed separate resetFlightSession / resetHealthOnly.
--     One resetBattery() for everything; health follows timer reset.
--   - Added: Batt% sensor support — uses FC-reported percentage when
--     available, falls back to voltage-based calculation.
--   - UI fix: Header no longer clips timer on large capacity labels.
--     Compact capacity format (1.3k instead of 1300) and dynamic timer
--     positioning prevent overlap.

local CFG = {
    -- Voltage thresholds per cell
    warnV = 3.55, -- per-cell warn
    critV = 3.30, -- per-cell critical
    armV = 3.20, -- per-cell minimum = battery connected

    -- HV auto-detection threshold
    -- Resting cell voltage above this = HV LiPo (4.35V max)
    -- below this = standard LiPo (4.20V max)
    hvThresh = 4.22, -- cells resting above 4.22V = HV

    -- Capacity-health qualification thresholds
    healthStartV = 4.15, -- first armed per-cell voltage must start at or above this
    healthEndV = 3.30, -- lowest armed per-cell voltage must reach at or below this

    -- New battery detection
    newBattDelta = 0.20, -- per-cell voltage rise > 200mV = new battery
    battSwapMinS = 15,   -- minimum seconds disconnected to count as a swap
                         -- crash cuts are usually <5s; a real swap takes ≥15s

    -- Link quality
    lqWarn = 70,
    lqCrit = 50,
}
CFG.minV = 3.00

-- ── Cell count auto-detection ────────────────────────────────────
-- Detects 1S-6S by checking which band the pack voltage falls in.
-- Uses resting voltage ranges (battery just connected, no load).
--   1S: 3.20 -  4.40V
--   2S: 6.40 -  8.80V
--   3S: 9.60 - 13.20V
--   4S: 12.80- 17.60V  (overlaps 3S slightly, resolved by upper bound)
--   5S: 16.00- 22.00V
--   6S: 19.20- 26.40V
-- Cell detection bands.
-- 5S and 6S overlap in voltage space when one is full and other is low.
-- Detection is done once at connect (resting, near full charge) so
-- the boundary at 22.00V reliably separates them:
--   5S HV full  = 21.75V  → below 22.00 = 5S correct
--   6S HV full  = 26.10V  → above 22.00 = 6S correct
--   6S std full = 25.20V  → above 22.00 = 6S correct
-- All other bands have clean separation with no overlap.
local CELL_BANDS = {
    { cells = 1, lo = 3.20, hi = 5.50 },
    { cells = 2, lo = 5.50, hi = 9.00 },
    { cells = 3, lo = 9.00, hi = 12.50 },
    { cells = 4, lo = 12.50, hi = 16.00 },
    { cells = 5, lo = 16.00, hi = 22.00 },
    { cells = 6, lo = 22.00, hi = 99.00 },
}

local COMMON_CAPS = { 300, 450, 500, 550, 650, 850, 1000, 1300, 1500, 2200, 3000 }
local AUTO_CAP_BY_CELLS = {
    [1] = 500,
    [2] = 450,
    [3] = 850,
    [4] = 1500,
    [5] = 2200,
    [6] = 3000,
}

local function detectCells(packV)
    -- Use >= lo and < hi so boundaries are unambiguous
    for i = 1, #CELL_BANDS do
        local b = CELL_BANDS[i]
        if packV >= b.lo and packV < b.hi then
            return b.cells
        end
    end
    return nil
end

-- ── Sensor IDs ───────────────────────────────────────────────────
local ID = { voltage = -1, current = -1, capa = -1, lq = -1, rssi1 = -1, rssi2 = -1, fm = -1, battpct = -1 }

-- ── State ────────────────────────────────────────────────────────
local cellCount = nil   -- auto-detected or manually set
local cellManual = nil   -- nil = auto / 1-6 = manually overridden
local hvLipo = nil   -- auto-detected: true=HV(4.35V) false=std(4.20V)
local maxV = 4.35  -- set after HV detection
local armed = false
local flightTime = 0
local segStart = 0
local startV = nil   -- per-cell voltage at first arm
local minFlightV = nil   -- lowest per-cell voltage seen while armed
local lastPackV = nil   -- last known pack voltage (for new-batt detect)
local batteryUsed = false
local disconnectTime = nil  -- getTime() when packV first went nil this session
local nominalMah = 500
local startCapa = nil
local usedMah = 0
local usedMahEstimated = false
local startedFull = false
local lastCurrentTick = nil
local baselineCellV = nil   -- best resting per-cell voltage seen for this pack
local lastCapaSeen = nil

-- Alert state
local lastWarnTime = 0
local lastCritTime = 0
local warnInterval = 1500  -- ticks = 15 sec
local critInterval = 1000  -- ticks = 10 sec
local warnAlerted = false
local critAlerted = false

-- ── Helpers ──────────────────────────────────────────────────────
local function getTelemetryId(name)
    local f = getFieldInfo(name)
    return f and f.id or -1
end

local function sensorGet(id)
    if id == -1 then
        return nil
    end
    local v = getValue(id)
    return (type(v) == "number" and v > 0) and v or nil
end

local function sensorGetAny(id)
    if id == -1 then
        return nil
    end
    local v = getValue(id)
    return type(v) == "number" and v or nil
end

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function voltPct(cellV)
    if not cellV then
        return 0
    end
    return clamp(
            math.floor((cellV - CFG.minV) / (maxV - CFG.minV) * 100 + 0.5),
            0, 100)
end

local function idiv(a, b)
    return math.floor(a / b)
end

local function fmtTime(secs)
    return string.format("%d:%02d", idiv(secs, 60), secs % 60)
end

local function fmtMah(v)
    return tostring(math.floor(v + 0.5))
end

-- Compact capacity label: 1300 → "1.3k", 3000 → "3k", 500 → "500"
local function fmtCapacityShort(mah)
    if mah >= 1000 and mah % 1000 ~= 0 then
        return string.format("%.1fk", mah / 1000)
    elseif mah >= 1000 then
        return string.format("%dk", mah // 1000)
    else
        return tostring(mah)
    end
end

local function bestRSSI()
    local a = sensorGetAny(ID.rssi1)
    local b = sensorGetAny(ID.rssi2)
    if a and b then
        return math.max(a, b)
    end
    return a or b
end

-- Returns the clean flight mode name (no trailing *, abbreviated to ≤4 chars).
-- Returns "" when sensor is unavailable.
local function getFlightMode()
    if ID.fm == -1 then return "" end
    local v = getValue(ID.fm)
    if type(v) ~= "string" or v == "" then return "" end
    -- Strip trailing * (disarmed marker used by Betaflight CRSF telemetry)
    local name = (string.sub(v, -1) == "*") and string.sub(v, 1, -2) or v
    if name == ""         then return "" end
    if name == "HORIZON"  then return "HOR"  end
    if name == "ANGLE"    then return "ANGL" end
    if name == "FAILSAFE" then return "FAIL" end
    if #name > 4          then return string.sub(name, 1, 4) end
    return name
end

local function defaultNominalMah(cells)
    return cells and AUTO_CAP_BY_CELLS[cells] or nil
end

local function isArmed()
    if ID.fm == -1 then
        return false
    end
    local v = getValue(ID.fm)
    if type(v) ~= "string" then
        return false
    end
    -- Betaflight: active mode has NO trailing * on this radio
    return string.sub(v, -1) ~= "*"
end

-- ── Reset ────────────────────────────────────────────────────────
-- Single reset function for both battery swap and manual long-press.
-- Health follows timer reset: same trigger, same logic.
-- Called on confirmed battery swap OR manual long-press ENTER.
-- NOT called on disarm — health persists across disarms/RX loss.
local function resetBattery()
    armed         = false
    flightTime    = 0
    segStart      = 0
    startV        = nil
    minFlightV    = nil
    cellCount     = nil   -- re-detect on next battery
    hvLipo        = nil   -- re-detect HV on next battery
    batteryUsed   = false
    warnAlerted   = false
    critAlerted   = false
    lastWarnTime  = 0
    lastCritTime  = 0
    disconnectTime = nil  -- clear any pending disconnect tracking
    startCapa     = nil
    usedMah       = 0
    usedMahEstimated = false
    startedFull   = false
    lastCurrentTick = nil
    baselineCellV = nil
    lastCapaSeen  = nil
end

-- ── Init ─────────────────────────────────────────────────────────
local function init_func()
    ID.voltage = getTelemetryId("RxBt")
    ID.current = getTelemetryId("Curr")
    ID.capa = getTelemetryId("Capa")
    ID.lq = getTelemetryId("RQly")
    ID.rssi1 = getTelemetryId("1RSS")
    ID.rssi2 = getTelemetryId("2RSS")
    ID.fm = getTelemetryId("FM")
    -- Battery percentage from FC (prefer over voltage-based calculation)
    ID.battpct = getTelemetryId("Batt%")
    if ID.battpct == -1 then
        ID.battpct = getTelemetryId("Fuel")
    end
end

-- Center zone -100 to +100 = AUTO detect
-- Right of center +101 to +1024: every 100 units = 1S,2S,3S,4S,5S,6S
-- Left of center -101 to -1024: every 100 units = 1S,2S,3S,4S,5S,6S
local function readS1Cells()
    local v = getValue("s1")
    if type(v) ~= "number" then
        return nil
    end
    if v >= -100 and v <= 100 then
        return 0  -- AUTO
    end
    -- both directions: strip dead zone then map every 100 units to a cell
    local offset = v > 0 and (v - 101) or (-v - 101)
    local cells = math.floor(offset / 154) % 6 + 1  -- 923/6=154 units per cell
    return cells
end

local function readS2Capacity()
    local v = getValue("s2")
    if type(v) ~= "number" then
        return nil, nil
    end
    if v >= -100 and v <= 100 then
        return "auto", nil
    end
    if v > 0 then
        local span = 923 / #COMMON_CAPS
        local idx = math.floor((v - 101) / span) + 1
        idx = clamp(idx, 1, #COMMON_CAPS)
        return "preset", COMMON_CAPS[idx]
    end

    local minMah = 100
    local maxMah = 3000
    local stepMah = 50
    local steps = idiv(maxMah - minMah, stepMah) + 1
    local span = 923 / steps
    local idx = math.floor((-v - 101) / span)
    idx = clamp(idx, 0, steps - 1)
    return "linear", minMah + idx * stepMah
end

local function currentNominalLabel()
    local capMode, capValue = readS2Capacity()
    if capMode == "auto" then
        return fmtCapacityShort(nominalMah)
    end
    if capValue then
        return fmtCapacityShort(capValue) .. "*"
    end
    return fmtCapacityShort(nominalMah) .. "?"
end

-- ── Background ───────────────────────────────────────────────────
local function bg_func()
    -- S1 knob: 0 = AUTO, 1-6 = manual override
    local s1pos = readS1Cells()
    if s1pos ~= nil and s1pos >= 1 then
        -- Manual override — set both
        cellManual = s1pos
        cellCount = s1pos
    elseif s1pos == 0 then
        -- Switched back to AUTO — clear manual and cellCount so detection re-runs
        if cellManual ~= nil then
            cellManual = nil
            cellCount = nil
        end
    end
    -- s1pos == nil means getValue failed — leave state unchanged

    local packV = sensorGet(ID.voltage)

    -- Auto-detect only when not manually overridden and not yet detected
    if packV and cellManual == nil and cellCount == nil then
        cellCount = detectCells(packV)
    end

    local cellV = (packV and cellCount) and (packV / cellCount) or nil

    local capMode, capValue = readS2Capacity()
    if capMode == "auto" then
        local autoMah = defaultNominalMah(cellCount)
        if autoMah then
            nominalMah = autoMah
        end
    elseif capValue then
        nominalMah = capValue
    end

    -- Auto-detect HV vs standard once per battery (use resting voltage)
    -- Only detect when not armed (no load) and cell count known
    if cellV and hvLipo == nil and not armed then
        if cellV > CFG.hvThresh then
            hvLipo = true
            maxV = 4.35
        else
            hvLipo = false
            maxV = 4.20
        end
    end

    if cellV and not armed and (not batteryUsed or startV == nil) then
        if baselineCellV == nil or cellV > baselineCellV then
            baselineCellV = cellV
        end
    end

    local capaNow = sensorGetAny(ID.capa)
    local currNow = sensorGetAny(ID.current)
    local now = getTime()
    local prevCapaSeen = lastCapaSeen

    -- ── Battery swap detection (time-gated) ─────────────────────────
    -- Problem: a crash causes a brief power cut (<5s) then voltage recovers
    -- (sag clears) which would trip a naive voltage-rise check.
    -- Solution: require the battery to have been absent for at least
    -- CFG.battSwapMinS seconds AND the per-cell voltage to be higher.
    -- You cannot physically swap a battery in <15s, so this cleanly
    -- separates real swaps from crash reconnects.
    if packV == nil then
        -- Power lost — start the disconnect clock (once per absence)
        if batteryUsed and disconnectTime == nil then
            disconnectTime = getTime()
        end
    else
        if disconnectTime ~= nil then
            -- Power just returned — only reset if it looks like a fresh pack,
            -- not the same battery recovering from sag after a telemetry drop.
            local outSecs    = idiv(getTime() - disconnectTime, 100)
            local returnCells = cellManual or cellCount or detectCells(packV)
            local returnCellV = returnCells and (packV / returnCells) or nil
            local cellsChanged = (cellCount ~= nil and returnCells ~= nil and returnCells ~= cellCount)
            local capaReset = (capaNow ~= nil and prevCapaSeen ~= nil and capaNow + 25 < prevCapaSeen)
            local freshEnough = returnCellV ~= nil and returnCellV >= CFG.healthStartV
            local aboveBaseline = baselineCellV ~= nil and returnCellV ~= nil
                    and returnCellV >= (baselineCellV + 0.05)
            local swapDetected = cellsChanged or capaReset or (ID.capa == -1 and freshEnough and aboveBaseline)
            if outSecs >= CFG.battSwapMinS and swapDetected then
                resetBattery()
                cellCount = detectCells(packV)
                cellV     = cellCount and (packV / cellCount) or nil
                baselineCellV = cellV
            end
            disconnectTime = nil
        end
        if packV > 0 then lastPackV = packV end
    end

    if capaNow ~= nil then
        lastCapaSeen = capaNow
    end

    -- Arm/disarm
    local nowArmed = isArmed()
    if nowArmed and not armed then
        -- ── Arming: keep existing health data if already tracking ──
        -- startV is only set on the FIRST arm per battery session.
        -- Subsequent re-arms (after crash / RX loss) keep the original
        -- startV so health tracking reflects the full battery usage,
        -- not just the last flight segment.
        armed = true
        segStart = now
        if startV == nil and cellV then
            startV = cellV
            startedFull = cellV >= CFG.healthStartV
        end
        if minFlightV == nil and cellV and cellV > CFG.armV then
            minFlightV = cellV
        end
        if startCapa == nil and capaNow ~= nil then
            startCapa = capaNow
            usedMahEstimated = false
        elseif startCapa == nil then
            usedMahEstimated = true
        end
        lastCurrentTick = now
        batteryUsed = true
    elseif not nowArmed and armed then
        -- ── Disarming: save flight time, keep health data ──
        -- Health (startV, minFlightV, usedMah, etc.) persists across
        -- disarms. Only a battery swap or manual reset clears it.
        flightTime = flightTime + idiv(now - segStart, 100)
        armed = false
        lastCurrentTick = nil
    end

    if armed then
        if cellV and cellV > CFG.armV then
            if minFlightV == nil or cellV < minFlightV then
                minFlightV = cellV
            end
        end

        if capaNow ~= nil and startCapa ~= nil then
            usedMah = math.max(0, capaNow - startCapa)
            usedMahEstimated = false
        elseif currNow ~= nil and currNow > 0 and lastCurrentTick ~= nil then
            local dt = now - lastCurrentTick
            if dt > 0 then
                usedMah = usedMah + (currNow * dt) / 360
                usedMahEstimated = true
            end
        end
        lastCurrentTick = now
    end

    -- ── Audio/haptic alerts (armed / in-flight only) ─────────────────
    -- Never alert on the bench or post-landing. The FC's disarm signal
    -- (trailing * in FM) clears the `armed` flag, stopping all alerts.
    if armed and cellV and cellV > 2.80 then
        if cellV <= CFG.critV then
            -- Critical: haptic vibration + batcrt.wav every 10s
            if (now - lastCritTime) > critInterval then
                playHaptic(100, 300)  -- strength=100, duration=300ms
                playFile("/SOUNDS/en/SCRIPTS/INAV/batcrt.wav")
                lastCritTime = now
                critAlerted  = true
            end
            -- keep warn timer alive so it does not re-trigger if voltage bounces up
            lastWarnTime = now
        elseif cellV <= CFG.warnV then
            -- Low: batlow.wav once then every 15s
            if not warnAlerted or (now - lastWarnTime) > warnInterval then
                playFile("/SOUNDS/en/SCRIPTS/INAV/batlow.wav")
                lastWarnTime = now
                warnAlerted  = true
            end
        end
    end
end

-- ── Run ──────────────────────────────────────────────────────────
local function run_func(event, touchState)
    -- Manual reset: long-press ENTER while disarmed.
    -- Resets timer + health + cell detection (full reset).
    -- Disarm guard prevents accidental in-flight reset.
    -- Cell count and HV are immediately re-detected from voltage.
    if event == EVT_VIRTUAL_ENTER_LONG and not armed then
        resetBattery()
    end

    lcd.clear()

    local W = LCD_W
    local H = LCD_H
    local mid = idiv(W, 2)
    local c2 = mid + 4

    local packV = sensorGet(ID.voltage)
    local cellV = (packV and cellCount) and (packV / cellCount) or nil
    local capaNow = sensorGetAny(ID.capa)
    local currNow = sensorGetAny(ID.current)
    local lq = sensorGetAny(ID.lq)
    local rssi = bestRSSI()

    -- Prefer FC-reported Batt% over voltage-based calculation
    local fcPct = sensorGetAny(ID.battpct)
    local pct = fcPct and clamp(math.floor(fcPct + 0.5), 0, 100) or voltPct(cellV)

    local ft = flightTime
    if armed then
        ft = ft + idiv(getTime() - segStart, 100)
    end

    local function vf(cv)
        if not cv then
            return INVERS + BLINK
        end
        if cv <= CFG.critV then
            return INVERS + BLINK
        end
        if cv <= CFG.warnV then
            return INVERS
        end
        return 0
    end

    local function lf(q)
        if not q then
            return INVERS + BLINK
        end
        if q <= CFG.lqCrit then
            return INVERS + BLINK
        end
        if q <= CFG.lqWarn then
            return INVERS
        end
        return 0
    end

    -- ── Header ───────────────────────────────────────────────────
    -- Layout: [6S HV 3k*]···[5:23]···[ACRO ARM]
    -- Left label width varies; timer position adapts so it never
    -- overlaps the label.  Mode+state stays right-aligned.
    local hvStr   = hvLipo == true and "HV" or (hvLipo == false and "ST" or "?")
    local manStr  = cellManual and "*" or ""
    local cellStr = cellCount and (cellCount .. "S" .. manStr) or "?S"
    local capLabel = currentNominalLabel()
    local leftLabel = cellStr .. " " .. hvStr .. " " .. capLabel
    lcd.drawText(0, 0, leftLabel, SMLSIZE + INVERS)

    -- Approximate left label width in pixels (SMLSIZE char ≈ 6px)
    local leftWidth = #leftLabel * 6 + 4
    -- Timer: at least 4px gap after label, but prefer center
    local timerX = math.max(leftWidth, idiv(W, 2) - 12)

    local fmName = getFlightMode()  -- e.g. "ACRO", "HOR", "ANGL", "FAIL", ""

    -- Helper: draw state label then flight mode immediately to its left.
    -- Each SMLSIZE char is ~6px wide; this gives a right-aligned mode+state pair.
    local function drawModeState(stateStr, stateFlags)
        local stateX = W - #stateStr * 6 - 2
        lcd.drawText(stateX, 0, stateStr, SMLSIZE + stateFlags)
        if fmName ~= "" then
            local mf = (fmName == "FAIL") and (INVERS + BLINK) or 0
            lcd.drawText(stateX - #fmName * 6 - 3, 0, fmName, SMLSIZE + mf)
        end
    end

    if armed then
        local bl = (idiv(getTime(), 100) % 2 == 0) and INVERS or 0
        lcd.drawText(timerX, 0, fmtTime(ft), SMLSIZE + bl)
        drawModeState("ARM", INVERS)
    elseif ft > 0 then
        lcd.drawText(timerX, 0, fmtTime(ft), SMLSIZE)
        drawModeState("DONE", 0)
    else
        lcd.drawText(timerX, 0, "0:00", SMLSIZE)
        drawModeState("RDY", 0)
    end

    lcd.drawLine(0, 9, W - 1, 9, SOLID, 0)
    lcd.drawLine(mid, 9, mid, H - 1, SOLID, 0)
    lcd.drawLine(mid, 34, W - 1, 34, DOTTED, 0)

    -- ── Left: Voltage ────────────────────────────────────────────
    lcd.drawText(2, 11, "BATTERY", SMLSIZE)
    if cellV then
        -- show both pack voltage and per-cell
        lcd.drawText(2, 20, string.format("%.2fV", cellV), MIDSIZE + vf(cellV))
        if cellCount and cellCount > 1 then
            lcd.drawText(2, 34, string.format("%.1fV pk", packV), SMLSIZE)
        end
        -- % source indicator: FC sensor vs voltage-based
        local pctSource = fcPct and "fc" or "v"
        -- % and bar
        local bx, by, bw, bh = 2, 42, mid - 6, 6
        lcd.drawRectangle(bx, by, bw, bh)
        local fill = math.max(1, idiv((bw - 2) * pct, 100))
        lcd.drawFilledRectangle(bx + 1, by + 1, fill, bh - 2)
        lcd.drawText(2, 50, pct .. "%" .. pctSource, SMLSIZE)
        if cellV <= CFG.critV then
            lcd.drawText(30, 50, "LAND!", SMLSIZE + INVERS + BLINK)
        elseif cellV <= CFG.warnV then
            lcd.drawText(30, 50, "LOW", SMLSIZE + INVERS)
        end
    elseif packV and cellCount == nil then
        lcd.drawText(2, 20, "DETECT...", SMLSIZE)
        lcd.drawText(2, 30, string.format("%.1fV", packV), SMLSIZE)
    else
        lcd.drawText(2, 20, "NO VBAT", SMLSIZE + INVERS + BLINK)
    end

    -- ── Right top: Link ───────────────────────────────────────────
    lcd.drawText(c2, 11, "LINK", SMLSIZE)
    if lq then
        local linkText = rssi and string.format("%d%% %ddBm", lq, math.floor(rssi))
                or string.format("%d%%", lq)
        lcd.drawText(c2, 20, linkText, SMLSIZE + lf(lq))
    else
        lcd.drawText(c2, 20, "NO LNK", SMLSIZE + INVERS + BLINK)
    end

    -- ── Right bottom: Health ──────────────────────────────────────
    lcd.drawText(c2, 37, "HEALTH:", SMLSIZE)
    local hasCapa = capaNow ~= nil or startCapa ~= nil
    local hasCurr = currNow ~= nil
    local healthQualified = batteryUsed and nominalMah > 0 and startedFull
            and minFlightV ~= nil and minFlightV <= CFG.healthEndV
    if batteryUsed and (hasCapa or usedMahEstimated or hasCurr) then
        local usedStr = fmtMah(usedMah) .. "/" .. fmtCapacityShort(nominalMah)
        local flags = 0
        local line1
        local line2
        if healthQualified then
            local healthPct = clamp(math.floor((usedMah / nominalMah) * 100 + 0.5), 0, 999)
            line1 = healthPct .. "% -"
            line2 = usedStr .. "mAh"
            if healthPct < 80 then
                flags = INVERS
            end
        elseif hasCapa or hasCurr then
            line1 = usedMahEstimated and "EST -" or "USED -"
            line2 = usedStr .. "mAh"
        else
            line1 = "NO CURR"
            flags = INVERS
        end
        lcd.drawText(c2, 45, line1, SMLSIZE + flags)
        if line2 then
            lcd.drawText(c2, 53, line2, SMLSIZE + flags)
        end
    elseif ID.capa == -1 and ID.current == -1 then
        lcd.drawText(c2, 49, "NO CAPA", SMLSIZE + INVERS)
    elseif ID.capa == -1 then
        lcd.drawText(c2, 45, "CURR ONLY", SMLSIZE)
        lcd.drawText(c2, 53, "ESTIMATE", SMLSIZE)
    elseif ID.current == -1 then
        lcd.drawText(c2, 45, "CAPA ONLY", SMLSIZE)
        lcd.drawText(c2, 53, "READY", SMLSIZE)
    else
        lcd.drawText(c2, 49, "---", SMLSIZE)
    end

    return 0
end

return { run = run_func, init = init_func, background = bg_func }