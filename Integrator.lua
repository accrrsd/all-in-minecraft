local Integrator = Class("integrator")

function Integrator:initialize(integratorName, sideNames)
  -- state values = idle, receiving, outputting
  self.sides = {
    top = { name = sideNames.top, state = "idle",},
    bottom = { name = sideNames.bottom, state = "idle",},
    left = { name = sideNames.left, state = "idle",},
    right = { name = sideNames.right, state = "idle",},
    front = { name = sideNames.front, state = "idle",},
    back = { name = sideNames.back, state = "idle",},
  }
  self.name = integratorName
  self.peripheral = peripheral.wrap(integratorName)
end

function Integrator:getSideState(side)
  return self.sides[side].state
end

function Integrator:getSideOutputStrength(side, parseAnalog)
  if parseAnalog then return self.peripheral.getAnalogOutput(side) else return self.peripheral.getOutput(side) end
end

function Integrator:getSideInputStrength(side, parseAnalog)
  if parseAnalog then return self.peripheral.getAnalogInput(side) else return self.peripheral.getInput(side) end
end

--- Reset reciving signals to idle
function Integrator:resetRecivingSides()
  for side, _ in ipairs(self.sides) do
    if self.sides[side].state == "receiving" then self:stopReciving(side) end
  end
end

--- Reset output signals to idle
function Integrator:resetOutputSides()
  for side, _ in ipairs(self.sides) do
    if self.sides[side].state == "outputting" then self:stopSignal(side) end
  end
end

--- Reset all signals to idle
function Integrator:resetAllSides()
  for side, _ in ipairs(self.sides) do self:stopAnySignal(side) end
end

--- Stop any side signal
---@param side string|number
function Integrator:stopAnySignal(side)
  self:stopSignal(side)
  self:stopReciving(side)
end

--- Stop side output signals
---@param side string|number
function Integrator:stopSignal(side)
  self.sides[side].state = "idle"
  self.peripheral.setOutput(side, false)
end

--- Stop side reciving signals
---@param side string|number
function Integrator:stopReciving(side)
  self.sides[side].state = "idle"
end

--- Add side to reciving list
---@param side string|number
function Integrator:startReciving(side)
  self.sides[side].state = "receiving"
end

--- Find side by name
---@param sideName string side name
function Integrator:getSideByName(sideName)
  if not sideName then return end
  for side, sideData in ipairs(self.sides) do
    if sideData.name == sideName then return side end
  end
end

--- Set side signal, if not value then stop signal
---@param side string|number
---@param value boolean|number
function Integrator:setSignal(side, value)
  if type(value) == "boolean" then
    self.peripheral.setOutput(side, value)
  elseif type(value) == "number" and value > 0 then
    self.peripheral.setAnalogOutput(side, value)
  else
    return
  end
  self.sides[side].state = "outputting"
end

--- Give impulse by side, if side output true, stop it for impulse.
---@param side string|number
---@param timeInSec number
---@param value boolean|number
function Integrator:setImpulse(side, timeInSec, value)
  if value == nil then value = true end
  if value == false or value == 0 then
    local prevValue = self:getSideOutputStrength(side)
    self:stopSignal(side)
    os.sleep(timeInSec)
    self:setSignal(side, prevValue)
  else
    self:setSignal(side, value)
    os.sleep(timeInSec)
    self:stopSignal(side)
  end
end

--- Switch side signal
---@param side string|number
---@param numValue number
function Integrator:switchSignal(side, numValue)
  if self.sides[side].state == "outputting" then
    self:stopSignal(side)
  else
    self:setSignal(side, type(numValue) == "number" or true)
  end
end

--- Inner timer function
---@param timeout number
local function _waitTimerReturn(timeout)
  local timerId = os.startTimer(timeout)
  local event, id
  while id ~= timerId do
    event, id = os.pullEvent("timer")
  end
  return "timer"
end

--- Recive signal endless
local function _receiveSignalWithoutStop(self, side, checkIntervalInSec, parseZero, parseAnalog)
  local inputValue
  local inputBefore = parseAnalog and self.peripheral.getAnalogInput(side) or self.peripheral.getInput(side)
  while self.sides[side].state == "receiving" do
    os.sleep(checkIntervalInSec or 0)
    if parseAnalog then
      inputValue = self.peripheral.getAnalogInput(side)
      if ((parseZero and inputValue == 0) or not parseZero) and inputValue ~= inputBefore then
        os.queueEvent("redstoneIntegratorAnalogInput", side, inputValue, self)
      end
    else
      inputValue = self.peripheral.getInput(side)
      if ((parseZero and inputValue == false) or not parseZero) and inputValue ~= inputBefore then
        os.queueEvent("redstoneIntegratorBoolInput", side, inputValue, self)
      end
    end
  end
  return "recived endless"
