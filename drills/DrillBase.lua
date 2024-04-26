local rightIntegrator = Integrator:new("right", {
  front = "switchMovement",
  right = "reverse",
  back = "clutch",
  top = "observeMovement",
})

local DrillBase = {
  state = "idle",
  currentHorisontalPos = 1,
  LENGTH_OF_STICK = 42,
  START_OF_STICK = 1,
}

-- ====== all contants was defined up ======

--- Reset all states before movement, inner function
function DrillBase:_resetStatesBeforeMovement()
  rightIntegrator:stopAnySignal("back")
  rightIntegrator:stopAnySignal("right")
  self.state = "idle"
end

--- Switch movement stick, inner function
---@param shouldMove boolean -- true - vertical, false - horisontal
function DrillBase:_switchVerticalMovement(shouldMove)
  if shouldMove then rightIntegrator:setSignal("front", true) else rightIntegrator:stopSignal("front") end
end

---Main movement steps, inner function
---@param dir string direction, can be "forward", "backward", "up", "down"
---@param sleepDelay number delay before cancel movement
---@return nil
function DrillBase:_commonMovementSteps(dir, sleepDelay)
  self:_resetStatesBeforeMovement()
  if dir == "forward" or dir == "up" then
    self:_switchVerticalMovement(dir == "up")
    rightIntegrator:setSignal("right", true)
    os.sleep(sleepDelay)
    rightIntegrator:setSignal("back", true)
    rightIntegrator:stopSignal("right")
  elseif dir == "backward" or dir == "down" then
    self:_switchVerticalMovement(dir == "down")
    rightIntegrator:stopSignal("back")
    os.sleep(sleepDelay)
    rightIntegrator:setSignal("back", true)
  else
    error("drills: wrong dir", 3)
    return nil
  end
  self.state = "idle"
end

--- function for moving drills by number of blocks
---@param dir string direction, can be "forward", "backward", "up", "down"
---@param numberOfBlocks number
---@param returnBoolRes boolean|nil should return movement result
---@return boolean|nil
function DrillBase:moveNBlocks(dir, numberOfBlocks, returnBoolRes)
  if self.state == "moving" then return end
  local currentMultiplayer
  if dir == "forward" or dir == "up" then
    -- if numberOfBlocks = 1 and not up - we move forward with 0.3
    currentMultiplayer = (numberOfBlocks > 1 and dir == "up") and 0.15 or dir == "up" and 0.2 or 0.3
  elseif dir == "backward" or dir == "down" then
    currentMultiplayer = numberOfBlocks > 1 and 0.2 or 0.3
  else
    return
  end

  self:_commonMovementSteps(dir, numberOfBlocks * currentMultiplayer)
  if dir == "forward" then
    self.currentHorisontalPos = self.currentHorisontalPos + numberOfBlocks
  elseif dir == "backward" then
    self.currentHorisontalPos = self.currentHorisontalPos - numberOfBlocks
  end

  -- if we dont need res, we can awoid calculation
  if not returnBoolRes then return end
  return rightIntegrator:reciveSideOnce("top", 1) == "recived"
end

---function for checking if we can move in given direction
---@param dir string direction, can be "forward", "backward", "up", "down"
---@return boolean|nil
function DrillBase:checkIfCanMoveSide(dir)
  if self.state == "moving" then return end
  -- maybe different delay for vertical and horisontal (0.15 - vertical)
  self:_commonMovementSteps(dir, 0.15)
  return rightIntegrator:reciveSideOnce("top", 1) == "recived"
end

---function for moving drill untill watcher recive signal
---@param dir string direction, can be "forward", "backward", "up", "down"
---@param forceMove boolean|nil if true we dont check if we can move
---@return boolean|nil res movement result
function DrillBase:moveUntillEnd(dir, forceMove)
  if self.state == "moving" then return end
  if (forceMove or self:checkIfCanMoveSide(dir)) ~= true then return false end
  self:_resetStatesBeforeMovement()
  if dir == "forward" or dir == "up" then
    self:_switchVerticalMovement(dir == "up")
    os.sleep(0.2)
    rightIntegrator:setSignal("right", true)
    parallel.waitForAny(function()rightIntegrator:reciveSideOnce("top")end, self.stopEndlessMoving)
    rightIntegrator:setSignal("back", true)
    rightIntegrator:stopSignal("right")
  elseif dir == "backward" or dir == "down" then
    self:_switchVerticalMovement(dir == "down")
    os.sleep(0.2)
    rightIntegrator:stopSignal("back")
    parallel.waitForAny(function()rightIntegrator:reciveSideOnce("top")end, self.stopEndlessMoving)
    rightIntegrator:setSignal("back", true)
  else
    return
  end
  if dir == "forward" then
    self.currentHorisontalPos = self.LENGTH_OF_STICK
  elseif dir == "backward" then
    self.currentHorisontalPos = self.START_OF_STICK
  end
  self.state = "idle"
  return true
end

-- todo check if it works
function DrillBase:stopEndlessMoving()
  while true do
    local name, key = os.pullEvent("stopEndlessMoving")
    if key == true then break end
  end
end

return DrillBase


-- ==============================================================
-- while true do
--   local name, key = os.pullEvent("key")
--   if key == keys.w then
--     DrillBase:moveNBlocks("forward", 1)
--   elseif key == keys.s then
--     DrillBase:moveNBlocks("backward", 1)
--   elseif key == keys.down then
--     DrillBase:moveNBlocks("down", 1)
--   elseif key == keys.up then
--     DrillBase:moveNBlocks("up", 1)
--   elseif key == keys.numPad8 then
--     DrillBase:moveUntillEnd("up")
--   elseif key == keys.numPad2 then
--     DrillBase:moveUntillEnd("down")
--   elseif key == keys.numPad4 then
--     DrillBase:moveUntillEnd("forward")
--   elseif key == keys.numPad6 then
--     DrillBase:moveUntillEnd("backward")
--   end
-- end
