--- that class provide a simple interface for pixel (1/6 of a symbol in vertical and 1/2 pf a symbol in horizontal) operations

local PixelsClass = {}
PixelsClass.__index = PixelsClass

---@param symX number (symbol)
---@param symY number (symbol)
---@return PixelsClass
function PixelsClass:new(symX, symY)
	local obj = {
		symX = symX,
		symY = symY,
		data = {
			-- left side
			{
				{ x = symX, y = symY - 1, active = false },
				{ x = symX, y = symY, active = false },
				{ x = symX, y = symY + 1, active = false },
			},
			-- right side
			{
				{ x = symX + 1, y = symY - 1, active = false },
				{ x = symX + 1, y = symY, active = false },
				{ x = symX + 1, y = symY + 1, active = false },
			},
		},
	}
	return setmetatable(obj, self)
end

---@param column number (pixel in symbol, like 1,2)
---@param row number (pixel in symbol, like 1,2,3)
---@param active boolean
function PixelsClass:setPixel(column, row, active)
	if column < 1 or column > 2 or row < 1 or row > 3 then
		return nil
	end
	self.data[column][row].active = active
end

---@param column number (pixel in symbol, like 1,2)
---@param row number (pixel in symbol, like 1,2,3)
---@return nil or boolean
function PixelsClass:getPixel(column, row)
	if column < 1 or column > 2 or row < 1 or row > 3 then
		return nil
	end
	return self.data[column][row].active
end

---@param column number (pixel in symbol, like 1,2)
---@param row number (pixel in symbol, like 1,2,3)
---@return nil or number x*2, number y*3
function PixelsClass:getPixelCordsOnPixGrid(column, row)
	if column < 1 or column > 2 or row < 1 or row > 3 then
		return nil
	end
	return (self.symX - 1) * 2 + column, (self.symY - 1) * 3 + row
end

return PixelsClass
