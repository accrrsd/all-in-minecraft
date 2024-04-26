BasicApi = {}

BasicApi.findInTableFirst = function(table, findArgument)
  if (type(findArgument) ~= "string") then findArgument = tostring(findArgument) end
  for k, v in pairs(table) do
    if (type(k) ~= "string") then k = tostring(k) end
    if (type(v) ~= "string") then v = tostring(v) end
    if k:match(findArgument) or v:match(findArgument) then return k, v end
  end
  return nil
end

BasicApi.getRealLength = function(tbl)
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

BasicApi.deepCopy = function(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepCopy(orig_key)] = deepCopy(orig_value)
    end
    setmetatable(copy, deepCopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

BasicApi.checkNills = function(t)
  local count = 0
  for i = 1, #t do
    if t[i] == nil then
      count = count + 1
    end
  end
  return count
end

BasicApi.findInTableMultiple = function(tableArg, findArgument, neededBoth)
  neededBoth = neededBoth or false
  if (type(findArgument) ~= "string") then findArgument = tostring(findArgument) end
  local result = {}
  for k, v in pairs(tableArg) do
    if (type(k) ~= "string") then k = tostring(k) end
    if (type(v) ~= "string") then v = tostring(v) end
    if k:match(findArgument) or v:match(findArgument) then
      if neededBoth then
        table.insert(result, { k, v })
      elseif neededBoth == "key" then
        table.insert(result, k)
      else
        table.insert(result, v)
      end
    end
  end
  return #result == 0 and nil or result
end

BasicApi.pickRandom = function(list)
  local randomIndex = math.random(#list)
  return randomIndex, list[randomIndex]
end

BasicApi.round = function(number)
  local decimal = number % 1
  if decimal >= 0.5 then
    return math.ceil(number)
  else
    return math.floor(number)
  end
end

return BasicApi
