local RelayClass = {}
RelayClass.__index = RelayClass

--@param side string
--@param receiver table
--@param analogue boolean
local function _receiveAnyInput(side, receiver, analogue)
  if analogue == nil then analogue = false end
  local prevValue
  if analogue then
    prevValue = receiver.getAnalogInput(side)
  else
    prevValue = receiver.getInput(side)
  end
  local res = { side = side, input = prevValue }
  if analogue then
    while res.input == prevValue do
      os.pullEvent("redstone")
      res.input = receiver.getAnalogInput(side)
    end
  else
    while res.input == prevValue do
      os.pullEvent("redstone")
      res.input = receiver.getInput(side)
    end
  end
  return res
end


local function _receiveNeededInput(side, receiver, neededValue)
  if neededValue == nil then neededValue = true end
  local res = { side = side, input = nil }
  local prevValue
  if type(neededValue) == "boolean" then
    prevValue = receiver.getInput(side)
    while res.input ~= neededValue or res.input == prevValue do
      os.pullEvent("redstone")
      res.input = receiver.getInput(side)
    end
  elseif type(neededValue) == "number" then
    prevValue = receiver.getInput(side)
    while res.input ~= neededValue or res.input == prevValue do
      os.pullEvent("redstone")
      res.input = receiver.getAnalogInput(side)
    end
  end
  return res
end

--@param name string
function RelayClass:new(name)
  local obj = {}
  local perepRes = peripheral.wrap(name)
  if perepRes ~= nil then obj.relay = perepRes end
  return setmetatable(obj, self)
end

--@param side string
--@param timeout number
--@param neededValue any
function RelayClass:awaitNeededInput(side, timeout, neededValue)
  if timeout == nil then timeout = 3 end
  if neededValue == nil then neededValue = true end
  local res = nil

  parallel.waitForAny(function() res = _receiveNeededInput(side, self.relay, neededValue).input end,
    function() os.sleep(timeout) end)

  return res
end

function RelayClass:awaitAllSideNeededInput(timeout, neededValue)
  if timeout == nil then timeout = 3 end
  if neededValue == nil then neededValue = true end
  local res = { side = nil, input = false }

  parallel.waitForAny(function() res = _receiveNeededInput("left", self.relay, neededValue) end,
    function() res = _receiveNeededInput("right", self.relay, neededValue) end,
    function() res = _receiveNeededInput("top", self.relay, neededValue) end,
    function() res = _receiveNeededInput("bottom", self.relay, neededValue) end,
    function() res = _receiveNeededInput("front", self.relay, neededValue) end,
    function() res = _receiveNeededInput("back", self.relay, neededValue) end, function() os.sleep(timeout) end)

  return res
end

function RelayClass:awaitAnyInput(side, timeout)
  if timeout == nil then timeout = 3 end
  local res = { side = nil, input = false }

  parallel.waitForAny(function() res = _receiveAnyInput(side, self.relay, false) end, function() os.sleep(timeout) end)

  return res
end

--@param timeout number
--@return table
function RelayClass:awaitAllSideAnyInput(timeout)
  if timeout == nil then timeout = 3 end

  local res = { side = nil, input = false }

  parallel.waitForAny(function() res = _receiveAnyInput("left", self.relay, false) end,
    function() res = _receiveAnyInput("right", self.relay, false) end,
    function() res = _receiveAnyInput("top", self.relay, false) end,
    function() res = _receiveAnyInput("bottom", self.relay, false) end,
    function() res = _receiveAnyInput("front", self.relay, false) end,
    function() res = _receiveAnyInput("back", self.relay, false) end, function() os.sleep(timeout) end)

  return res
end

--@param side string
--@param timeout number
--@param value any
function RelayClass:setImpulse(side, value, timeout)
  if value == nil then value = true end
  timeout = timeout or 0.1
  self.relay.setOutput(side, value)
  -- stop code untill it can handle pullEvent("timer")
  local timer_id = os.startTimer(timeout)
  local _, id
  repeat _, id = os.pullEvent("timer") until id == timer_id
  if type(value) == "boolean" then
    self.relay.setOutput(side, not value)
  else
    if value > 0 then
      self.relay.setOutput(side, 0)
    else
      self.relay.setOutput(side, 15)
    end
  end
end

--@param value boolean
function RelayClass:resetSignals(value)
  if not value then value = false end
  self.relay.setOutput("left", value)
  self.relay.setOutput("right", value)
  self.relay.setOutput("top", value)
  self.relay.setOutput("bottom", value)
  self.relay.setOutput("front", value)
  self.relay.setOutput("back", value)
end

return RelayClass
