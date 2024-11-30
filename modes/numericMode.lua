local function drawLayerBody(winObj, matrixToDraw, offset, layer, customColors, symbolByName)
	local xCenter, yCenter = winObj:getCenter()

	local xC = xCenter
	local yC = yCenter

	local xCenter = xCenter + offset.x
	local yCenter = yCenter + offset.y

	local xSize, ySize = winObj.win.getSize()

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

	if matrixToDraw[layer] then
		for _, block in pairs(matrixToDraw[layer]) do
			local symX = xCenter + block.x
			local symY = yCenter + block.z
			local value
			local text

			if block.x == 0 or block.z == 0 then
				axysBlocks[symX .. symY] = block
			end

			-- prevent text bugging when fast change layers
			if block.x == 0 and block.z ~= 0 then
				text = "|"
			elseif block.z == 0 and block.x ~= 0 then
				text = "-"
			end

			if block.z ~= 0 then
				value = math.abs(block.x)
			else
				value = math.abs(block.z)
			end

			if not text and symbolByName and symbolByName[block.name] then
				text = symbolByName[block.name]
			end

			if not text then
				text = value > 9 and "#" or value
			end

			tryWriteColored(text, symX, symY, block)
		end
	end

	-- garantee that axys are always visible
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

-- make that way, because of optimization reasons
--- draw numeric layer
---@param matrixToDraw table scan from scanner, sorted by level
---@param layer number
---@param customColors table
function Numeric:drawLayer(matrixToDraw, layer, customColors, symbolByName)
	self.winObj.win.clear()
	if self.canHandleColors then
		drawLayerBody(self.winObj, matrixToDraw, self.offset, layer, customColors, symbolByName)
	else
		drawLayerBody(self.winObj, matrixToDraw, self.offset, layer, nil, symbolByName)
	end
end

return Numeric
