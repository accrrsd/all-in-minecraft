local CanvasClass = _G.canvasLib.CanvasClass

--- That class uses for simplify window operations
local WindowClass = {}
WindowClass.__index = WindowClass

function WindowClass:new(source, xPos, yPos, width, height, startVisible, createCanvas, canvasScale)
	local obj = {}
	setmetatable(obj, self)

	if startVisible == nil then
		startVisible = true
	end
	if createCanvas == nil then
		createCanvas = true
	end
	if canvasScale == nil then
		canvasScale = 0.5
	end

	local sW, sH = source.getSize()
	obj.posX = xPos
	obj.posY = yPos
	obj.dirX = 0
	obj.dirY = 0
	obj.width = width
	obj.height = height
	obj.source = source
	obj.sourceSize = { w = sW, h = sH }

	obj.win = window.create(source, obj.posX, obj.posY, obj.width, obj.height, startVisible)

	if createCanvas then
		obj.canvas = CanvasClass:new(obj.win, canvasScale)
	elseif obj.source.setTextScale then
		obj.source.setTextScale(scale or 0.5)
	end

	return obj
end

function WindowClass:move(x, y)
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

function WindowClass:moveTo(x, y)
	self.posX = x
	self.posY = y
	self.win.reposition(x, y)
end

function WindowClass:impulse(x, y)
	self.dirX = x
	self.dirY = y
end

function WindowClass:getCenter()
	return math.floor(self.width / 2) + 1, math.floor(self.height / 2) + 1
end

return WindowClass
