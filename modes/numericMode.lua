local function _drawBody(winObj, matrixToDraw, offset, customColors, getText, handleConflict)
  local xCenter, yCenter = winObj:getCenter()

  local xC = xCenter
  local yC = yCenter

  xCenter = xCenter + offset.x
  yCenter = yCenter + offset.y

  local xSize, ySize = winObj.win.getSize()

  local displayMap = {}
  local axysBlocks = {}

  for i = 0, xSize do
    for j = 0, ySize do
      axysBlocks[i .. j] = nil
    end
  end

  local function tryWriteColored(text, symX, symY, block)
    local color = colors.white
    if customColors and block and customColors[block.name] then
      color = customColors[block.name]
    end
    winObj.win.setTextColor(color)
    winObj.win.setCursorPos(symX, symY)
    winObj.win.write(text)
    winObj.win.setTextColor(colors.white)
  end

  for _, blocks in pairs(matrixToDraw) do
    for _, block in pairs(blocks) do
      local symX = xCenter + block.x
      local symY = yCenter + block.z
      local cellKey = symX .. ":" .. symY
      local existingBlock = displayMap[cellKey]

      if existingBlock then
        -- Решение конфликта
        displayMap[cellKey] = handleConflict(existingBlock, block)
      else
        displayMap[cellKey] = block
      end
    end
  end

  for _, block in pairs(displayMap) do
    local symX = xCenter + block.x
    local symY = yCenter + block.z

    if block.x == 0 or block.z == 0 then
      axysBlocks[symX .. symY] = block
    end

    local text = getText(block)
    tryWriteColored(text, symX, symY, block)
  end

  -- Обеспечиваем отображение осей
  for i = -xC, xC + 1 do
    local symX = xCenter + i
    local symY = yCenter
    tryWriteColored("-", symX, symY, axysBlocks[symX .. symY])
  end

  for j = -yC, yC + 1 do
    local symX = xCenter
    local symY = yCenter + j
    tryWriteColored("|", symX, symY, axysBlocks[symX .. symY])
  end

  tryWriteColored("+", xCenter, yCenter, axysBlocks[xCenter .. yCenter])
end

local Numeric = {}
Numeric.__index = Numeric

function Numeric:new(winObj)
  local obj = {
    winObj = winObj,
    canHandleColors = winObj.win.isColour(),
    offset = {
      x = 0,
      y = 0,
    },
  }
  setmetatable(obj, self)
  return obj
end

--- added offset to current offset
---@param offset {x: number, y: number}
function Numeric:addOffset(offset)
  self.offset.x = self.offset.x + offset.x
  self.offset.y = self.offset.y + offset.y
end

--- set new offset
---@param offset {x: number, y: number}
function Numeric:setOffset(offset)
  self.offset = offset
end

--- draw numeric layer
---@param matrixToDraw table scan from scanner, sorted by level
---@param layer number
---@param customColors table
---@param symbolByName table
function Numeric:drawLayer(matrixToDraw, layer, customColors, symbolByName)
  self.winObj.win.clear()
  customColors = self.canHandleColors and customColors or nil

  -- text rules
  local getText = function(block)
    local text
    if block.x == 0 and block.z ~= 0 then
      text = "|"
    elseif block.z == 0 and block.x ~= 0 then
      text = "-"
    elseif symbolByName and symbolByName[block.name] then
      text = symbolByName[block.name]
    else
      local value = (block.z ~= 0) and math.abs(block.x) or math.abs(block.z)
      text = value > 9 and "#" or value
    end
    return text
  end

  -- ignore conflicts for `drawLayer`
  local handleConflict = function(existingBlock)
    return existingBlock
  end

  _drawBody(self.winObj, { [layer] = matrixToDraw[layer] }, self.offset, customColors, getText, handleConflict)
end

--- draw priority layer
---@param matrixToDraw table scan from scanner, sorted by level
---@param customColors table
---@param symbolByName table
function Numeric:drawPriorityLayer(matrixToDraw, heightMode, customColors, symbolByName)
  self.winObj.win.clear()
  customColors = self.canHandleColors and customColors or nil

  local currentChar = heightMode == "up" and string.char(30) or string.char(31)
  local oppositeChar = heightMode == "up" and string.char(31) or string.char(30)

  -- text rules
  local getText = function(block)
    if block.priority ~= nil then
      if block.y ~= 0 and heightMode then
        local block_dir = block.y > 0 and "up" or "down"
        local distance = math.abs(block.y)
        if distance > 9 then
          return block_dir == heightMode and currentChar or oppositeChar
        elseif block_dir == heightMode then
          return distance
        elseif block_dir ~= heightMode then
          return oppositeChar
        end
      end
    elseif symbolByName and symbolByName[block.name] then
      return symbolByName[block.name]
    end
    return "#"
  end

  local handleConflict = function(existingBlock, newBlock)
    -- if some block has higher priority
    if newBlock.priority and (not existingBlock.priority or newBlock.priority > existingBlock.priority) then
      return newBlock
      -- if blocks have equals or not have priority
    elseif newBlock.priority == existingBlock.priority then
      return (math.abs(newBlock.y) < math.abs(existingBlock.y)) and newBlock or existingBlock
    end
    return existingBlock
  end

  _drawBody(self.winObj, matrixToDraw, self.offset, customColors, getText, handleConflict)
end

return Numeric
