local StateHandler = {}
StateHandler.__index = StateHandler

local instance = nil

local function createStateHandler()
  local obj = {}
  obj.path = "settings/state.json"
  obj.state = {}
  return setmetatable(obj, StateHandler)
end

function StateHandler.getInstance()
  if instance == nil then
    instance = createStateHandler()
    instance:load()
  end
  return instance
end

function StateHandler:load()
  if not fs.exists(self.path) then return false end
  local file = fs.open(self.path, "r")
  local content = file.readAll()
  file.close()
  self.state = textutils.unserializeJSON(content) or {}
  return true
end

function StateHandler:save()
  local jsonstr = textutils.serializeJSON(self.state)
  local file = fs.open(self.path, "w")
  file.write(jsonstr)
  file.close()
end

return StateHandler
