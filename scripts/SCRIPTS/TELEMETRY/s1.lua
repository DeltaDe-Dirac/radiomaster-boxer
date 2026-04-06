local s1id = -1
local s2id = -1

local function init_func()
  local f1 = getFieldInfo("S1")
  local f2 = getFieldInfo("S2")
  s1id = f1 and f1.id or -1
  s2id = f2 and f2.id or -1
end

local function bg_func() end

local function run_func()
  lcd.clear()
  lcd.drawText(0, 0, "KNOB DIAGNOSTIC", SMLSIZE + INVERS)
  lcd.drawLine(0, 9, LCD_W-1, 9, SOLID, 0)

  lcd.drawText(2, 12, "S1 id: " .. s1id, SMLSIZE)
  if s1id ~= -1 then
    local v = getValue(s1id)
    lcd.drawText(2, 21, "S1 val: " .. tostring(v), SMLSIZE)
  else
    lcd.drawText(2, 21, "S1 NOT FOUND", SMLSIZE + INVERS)
  end

  local v2 = getValue("S1")
  lcd.drawText(2, 30, "S1 str: " .. tostring(v2), SMLSIZE)

  local v3 = getValue("s1")
  lcd.drawText(2, 39, "s1 str: " .. tostring(v3), SMLSIZE)

  lcd.drawText(2, 50, "S2 val: " .. tostring(getValue("S2")), SMLSIZE)

  return 0
end

return { run=run_func, init=init_func, background=bg_func }