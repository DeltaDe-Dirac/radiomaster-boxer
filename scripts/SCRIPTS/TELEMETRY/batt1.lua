-- FPVStats v5.0 - RadioMaster Boxer B&W · EdgeTX · ELRS
-- Generic: auto-detects 1S-6S LiPo/HV LiPo
--
-- Install: SD card → SCRIPTS/TELEMETRY/fpvstats.lua

local CFG = {
    -- Voltage thresholds per cell
    warnV = 3.55, -- per-cell warn
    critV = 3.30, -- per-cell critical
    armV = 3.20, -- per-cell minimum = battery connected

    -- HV auto-detection threshold
    -- Resting cell voltage above this = HV LiPo (4.35V max)
    -- below this = standard LiPo (4.20V max)
    hvThresh = 4.22, -- cells resting above 4.22V = HV

    -- Battery health thresholds (voltage sag per cell)
    sagGood = 0.15, -- < 150mV sag = GOOD
    sagOk = 0.30, -- < 300mV sag = OK / >= 300mV = WEAK

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
local ID = { voltage = -1, lq = -1, rssi1 = -1, rssi2 = -1, fm = -1 }

-- ── State ────────────────────────────────────────────────────────
local cellCount = nil   -- auto-detected or manually set
local cellManual = nil   -- nil = auto / 1-6 = manually overridden
local hvLipo = nil   -- auto-detected: true=HV(4.35V) false=std(4.20V)
local maxV = 4.35  -- set after HV detection
local armed = false
local flightTime = 0
local segStart = 0
local startV = nil   -- per-cell voltage at first arm
local minV = nil   -- lowest per-cell voltage seen
local lastPackV = nil   -- last known pack voltage (for new-batt detect)
local batteryUsed = false
local disconnectTime = nil  -- getTime() when packV first went nil this session

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

local function resetBattery()
    armed         = false
    flightTime    = 0
    segStart      = 0
    startV        = nil
    minV          = nil
    cellCount     = nil   -- re-detect on next battery
    hvLipo        = nil   -- re-detect HV on next battery
    batteryUsed   = false
    warnAlerted   = false
    critAlerted   = false
    lastWarnTime  = 0
    lastCritTime  = 0
    disconnectTime = nil  -- clear any pending disconnect tracking
end

-- ── Init ─────────────────────────────────────────────────────────
local function init_func()
    ID.voltage = getTelemetryId("RxBt")
    ID.lq = getTelemetryId("RQly")
    ID.rssi1 = getTelemetryId("1RSS")
    ID.rssi2 = getTelemetryId("2RSS")
    ID.fm = getTelemetryId("FM")
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
            -- Power just returned — evaluate whether this is a new battery
            local outSecs    = idiv(getTime() - disconnectTime, 100)
            local perCellRise = (lastPackV and cellCount)
                            and ((packV - lastPackV) / cellCount) or 0
            if outSecs >= CFG.battSwapMinS and perCellRise > CFG.newBattDelta then
                -- Confirmed swap: long absence + higher voltage = fresh battery
                resetBattery()
                cellCount = detectCells(packV)
                cellV     = cellCount and (packV / cellCount) or nil
            end
            disconnectTime = nil
        end
        if packV > 0 then lastPackV = packV end
    end

    -- Track min cell voltage
    if cellV and cellV > CFG.armV then
        if minV == nil or cellV < minV then
            minV = cellV
        end
    end

    -- Arm/disarm
    local nowArmed = isArmed()
    if nowArmed and not armed then
        armed = true
        segStart = getTime()
        if startV == nil and cellV then
            startV = cellV
        end
        batteryUsed = true
    elseif not nowArmed and armed then
        flightTime = flightTime + idiv(getTime() - segStart, 100)
        armed = false
    end

    -- ── Audio/haptic alerts (armed / in-flight only) ─────────────────
    -- Never alert on the bench or post-landing. The FC's disarm signal
    -- (trailing * in FM) clears the `armed` flag, stopping all alerts.
    if armed and cellV and cellV > 2.80 then
        local now = getTime()

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
    -- Manual timer reset: long-press ENTER while disarmed.
    -- Disarm guard makes accidental in-flight reset impossible.
    if event == EVT_VIRTUAL_ENTER_LONG and not armed then
        flightTime   = 0
        warnAlerted  = false
        critAlerted  = false
        lastWarnTime = 0
        lastCritTime = 0
    end

    lcd.clear()

    local W = LCD_W
    local H = LCD_H
    local mid = idiv(W, 2)
    local c2 = mid + 4

    local packV = sensorGet(ID.voltage)
    local cellV = (packV and cellCount) and (packV / cellCount) or nil
    local lq = sensorGetAny(ID.lq)
    local rssi = bestRSSI()
    local pct = voltPct(cellV)
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
    local hvStr   = hvLipo == true and "HV" or (hvLipo == false and "ST" or "?")
    local manStr  = cellManual and "*" or ""
    local cellStr = cellCount and (cellCount .. "S" .. manStr) or "?S"
    lcd.drawText(0, 0, cellStr .. " " .. hvStr, SMLSIZE + INVERS)

    local timerX = idiv(W, 2) - 12
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
    lcd.drawLine(mid, 44, W - 1, 44, DOTTED, 0)

    -- ── Left: Voltage ────────────────────────────────────────────
    lcd.drawText(2, 11, "BATTERY", SMLSIZE)
    if cellV then
        -- show both pack voltage and per-cell
        lcd.drawText(2, 20, string.format("%.2fV", cellV), MIDSIZE + vf(cellV))
        if cellCount and cellCount > 1 then
            lcd.drawText(2, 34, string.format("%.1fV pk", packV), SMLSIZE)
        end
        -- % and bar
        local bx, by, bw, bh = 2, 42, mid - 6, 6
        lcd.drawRectangle(bx, by, bw, bh)
        local fill = math.max(1, idiv((bw - 2) * pct, 100))
        lcd.drawFilledRectangle(bx + 1, by + 1, fill, bh - 2)
        lcd.drawText(2, 50, pct .. "%", SMLSIZE)
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
    lcd.drawText(c2, 11, "LINK RQly", SMLSIZE)
    if lq then
        lcd.drawText(c2, 20, string.format("%d%%", lq), MIDSIZE + lf(lq))
        if rssi then
            lcd.drawText(c2, 36, string.format("%ddBm", math.floor(rssi)), SMLSIZE)
        end
    else
        lcd.drawText(c2, 20, "NO LNK", SMLSIZE + INVERS + BLINK)
    end

    -- ── Right bottom: Health ──────────────────────────────────────
    lcd.drawText(c2, 46, "HEALTH:", SMLSIZE)
    if startV and minV and batteryUsed then
        local sag = startV - minV
        local sagMv = math.floor(sag * 1000)
        local rating = sag < CFG.sagGood and "GOOD"
                or sag < CFG.sagOk and "OK"
                or "WEAK"
        local hf = sag >= CFG.sagOk and INVERS or 0
        lcd.drawText(c2, 55, rating .. " " .. sagMv .. "mV", SMLSIZE + hf)
    elseif armed then
        lcd.drawText(c2, 55, "sampling...", SMLSIZE)
    else
        lcd.drawText(c2, 55, "---", SMLSIZE)
    end

    return 0
end

return { run = run_func, init = init_func, background = bg_func }