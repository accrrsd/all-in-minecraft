local RelayHandlerClass = require("handlers/RelayHandler")

local MovementHandler = {}
MovementHandler.__index = MovementHandler

function MovementHandler:new(RelayHandler, GearshiftHandler)
  local obj = {}
  obj.RelayHandler = RelayHandler
  obj.GearshiftHandler = GearshiftHandler
  return setmetatable(obj, self)
end

function MovementHandler:rotateShip(side)
  self.RelayHandler.rotateShip(side)
end

function MovementHandler:moveForward()
  if self.RelayHandler:setBaseArmPosition(1) then
    self.RelayHandler:awaitChangeArmPosition(3)
    self.RelayHandler:awaitEngineObserverSignal(3)
  end
  self.RelayHandler:moveFromEngine180Deg(math.random() > 0.5)
end

function MovementHandler:moveBackward()
  if self.RelayHandler:setBaseArmPosition(3) then
    self.RelayHandler:awaitChangeArmPosition(3)
    self.RelayHandler:awaitEngineObserverSignal(3)
  end
  self.RelayHandler:moveFromEngine180Deg(math.random() > 0.5)
end

function MovementHandler:moveUp()
  if self.RelayHandler:setBaseArmPosition(2) then
    self.RelayHandler:awaitChangeArmPosition(3)
    self.RelayHandler:awaitEngineObserverSignal(3)
  end
  self.RelayHandler:moveFromEngine180Deg(math.random() > 0.5)
end

function MovementHandler:moveDown()
  if self.RelayHandler:setBaseArmPosition(4) then
    self.RelayHandler:awaitChangeArmPosition(3)
    self.RelayHandler:awaitEngineObserverSignal(3)
  end
  self.RelayHandler:moveFromEngine180Deg(math.random() > 0.5)
end

function MovementHandler:changeArmLength(targetLength)
  if targetLength < 0 or targetLength > self.GearshiftHandler.armMaxLength then
    targetLength = self.GearshiftHandler.armMaxLength
  end
  local currentLength = self.GearshiftHandler.currentArmLength
  local offset = targetLength - currentLength
  local dir = offset > 0 and 1 or -1
  self.GearshiftHandler:moveArm(offset, dir)
end

function MovementHandler:calculateSteps(targetDistance)
  local remaining = targetDistance
  local steps = {}

  local OFFSET = 2

  while remaining > 0 do
    local maxPossible = math.floor(remaining / 2) - OFFSET
    local optimal = math.min(maxPossible, self.GearshiftHandler.armMaxLength)

    if optimal < 0 then optimal = 0 end

    local step = (optimal + OFFSET) * 2
    table.insert(steps, { armLength = optimal, step = step })
    remaining = remaining - step
  end

  return steps
end

return MovementHandler
