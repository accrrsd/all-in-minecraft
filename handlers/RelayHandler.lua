local RelayHandler = {}
local RelayClass = require("api/RelayClass")

RelayHandler.__index = RelayHandler

function RelayHandler:new()
  local obj = {}
  local relays = { peripheral.find("redstone_relay") }

  for _, relay in pairs(relays) do
    if relay.getAnalogInput("back") == 15 then
      obj.armPosRelay = RelayClass:new(peripheral.getName(relay))
    elseif relay.getAnalogInput("front") == 15 then
      obj.moveRelay = RelayClass:new(peripheral.getName(relay))
    elseif relay.getAnalogInput("right") == 15 then
      obj.additionalRelay = RelayClass:new(peripheral.getName(relay))
      -- specified order, because armPosRelay can also have top impulse
    elseif relay.getAnalogInput("top") == 15 then
      obj.bugHandlerRelay = RelayClass:new(peripheral.getName(relay))
    end
  end

  return setmetatable(obj, self)
end

--@param side string
function RelayHandler:rotateShip(side)
  if side == "left" then
    self.bugHandlerRelay:setImpulse("right", true)
  else
    self.additionalRelay:setImpulse("top", true)
  end
end

function RelayHandler:resetSignals()
  if self.mainRelay then self.mainRelay:resetSignals() end
  if self.additionalRelay then self.additionalRelay:resetSignals() end
  if self.reverseRelay then self.reverseRelay:resetSignals() end
end

--#region Base

--@param value boolean
function RelayHandler:reverseBaseGearshift(value)
  self.additionalRelay.relay.setOutput("front", value)
end

--@param reverse boolean
function RelayHandler:moveFromBase90Deg(reverse)
  reverse = reverse or false
  self:reverseBaseGearshift(reverse)
  self.bugHandlerRelay:setImpulse("left", true)
end

--@param reverse boolean
function RelayHandler:moveFromBase180Deg(reverse)
  reverse = reverse or false
  self:reverseBaseGearshift(reverse)
  self.moveRelay:setImpulse("top", true)
end

--#endregion

--#region Engine

--@param value boolean
function RelayHandler:reverseEngineGearshift(value)
  self.additionalRelay.relay.setOutput("back", value)
end

--@param reverse boolean
function RelayHandler:moveFromEngine90Deg(reverse)
  reverse = reverse or false
  self:reverseEngineGearshift(reverse)
  self.moveRelay:setImpulse("left", true)
end

--@param reverse boolean
function RelayHandler:moveFromEngine180Deg(reverse)
  reverse = reverse or false
  self:reverseEngineGearshift(reverse)
  self.moveRelay:setImpulse("right", true)
end

--#endregion

function RelayHandler:awaitEngineObserverSignal(timeout)
  if not timeout then timeout = 3 end
  return self.bugHandlerRelay:awaitNeededInput("back", timeout, true)
end

function RelayHandler:checkCurrentArmPosition()
  if self.armPosRelay.relay.getInput("top") then return 1 end
  if self.armPosRelay.relay.getInput("right") then return 2 end
  if self.armPosRelay.relay.getInput("bottom") then return 3 end
  if self.armPosRelay.relay.getInput("left") then return 4 end
  return -1
end

function RelayHandler:convertSideToArmPosition(side)
  if side == "top" then return 1 end
  if side == "right" then return 2 end
  if side == "bottom" then return 3 end
  if side == "left" then return 4 end
  return -1
end

--@param timeour number
function RelayHandler:awaitChangeArmPosition(timeout)
  timeout = timeout or 10
  local side = self.armPosRelay:awaitAllSideNeededInput(timeout, true).side
  if side then
    return self:convertSideToArmPosition(side)
  else
    return -1
  end
end

function RelayHandler:setBaseArmPosition(targetNumSide)
  local currentPos = self:checkCurrentArmPosition()
  if currentPos == targetNumSide or currentPos == -1 then return end
  local diff = (targetNumSide - currentPos) % 4
  if diff == 0 then
    return false
  elseif diff == 1 then
    self:moveFromBase90Deg()
  elseif diff == 3 then
    self:moveFromBase90Deg(true)
  elseif diff == 2 then
    self:moveFromBase180Deg(math.random() > 0.5)
  end
  return true
end

return RelayHandler
