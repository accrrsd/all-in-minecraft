local function _loadJsonFromFile(filePath)
	local file = fs.open(filePath, "r")
	local content = file.readAll()
	file.close()
	return textutils.unserialiseJSON(content)
end

local function _matchColor(stringName)
	if stringName == "white" then
		return colors.white
	elseif stringName == "orange" then
		return colors.orange
	elseif stringName == "magenta" then
		return colors.magenta
	elseif stringName == "lightBlue" then
		return colors.lightBlue
	elseif stringName == "yellow" then
		return colors.yellow
	elseif stringName == "lime" then
		return colors.lime
	elseif stringName == "pink" then
		return colors.pink
	elseif stringName == "gray" then
		return colors.gray
	elseif stringName == "lightGray" then
		return colors.lightGray
	elseif stringName == "cyan" then
		return colors.cyan
	elseif stringName == "purple" then
		return colors.purple
	elseif stringName == "blue" then
		return colors.blue
	elseif stringName == "brown" then
		return colors.brown
	elseif stringName == "green" then
		return colors.green
	elseif stringName == "red" then
		return colors.red
	elseif stringName == "black" then
		return colors.black
	else
		return colors.white
	end
end

local function _setPriorityByTags(tagsPriorifyFilter, block)
	local maxPriority = 0
	if tagsPriorifyFilter and block.tags then
		for _, tag in pairs(block.tags) do
			for tag2, priority in pairs(tagsPriorifyFilter) do
				if tonumber(priority) and tag == tag2 then
					maxPriority = math.max(maxPriority, priority)
				end
			end
		end
	end
	return maxPriority ~= 0 and maxPriority or nil
end

local function _setPriorityByName(namePriorifyFilter, block)
	if namePriorifyFilter and block.name then
		for name, priority in pairs(namePriorifyFilter) do
			if tonumber(priority) and block.name == name then
				return priority
			end
		end
	end
	return nil
end

local function _checkBlockByTags(blockTagsFilter, block)
	if blockTagsFilter and block.tags then
		for _, tag in pairs(block.tags) do
			for tag2, _ in pairs(blockTagsFilter) do
				if tag == tag2 then
					return true
				end
			end
		end
	end
	return false
end

local function _checkBlockByName(blockNamesFilter, block)
	if blockNamesFilter and block.name then
		for name, _ in pairs(blockNamesFilter) do
			if block.name == name then
				return true
			end
		end
	end
	return false
end

local FiltersHandler = {}
FiltersHandler.__index = FiltersHandler

function FiltersHandler:new()
	local obj = {}
	obj.block_colors_by_name = (function()
		local data = _loadJsonFromFile("settings/colorByName.json")
		for k, v in pairs(data) do
			data[k] = _matchColor(v)
		end
		return data
	end)()
	obj.symbol_by_name = _loadJsonFromFile("settings/symbolByName.json")
	obj.blockTagsFilter = _loadJsonFromFile("settings/tagsFilter.json")
	obj.blockNamesFilter = _loadJsonFromFile("settings/nameFilter.json")
	obj.defaults = _loadJsonFromFile("settings/defaults.json")
	obj.priorityNameFilter = _loadJsonFromFile("settings/priorityByName.json")
	obj.priorityTagsFilter = _loadJsonFromFile("settings/priorityByTags.json")

	return setmetatable(obj, self)
end

function FiltersHandler:filterByTagsAndName(scan)
	local filteredScan = {}
	if not self.blockTagsFilter and not self.blockNamesFilter then
		return scan
	end
	for _, block in pairs(scan) do
		if _checkBlockByName(self.blockNamesFilter, block) or _checkBlockByTags(self.blockTagsFilter, block) then
			table.insert(filteredScan, block)
		end
	end
	return next(filteredScan) and filteredScan or scan
end

function FiltersHandler:setPriorityByTagsAndName(scan)
	local filteredScan = {}
	if not self.priorityTagsFilter and not self.priorityNameFilter then
		return scan
	end
	for _, block in pairs(scan) do
		local priorityByName = _setPriorityByName(self.priorityNameFilter, block) or 0
		local priorityByTags = _setPriorityByTags(self.priorityTagsFilter, block) or 0
		local priority = math.max(priorityByName, priorityByTags)
		block.priority = priority ~= 0 and priority or nil
		table.insert(filteredScan, block)
	end
	return next(filteredScan) and filteredScan or scan
end

return FiltersHandler
