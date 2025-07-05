local ActionsHandler = {}
ActionsHandler.__index = ActionsHandler

function ActionsHandler:new(MovementHandler)
  local obj = {}
  obj.path = "actions.json"
  obj.MovementHandler = MovementHandler
  obj.actions = {}
  return setmetatable(obj, self)
end

function ActionsHandler:load()
  if not fs.exists(self.path) then return false end
  local file = fs.open(self.path, "r")
  local content = file.readAll()
  file.close()
  self.actions = textutils.unserialiseJSON(content)
  return true
end

function ActionsHandler:save()
  local jsonStr = textutils.serialiseJSON(self.actions)
  local file = fs.open(self.path, "w")
  file.write(jsonStr)
  file.close()
end

function ActionsHandler:add(action)
  table.insert(self.actions, action)
end

function ActionsHandler:remove(index)
  if index == nil then index = 1 end
  if index >= 1 and index <= #self.actions then
    table.remove(self.actions, index)
    return true
  end
  return false
end

function ActionsHandler:createArmLengthAction(length, direction)
  return { type = "armLength", length = length, direction = direction }
end

function ActionsHandler:createRotationAction(side)
  return { type = "rotateShip", side = side }
end

function ActionsHandler:createMovementAction(direction)
  return { type = "move", direction = direction }
end

function ActionsHandler:createArmRotationAction(position)
  return { type = "armPos", position = position }
end

function ActionsHandler:doActions()
  -- todo удаляем по мере исполнения - что приводит к багу
  for i = 1, #self.actions do
    self:doAction(i)
  end
end

function ActionsHandler:doAction(index)
  local action = self.actions[index]
  if action.type == "armLength" then
    self.MovementHandler:changeArmLength(action.length)
    self:remove(index)
    self:save()
  elseif action.type == "rotateShip" then
    self:remove(index)
    self:save()
    self.MovementHandler:rotateShip(action.side)
  elseif action.type == "move" then
    self:remove(index)
    self:save()
    if action.direction == "forward" then
      self.MovementHandler:moveForward()
    elseif action.direction == "backward" then
      self.MovementHandler:moveBackward()
    elseif action.direction == "up" then
      self.MovementHandler:moveUp()
    elseif action.direction == "down" then
      self.MovementHandler:moveDown()
    end
  elseif action.type == "armPos" then
    self.MovementHandler:setBaseArmPosition(action.position)
    self:remove(index)
    self:save()
  end
end

return ActionsHandler
