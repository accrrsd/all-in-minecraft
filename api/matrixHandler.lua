local MatrixHandler = {}
MatrixHandler.__index = MatrixHandler

function MatrixHandler:new()
	local obj = {
		matrix = nil,
		rotatedMatrix = nil,
		currentLevel = 0,
		directionIndex = 4,
		isMatrixOutOfDate = true,
		directions = {
			{ x = 1, z = 0 }, -- +x
			{ x = 0, z = 1 }, -- +z
			{ x = -1, z = 0 }, -- -x
			{ x = 0, z = -1 }, -- -z
		},
	}
	setmetatable(obj, self)
	return obj
end

---@param newMatrix table scan from scanner
function MatrixHandler:loadMatrix(newMatrix)
	self.matrix = newMatrix
	self.currentLevel = 0
	self.isMatrixOutOfDate = true
end

---@param offset number
function MatrixHandler:setDirectionIndex(offset)
	self.directionIndex = (self.directionIndex + offset - 1) % #self.directions + 1
	self.isMatrixOutOfDate = true
end

function MatrixHandler:setDirection(dir)
	for i = 1, #self.directions do
		if self.directions[i].x == dir.x and self.directions[i].z == dir.z then
			self.directionIndex = i
			self.isMatrixOutOfDate = true
		end
	end
end

---@param offset number
---@return bool level was changed
function MatrixHandler:changeLevel(offset)
	if not self.matrix then
		return
	end

	local maxLevel = -math.huge
	local minLevel = math.huge
	for level, _ in pairs(self.matrix) do
		if level > maxLevel then
			maxLevel = level
		end
		if level < minLevel then
			minLevel = level
		end
	end
	if minLevel == math.huge then
		minLevel = 0
	end

	local newLevel = math.max(minLevel, math.min(self.currentLevel + offset, maxLevel))
	if newLevel ~= self.currentLevel then
		self.currentLevel = newLevel
		return true
	end
	return false
end

---@return table
function MatrixHandler:rotateMatrix()
	if not self.matrix then
		return nil
	end

	if self.isMatrixOutOfDate then
		local direction = self.directions[self.directionIndex]
		self.rotatedMatrix = self:rotateLevelSortedMatrix(self.matrix, direction)
		self.isMatrixOutOfDate = false
	end

	return self.rotatedMatrix
end

---@param scan table
---@param direction table
---@return table
function MatrixHandler:rotateLevelSortedMatrix(scan, direction)
	local rotatedMatrix = {}

	for yLevel, blocks in pairs(scan) do
		if not rotatedMatrix[yLevel] then
			rotatedMatrix[yLevel] = {}
		end

		for _, block in ipairs(blocks) do
			if block.x and block.z then
				local x, z = block.x, block.z

				if direction.z == 1 then
					x, z = -x, -z
				elseif direction.z == -1 then
					x, z = x, z
				elseif direction.x == 1 then
					x, z = z, -x
				elseif direction.x == -1 then
					x, z = -z, x
				end

				table.insert(rotatedMatrix[yLevel], {
					x = x,
					y = block.y,
					z = z,
					name = block.name,
					tags = block.tags,
					priority = block.priority,
				})
			end
		end
	end
	return rotatedMatrix
end

---@return table, number
function MatrixHandler:getCurrentMatrix()
	return self:rotateMatrix(), self.currentLevel
end

return MatrixHandler
