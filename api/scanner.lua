-- Scanner object with scanning and direction detection

local MAX_DISTANCE_FOR_NEIGHBOR = 5
local MAX_ANCHORS = 10

local function sign(x)
	if x > 0 then
		return 1
	elseif x < 0 then
		return -1
	else
		return 0
	end
end

local function _sortPattern(a, b)
	if a.name ~= b.name then
		return a.name < b.name
	elseif a.rx ~= b.rx then
		return a.rx < b.rx
	elseif a.ry ~= b.ry then
		return a.ry < b.ry
	else
		return a.rz < b.rz
	end
end

local function isFarEnough(newBlock, selectedBlocks, minDistance)
	for _, existingBlock in ipairs(selectedBlocks) do
		local distance = math.abs(newBlock.x - existingBlock.x)
			+ math.abs(newBlock.y - existingBlock.y)
			+ math.abs(newBlock.z - existingBlock.z)
		if distance < minDistance then
			return false
		end
	end
	return true
end

local function _calculateRelativeHash(block, scan)
	local neighbors = {}
	local maxDistanceFromRoot = MAX_DISTANCE_FOR_NEIGHBOR

	for _, otherBlock in ipairs(scan) do
		local rx = otherBlock.x - block.x
		local ry = otherBlock.y - block.y
		local rz = otherBlock.z - block.z
		local distance = math.abs(rx) + math.abs(ry) + math.abs(rz)
		if distance <= maxDistanceFromRoot and distance > 0 then
			table.insert(neighbors, { name = otherBlock.name, rx = rx, ry = ry, rz = rz })
		end
	end

	table.sort(neighbors, _sortPattern)

	local hash = ""
	for _, neighbor in ipairs(neighbors) do
		hash = hash .. neighbor.name .. neighbor.rx .. neighbor.ry .. neighbor.rz
	end
	return hash
end

local function _getRareRootBlocks(scan, maxCount)
	local nameCount = {}

	for _, block in ipairs(scan) do
		nameCount[block.name] = (nameCount[block.name] or 0) + 1
	end

	local rareBlocks = {}
	for name, count in pairs(nameCount) do
		table.insert(rareBlocks, { name = name, count = count })
	end

	table.sort(rareBlocks, function(a, b)
		return a.count < b.count -- Сортируем от редких к более частым
	end)

	local selectedBlocks = {}
	local addedBlocks = {}
	local count = 0
	local minDistance = MAX_DISTANCE_FOR_NEIGHBOR

	local rareBlockIndex = 1
	while count < maxCount do
		local rareBlock = rareBlocks[rareBlockIndex]
		if not rareBlock then
			break
		end

		for _, block in ipairs(scan) do
			if
				block.name == rareBlock.name
				and not addedBlocks[block]
				and isFarEnough(block, selectedBlocks, minDistance)
			then
				table.insert(selectedBlocks, block)
				addedBlocks[block] = true
				count = count + 1
				if count >= maxCount then
					return selectedBlocks
				end
			end
		end

		rareBlockIndex = rareBlockIndex + 1
		if rareBlockIndex > #rareBlocks then
			rareBlockIndex = 1
		end
	end

	return selectedBlocks
end

local function _generateAnchors(blocks)
	local anchors = {}
	for _, block in ipairs(blocks) do
		local hash = _calculateRelativeHash(block, blocks)
		anchors[hash] = block
	end
	return anchors
end

local function _calculateShifts(prevAnchors, currentAnchors)
	local shifts = { x = 0, y = 0, z = 0 }
	local count = 0
	for hash, _ in pairs(prevAnchors) do
		if currentAnchors[hash] then
			shifts.x = shifts.x + (currentAnchors[hash].x - prevAnchors[hash].x)
			shifts.y = shifts.y + (currentAnchors[hash].y - prevAnchors[hash].y)
			shifts.z = shifts.z + (currentAnchors[hash].z - prevAnchors[hash].z)
			count = count + 1
		end
	end

	local medium = {
		x = 0,
		y = 0,
		z = 0,
	}

	if count > 0 then
		medium.x = shifts.x / count
		medium.y = shifts.y / count
		medium.z = shifts.z / count
	end

	return shifts, count, medium
end

local function _getDirection(prevScan, currentScan)
	if not prevScan or not currentScan then
		return { x = 0, y = 0, z = 0 }
	end

	local prevRareAnchors = _generateAnchors(_getRareRootBlocks(prevScan, MAX_ANCHORS))
	local currentRareAnchors = _generateAnchors(_getRareRootBlocks(currentScan, MAX_ANCHORS))

	local rareShifts, rareCount, rareMedium = _calculateShifts(prevRareAnchors, currentRareAnchors)

	local count = rareCount

	local direction = {
		x = rareMedium.x,
		y = rareMedium.y,
		z = rareMedium.z,
	}

	-- for fit minecraft world directions
	for key, _ in pairs(direction) do
		direction[key] = direction[key] * -1
	end

	local normal2DDirs = {}

	normal2DDirs.y = sign(direction.y)

	local absX = math.abs(direction.x)
	local absZ = math.abs(direction.z)
	local maxDir = math.max(absX, absZ)

	if maxDir == absX then
		normal2DDirs.x = sign(direction.x)
		normal2DDirs.z = 0
	elseif maxDir == absZ then
		normal2DDirs.x = 0
		normal2DDirs.z = sign(direction.z)
	else
		normal2DDirs.x = sign(direction.x)
		normal2DDirs.z = sign(direction.z)
	end

	return normal2DDirs, rareShifts
end

local Scanner = {}
Scanner.__index = Scanner

--- @param side string
--- @param radius number
--- @return Scanner
function Scanner:new(side, radius)
	side = side or "back"
	radius = radius or 16

	local obj = {
		side = side,
		s = peripheral.wrap(side),
		error = nil,
		radius = radius,
		prevScan = nil,
		currentScan = nil,
	}

	setmetatable(obj, self)
	return obj
end

--- @param radius number
--- @return nil
function Scanner:changeRadius(radius)
	self.radius = radius
end

--- @param radius number
--- @return table
function Scanner:scan(radius)
	radius = radius or self.radius
	local res, err = self.s.scan(radius)
	self.error = err
	if res then
		if self.currentScan then
			self.prevScan = self.currentScan
		end
		self.currentScan = res
	end
	return res or nil
end

--- @return table,table directions, normalized and shifts
function Scanner:determineDirections()
	if not self.prevScan or not self.currentScan then
		return { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }
	end
	return _getDirection(self.prevScan, self.currentScan)
end

---@param scan table
---@return table
function Scanner:sortScanByLevel(scan)
	local res_by_level = {}
	for _, block in pairs(scan) do
		res_by_level[block.y] = res_by_level[block.y] or {}
		table.insert(res_by_level[block.y], block)
	end
	return res_by_level
end

return Scanner
