-- dont use middleclass because its overkill, i just need a table with fabric, and its done.

local PixelsClass = _G.canvasLib.private.PixelsClass

--- That class provide a simple interface for symbol operations
local SymbolClass = {}
SymbolClass.__index = SymbolClass

---@param display table (window)
---@param symX number (symbol)
---@param symY number (symbol)
---@param textColor check color docs
---@param bgColor check color docs
---@return SymbolClass
function SymbolClass:new(display, symX, symY, textColor, bgColor)
	if not textColor then
		textColor = colors.white
	end

	if not bgColor then
		bgColor = colors.black
	end

	local obj = {
		textColor = textColor,
		bgColor = bgColor,
		pixels = PixelsClass:new(symX, symY),
		display = display,
		char = " ",
		invert = false,
	}

	return setmetatable(obj, self)
end

--- apply changes to symbol data
function SymbolClass:update()
	local char = 128
	local pData = self.pixels.data
	if not pData[2][3].active then
		char = char + (pData[1][1].active and 1 or 0)
		char = char + (pData[2][1].active and 2 or 0)
		char = char + (pData[1][2].active and 4 or 0)
		char = char + (pData[2][2].active and 8 or 0)
		char = char + (pData[1][3].active and 16 or 0)
		self.invert = false
	else
		char = char + (pData[1][1].active and 0 or 1)
		char = char + (pData[2][1].active and 0 or 2)
		char = char + (pData[1][2].active and 0 or 4)
		char = char + (pData[2][2].active and 0 or 8)
		char = char + (pData[1][3].active and 0 or 16)
		self.invert = true
	end
	self.char = string.char(char)
end

--- draw symbol
function SymbolClass:draw()
	if self.invert then
		self.display.setBackgroundColor(self.textColor)
		self.display.setTextColor(self.bgColor)
	else
		self.display.setBackgroundColor(self.bgColor)
		self.display.setTextColor(self.textColor)
	end
	self.display.write(self.char)
end

--- clear symbol data and redraw
function SymbolClass:clear()
	self.display.setBackgroundColor(self.bgColor)
	self.display.setTextColor(self.bgColor)

	for i = 1, 2 do
		for j = 1, 3 do
			self.pixels.data[i][j].active = false
		end
	end

	self:update()
	self.display.write(self.char)
	self.display.setBackgroundColor(self.bgColor)
	self.display.setTextColor(self.textColor)
end

return SymbolClass
