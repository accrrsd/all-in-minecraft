-- todo Подумать над тем, как сделать внутренний контент меньше при наличии границы, и больше при ее отсутствии, а так же подумать в сторону resize и drag

local function drawBorders(width, height, win)
	if width < 2 or height < 2 then
		return
	end
	win.setCursorPos(1, 1)
	win.write("+" .. string.rep("-", width - 2) .. "+")

	for i = 1, height do
		win.setCursorPos(1, i + 1)
		win.write("|")
		win.setCursorPos(width, i + 1)
		win.write("|")
	end

	win.setCursorPos(1, height + 1)
	win.write("+" .. string.rep("-", width - 2) .. "+")
end

local CanvasClass = _G.canvasLib.CanvasClass

--- That class uses for simplify window operations
local WindowClass = {}
WindowClass.__index = WindowClass

--- That class uses for simplify window operations
---@param source table (term or monitor)
---@param xPos number offset
---@param yPos number offset
---@param width number
---@param height number
---@param startVisible boolean
---@param createCanvas boolean
---@param scale number
function WindowClass:new(source, xPos, yPos, width, height, startVisible, createCanvas, scale, borders)
	if startVisible == nil then
		startVisible = true
	end
	if createCanvas == nil then
		createCanvas = true
	end
	if scale == nil then
		scale = 0.5
	end

	local sW, sH = source.getSize()

	local obj = {
		posX = xPos,
		posY = yPos,
		dirX = 0,
		dirY = 0,
		width = width,
		height = height,
		source = source,
		borders = borders,
		sourceSize = { w = sW, h = sH },
	}

	obj.win = window.create(source, obj.posX, obj.posY, obj.width, obj.height, startVisible)

	if createCanvas then
		obj.canvas = CanvasClass:new(obj.win, scale)
	elseif obj.source.setTextScale then
		obj.source.setTextScale(scale or 0.5)
	end

	return setmetatable(obj, self)
end

--- move window with offset
---@param x number
---@param y number
function WindowClass:moveWithOffset(x, y)
	if x == nil then
		x = obj.dirX
	end
	if y == nil then
		y = obj.dirY
	end
	self.posX = self.posX + x
	self.posY = self.posY + y
	self.win.reposition(self.posX, self.posY)
end

--- move window to new position
---@param x number
---@param y number
function WindowClass:moveTo(x, y)
	self.posX = x
	self.posY = y
	self.win.reposition(x, y)
end

--- give window impulse
---@param x number
---@param y number
function WindowClass:impulse(x, y)
	self.dirX = x
	self.dirY = y
end

--- move window using impulse
function WindowClass:moveWithImpulse()
	self:moveWithOffset(self.dirX, self.dirY)
end

--- get window size, with or without borders
function WindowClass:getSize()
	if self.borders then
		return self.width - 2, self.height - 2
	else
		return self.width, self.height
	end
end

--- draw window content and borders
function WindowClass:draw()
	if self.win.isVisible() == false then
		return
	end
	if self.canvas then
		self.canvas:draw()
	end
	self.win.redraw()
	if self.borders then
		local w, h = self:getSize()
		drawBorders(w, h, self.win)
	end
end

--- clear window
function WindowClass:clear()
	if self.canvas then
		self.canvas:clear()
	end
	self.win.clear()
end

--- get center of window
function WindowClass:getCenter()
	local w, h = self:getSize()
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

return WindowClass
