-- term size is 26x20

local Relief = {}
Relief.__index = Relief

function Relief:new(winObj)
	local obj = {
		winObj = winObj,
	}
	setmetatable(obj, self)
	return obj
end

function Relief:drawLayer(matrixToDraw, layer)
	local centerX, centerY = self.winObj.canvas:getPixelCordsCenter()
	local count = 0
	for level, levelContent in pairs(matrixToDraw) do
		if level == layer then
			self.winObj.canvas:clear()
			for _, block in pairs(levelContent) do
				local blockX = centerX + block.x
				local blockZ = centerY + block.z
				self.winObj.canvas:setPixelByPixGrid(blockX, blockZ, true)
				count = count + 1
			end
		end
	end
	self.winObj.canvas:draw()
end

return Relief
