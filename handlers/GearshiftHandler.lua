local GearshiftHandler = {}
GearshiftHandler.__index = GearshiftHandler

local GearshiftClass = require("api/GearshiftClass")
local StateHandler = require("handlers/StateHandler")

local function _loadJsonFromFile(filePath)
  local file = fs.open(filePath, "r")
  local content = file.readAll()
  file.close()
  return textutils.unserialiseJSON(content)
end

local function setArmState(armLength, obj)
  obj.currentArmLength = armLength
  obj.StateHandler.state.currentArmLength = obj.currentArmLength
  obj.StateHandler:save()
end

function GearshiftHandler:new(RelayHandler)
  local obj = {}
  local settings = _loadJsonFromFile("settings/props.json")
  obj.armGearshift = GearshiftClass:new(settings.armGearshiftName)
  obj.armMaxLength = settings.armLength or 16
  obj.StateHandler = StateHandler.getInstance()
  obj.RelayHandler = RelayHandler

  local res = setmetatable(obj, self)
  if obj.StateHandler.state.currentArmLength then
    obj.currentArmLength = obj.StateHandler.state.currentArmLength
  else
    obj:resetArm()
  end
  return res
end

function GearshiftHandler:moveArm(lengthOffset, direction)
  self.armGearshift:moveAfterRunning(lengthOffset, direction)
  if self.RelayHandler:awaitEngineObserverSignal(10) ~= nil then
    setArmState(self.currentArmLength + lengthOffset, self)
  end
end

function GearshiftHandler:resetArm()
  self.armGearshift:moveAfterRunning(self.armMaxLength, -1)
  setArmState(0, self)
end

return GearshiftHandler