end

--- Recive signal once
local function _reciveSignalForOnce(self, side, checkIntervalInSec, parseZero, parseAnalog)
  local inputValue
  local inputBefore = parseAnalog and self.peripheral.getAnalogInput(side) or self.peripheral.getInput(side)
  while true do
    os.sleep(checkIntervalInSec or 0)
    if parseAnalog then
      inputValue = self.peripheral.getAnalogInput(side)
      if ((parseZero and inputValue == 0) or not parseZero) and inputValue ~= inputBefore then
        os.queueEvent("redstoneIntegratorAnalogInput", side, inputValue, self)
        return "recived"
      end
    else
      inputValue = self.peripheral.getInput(side)
      if ((parseZero and inputValue == false) or not parseZero) and inputValue ~= inputBefore then
        os.queueEvent("redstoneIntegratorBoolInput", side, inputValue, self)
        return "recived"
      end
    end
  end
end

--- Endless recive all marked sides or timer
---@param timeoutInSec number
---@param checkIntervalInSec number how often input will be checked
---@param parseZero boolean
---@param parseAnalog boolean
---@return number of ended function 
function Integrator:reciveAnyMarkedSidesWithTimer(timeoutInSec, checkIntervalInSec, parseZero, parseAnalog)
  local funcs = {}
  for side, _ in ipairs(self.sides) do
    if self.sides[side].state == "receiving" then
      funcs[side] = function() _receiveSignalWithoutStop(self, side, checkIntervalInSec, parseZero, parseAnalog) end
    end
  end
  if #funcs == 0 then return -1 end

  return parallel.waitForAny(parallel.waitForAll(table.unpack(funcs)), function()
    _waitTimerReturn(timeoutInSec)
  end)
end

--- Recive signal on one side with timer
---@param side string|number
---@param timeoutInSec number
---@param checkIntervalInSec number how often input will be checked
---@param parseZero boolean
---@param parseAnalog boolean
---@return number of ended function 
function Integrator:reciveSideWithTimer(side, timeoutInSec, checkIntervalInSec, parseZero, parseAnalog)
  return parallel.waitForAny(function() _receiveSignalWithoutStop(self, side, checkIntervalInSec, parseZero, parseAnalog) end,
    function() _waitTimerReturn(timeoutInSec) end)
end

--- Recive all sides once or timer
---@param timeoutInSec number
---@param checkIntervalInSec number how often input will be checked
---@param parseZero boolean
---@param parseAnalog boolean
---@return number of ended function 
function Integrator:reciveAllMarkedSidesOnce(timeoutInSec, checkIntervalInSec, parseZero, parseAnalog)
  local funcs = {}
  for side, _ in ipairs(self.sides) do
    if self.sides[side].state == "receiving" then
      funcs[side] = function() _reciveSignalForOnce(self, side, checkIntervalInSec, parseZero, parseAnalog) end
    end
  end
  if #funcs == 0 then return -1 end

  if timeoutInSec ~= nil then
    return parallel.waitForAny(table.unpack(funcs), function()
      _waitTimerReturn(timeoutInSec)
    end)
  else
    return parallel.waitForAny(table.unpack(funcs))
  end
end

--- Recive signal on one side once or timer
---@param side string|number
---@param timeoutInSec number
---@param checkIntervalInSec number how often input will be checked
---@param parseZero boolean
---@param parseAnalog boolean
---@return string|number number of ended function or reason why function ended
function Integrator:reciveSideOnce(side, timeoutInSec, checkIntervalInSec, parseZero, parseAnalog)
  if timeoutInSec ~= nil then
    local res = parallel.waitForAny(function() _reciveSignalForOnce(self, side, checkIntervalInSec, parseZero, parseAnalog) end,
      function() _waitTimerReturn(timeoutInSec) end)
      if res==1 then return "recived" else return "timer" end
  else
    return _reciveSignalForOnce(self, side, parseZero, parseAnalog)
  end
end

return Integrator
