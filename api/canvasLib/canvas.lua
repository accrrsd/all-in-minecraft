-- dont use middleclass because its overkill, i just need a table with fabric, and its done.
local SymbolClass = _G.canvasLib.private.SymbolClass

local function _checkSymbolInBounds(symX, symY, symbols)
	if symX < 1 or symX > #symbols or symY < 1 or symY > #symbols[symX] then
		return false
	end
	return true
end

--return symX number (symbol), symY number (symbol), column number (pixel in symbol, like 1,2), row number (pixel in symbol, like 1,2,3)
local function _findPixelOnScreenByCords(x, y)
	x = x - 1
	y = y - 1
	local symX = math.floor(x / 2)
	local symY = math.floor(y / 3)
	local column = x - symX * 2
	local row = y - symY * 3
	symX = symX + 1
	symY = symY + 1
	return symX, symY, column, row
end

--- That class uses for simlify canvas operations on settet window.
local CanvasClass = {}
CanvasClass.__index = CanvasClass

---@param display table (window)
---@param scale number (0.5, 1, 1.5, 2)
---@param textColor check color docs
---@param bgColor check color docs
---@return CanvasClass
function CanvasClass:new(display, scale, textColor, bgColor)
	if display.setTextScale then
		display.setTextScale(scale or 0.5)
	end
	if scale == nil then
		scale = 0.5
	end
	local w, h = display.getSize()

	local obj = {
		x = 1,
		y = 1,
		display = display,
		scale = scale,
		displaySize = { w = w, h = h },
		symbols = {},
		width = w * 2,
		height = h * 3,
	}

	for i = 1, obj.displaySize.w do
		obj.symbols[i] = {}
		for j = 1, obj.displaySize.h do
			obj.symbols[i][j] = SymbolClass:new(display, i, j, textColor, bgColor)
		end
	end

	return setmetatable(obj, self)
end

---Set pixel by using pixel grid
---@param x number (pixels)
---@param y number (pixels)
---@param active boolean
function CanvasClass:setPixelByPixGrid(x, y, active)
	local symX, symY, column, row = _findPixelOnScreenByCords(x, y)
	if not _checkSymbolInBounds(symX, symY, self.symbols) then
		return
	end
	self.symbols[symX][symY].pixels:setPixel(column + 1, row + 1, active)
	self.symbols[symX][symY]:update()
end

---Get pixel by using pixel grid
---@param x number (pixels)
---@param y number (pixels)
---@return nil or Symbol
function CanvasClass:getPixelByPixGrid(x, y)
	local symX, symY, column, row = _findPixelOnScreenByCords(x, y)
	if not _checkSymbolInBounds(symX, symY, self.symbols) then
		return nil
	end
	return self.symbols[symX][symY].pixels:getPixel(column + 1, row + 1)
end

---Set pixel by using symbol grid
---@param symX number (symbol)
---@param symY number (symbol)
---@param column number (pixel in symbol, like 1,2)
---@param row number (pixel in symbol, like 1,2,3)
---@param active boolean
function CanvasClass:setPixelBySymGrid(symX, symY, column, row, active)
	if not _checkSymbolInBounds(symX, symY, self.symbols) then
		return
	end
	self.symbols[symX][symY].pixels:setPixel(column, row, active)
	self.symbols[symX][symY]:update()
end

---Get pixel by using symbol grid
---@param symX number (symbol)
---@param symY number (symbol)
---@param column number (pixel in symbol, like 1,2)
---@param row number (pixel in symbol, like 1,2,3)
---@return nil or Pixel
function CanvasClass:getPixelBySymGrid(symX, symY, column, row)
	if not _checkSymbolInBounds(symX, symY, self.symbols) then
		return
	end
	return self.symbols[symX][symY].pixels:getPixel(column, row)
end

---Get pixel cords by using symbol grid
---@param symX number (symbol)
---@param symY number (symbol)
---@param column number (pixel in symbol, like 1,2)
---@param row number (pixel in symbol, like 1,2,3)
---@return nil or number x*2, number y*3
function CanvasClass:getPixelCordsAsPixGrid(symX, symY, column, row)
	if not _checkSymbolInBounds(symX, symY, self.symbols) then
		return
	end
	return self.symbols[symX][symY]:getPixelCordsOnPixGrid(column, row)
end

---Draw canvas, needed for apply changes
function CanvasClass:draw()
	for j = self.y, (self.displaySize.h + self.y - 1) do
		self.display.setCursorPos(self.x, j)
		for i = self.x, (self.displaySize.w + self.x - 1) do
			self.symbols[i][j]:draw()
		end
	end
end

---Clear canvas
function CanvasClass:clear()
	for j = self.y, (self.displaySize.h + self.y - 1) do
		self.display.setCursorPos(self.x, j)
		for i = self.x, (self.displaySize.w + self.x - 1) do
			self.symbols[i][j]:clear()
		end
	end
end

---Change symbol color
---@param symX number (symbol)
---@param symY number (symbol)
---@param textColor check color docs
---@param bgColor check color docs
function CanvasClass:changeSymbolColor(symX, symY, textColor, bgColor)
	if self.symbols[symX] == nil or self.symbols[symX][symY] == nil then
		return
	end
	if not textColor and not bgColor then
		return
	end
	if textColor then
		self.symbols[symX][symY].textColor = textColor
	end
	if bgColor then
		self.symbols[symX][symY].bgColor = bgColor
	end
	self.symbols[symX][symY]:update()
end

---Get pixel cords by using symbol grid
function CanvasClass:getPixelCordsCenter()
	local symX, symY = self:getSymbolCordsCenter()
	return symX * 2, symY * 3
end

---Get symbol cords
function CanvasClass:getSymbolCordsCenter()
	local w, h = self.displaySize.w, self.displaySize.h
	local centerX, centerY
	if w % 2 == 0 then
		centerX = math.floor(w / 2) + 1
	else
		centerX = math.floor(w / 2)
	end
	if h % 2 == 0 then
		centerY = math.floor(h / 2) + 1
	else
		centerY = math.floor(h / 2)
	end
	return centerX, centerY
end

return CanvasClass
