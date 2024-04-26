GeneralApi = {}

-- create event and need another function to subscribe to it
GeneralApi.redstoneIntegratorBoolInputEvent = function(integrator, side, neededBool)
  neededBool = neededBool or true
  while true do
    local inputValue = integrator.getInput(side)
    if inputValue == neededBool then
      os.queueEvent("redstoneIntegratorBoolInput", side, neededBool)
      return inputValue
    end
  end
end

GeneralApi.redstoneIntegratorAnalogInputEvent = function (integrator, side, obtainZero)
  obtainZero = obtainZero or false
  while true do
    local inputValue = integrator.getAnalogInput(side)
    if obtainZero and inputValue == 0 then
      os.queueEvent("redstoneIntegratorAnalogInput", side, inputValue)
    elseif not obtainZero and inputValue ~= 0 then
      os.queueEvent("redstoneIntegratorAnalogInput", side, inputValue)
    end
  end
end

GeneralApi.rewriteFileWithDataTable = function(path, data)
  local file = fs.open(path, "w")
  local new = ""
  if data~=nil then
    for _, v in pairs(data) do
      new = new .. v .. '\n'
    end
  end
  file.write(new)
  file.close()
end

GeneralApi.addToFileWithDataTable = function (path, data)
  local file = fs.open(path, "a")
  local new = ""
  if data~=nil then
    for _, v in pairs(data) do
      new = new .. v .. '\n'
    end
  end
  file.write(new)
  file.close()
end

GeneralApi.readFileAsDataTable = function(path)
  local file = fs.open(path, "r")
  if file == nil then return nil end
  local data = {}
  for line in file.readAll():gmatch("[^\r\n]+") do
    table.insert(data, line)
  end
  file.close()
  return #data > 0 and data or nil
end


GeneralApi.pullEventByName = function(name)
  while true do
    local event = table.pack(os.pullEvent())
    if event[1] == name then
      return event
    end
  end
end


local function wait_for_exit_key()
  repeat
    local _, key = os.pullEvent("key")
  until key == keys.q
end

GeneralApi.WaitForAny = function(callback, params, exitEvent, exitEventParams)
  local function exitEventWrapper()
    if exitEvent == true then return end
    if exitEventParams == nil then
      return exitEvent()
    else
      return exitEvent(unpack(exitEventParams))
    end
  end

  local function wrapper()
    if params == nil then
      return callback()
    else
      return callback(unpack(params))
    end
  end

  if exitEvent == nil then
    return parallel.waitForAny(wrapper, wait_for_exit_key)
  else
    return parallel.waitForAny(wrapper, exitEventWrapper)
  end
end

-- usage  GeneralApi.WaitForAny( GeneralApi.redstoneIntegratorInputEvent, { RedstoneIntegrator, "back", true }, test, nil)


return GeneralApi
