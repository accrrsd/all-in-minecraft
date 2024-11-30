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
function WindowClass:new(source, xPos, yPos, width, height, startVisible, createCanvas, scale)
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
function WindowClass:moveTo(x, y)
	self.posX = x
	self.posY = y
	self.win.reposition(x, y)
end

--- give window impulse
function WindowClass:impulse(x, y)
	self.dirX = x
	self.dirY = y
end

--- move window using impulse
function WindowClass:moveWithImpulse()
	self:moveWithOffset(self.dirX, self.dirY)
end

--- get center of window
function WindowClass:getCenter()
	local w, h = self.width, self.height
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
