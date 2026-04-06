-- GPS Plus Code script (fixed)
-- Original: Miami Mike / ChrisOhara
-- Fix: guard getValue() against nil sensor ID

local mid = LCD_W / 2
local map = {[0] =
  "2", "3", "4", "5", "6", "7", "8", "9", "C", "F",
  "G", "H", "J", "M", "P", "Q", "R", "V", "W", "X"}

local my_gpsId = -1  -- safe default: getValue(-1) returns 0, never crashes
local latitude, longitude = 0.0, 0.0
local pluscode = ""

local function getTelemetryId(name)
  local field = getFieldInfo(name)
  if field then return field.id else return -1 end
end

local function init_func()
  my_gpsId = getTelemetryId("GPS")
end

local function getcode(lat, lon)
  local int = math.floor(lat)
  local codepair = map[int]
  lat = 20 * (lat - int)
  int = math.floor(lon)
  codepair = codepair .. map[int]
  lon = 20 * (lon - int)
  return lat, lon, codepair
end

local function bg_func()
  local gps = getValue(my_gpsId)  -- safe: -1 returns 0 if no GPS
  if type(gps) == "table" and gps.lat and gps.lon then
    latitude  = gps.lat
    longitude = gps.lon
  end
end

local function run_func()
  local lat = (latitude + 90) / 20
  local lon = (longitude + 180) / 20
  local codepair
  pluscode = ""
  for i = 1, 4 do
    lat, lon, codepair = getcode(lat, lon)
    pluscode = pluscode .. codepair
  end
  pluscode = pluscode .. "+"
  lat, lon, codepair = getcode(lat, lon)
  pluscode = pluscode .. codepair
  pluscode = pluscode .. map[4 * math.floor(lat / 5) + math.floor(lon / 4)]
  lcd.clear()
  lcd.drawText(mid - 53, 5,  "GPS coordinates are")
  lcd.drawText(mid - 44, 15, latitude .. ", " .. longitude)
  lcd.drawText(mid - 49, 35, "Google Plus Code is")
  lcd.drawText(mid - 32, 45, pluscode)
  return 0
end

return { run=run_func, init=init_func, background=bg_func }