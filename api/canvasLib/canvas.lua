-- dont use middleclass because its overkill, i just need a table with fabric, and its done.

local SymbolClass = _G.canvasLib.private.SymbolClass

--- That class uses for simlify canvas operations on settet window.
local CanvasClass = {}
CanvasClass.__index = CanvasClass

---@param display table (window)
---@param scale number (0.5, 1, 1.5, 2)
---@param textColor check color docs
---@param bgColor check color docs
function CanvasClass:new(display, scale, textColor, bgColor)
	local obj = {}
	setmetatable(obj, self)

	if display.setTextScale then
		display.setTextScale(scale or 0.5)
	end
	if scale == nil then
		scale = 0.5
	end

	obj.x = 1
	obj.y = 1
	obj.display = display
	obj.scale = scale
	local w, h = display.getSize()
	obj.displaySize = { w = w, h = h }
	obj.symbols = {}
	obj.width = w * 2
	obj.height = h * 3
	for i = 1, obj.displaySize.w do
		obj.symbols[i] = {}
		for j = 1, obj.displaySize.h do
			obj.symbols[i][j] = SymbolClass:new(display, i, j, textColor, bgColor)
		end
	end
	return obj
end

---@param symX number (symbol)
---@param symY number (symbol)
---@return boolean
local function _checkSymbolInBounds(symX, symY, symbols)
	if symX < 1 or symX > #symbols or symY < 1 or symY > #symbols[symX] then
		return false
	end
	return true
end

---@param x number (in pixels)
---@param y number (in pixels)
---@return symX number (symbol), symY number (symbol), column number (pixel in symbol, like 1,2), row number (pixel in symbol, like 1,2,3)
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

function CanvasClass:draw()
	for j = self.y, (self.displaySize.h + self.y - 1) do
		self.display.setCursorPos(self.x, j)
		for i = self.x, (self.displaySize.w + self.x - 1) do
			self.symbols[i][j]:draw()
		end
	end
end

function CanvasClass:clear()
	for j = self.y, (self.displaySize.h + self.y - 1) do
		self.display.setCursorPos(self.x, j)
		for i = self.x, (self.displaySize.w + self.x - 1) do
			self.symbols[i][j]:clear()
		end
	end
end

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

function CanvasClass:getPixelCordsCenter()
	local symX, symY = self:getSymbolCordsCenter()
	return symX * 2, symY * 3
end

function CanvasClass:getSymbolCordsCenter()
	return math.floor(self.displaySize.w / 2), math.floor(self.displaySize.h / 2)
end

return CanvasClass
