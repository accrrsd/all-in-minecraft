local function loadJsonFromFile(filePath)
	local file = fs.open(filePath, "r")
	local content = file.readAll()
	file.close()
	return textutils.unserialiseJSON(content)
end

local function matchColor(stringName)
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

local function check_block_tags(block_tags_filter, block)
	if block_tags_filter and block.tags then
		for _, tag in pairs(block.tags) do
			for _, tag2 in pairs(block_tags_filter) do
				if tag == tag2 then
					return true
				end
			end
		end
	end
	return false
end

local function check_block_name(block_names_filter, block)
	if block_names_filter and block.name then
		for _, name in pairs(block_names_filter) do
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
		local data = loadJsonFromFile("settings/colorByName.json")
		for k, v in pairs(data) do
			data[k] = matchColor(v)
		end
		return data
	end)()
	obj.symbol_by_name = loadJsonFromFile("settings/symbolByName.json")
	obj.block_tags_filter = loadJsonFromFile("settings/tagsFilter.json")
	obj.block_names_filter = loadJsonFromFile("settings/nameFilter.json")
	obj.defaults = loadJsonFromFile("settings/defaults.json")

	return setmetatable(obj, self)
end

function FiltersHandler:filter_by_tags_and_name(scan)
	local filteredScan = {}
	for _, block in pairs(scan) do
		if check_block_name(self.block_names_filter, block) or check_block_tags(self.block_tags_filter, block) then
			table.insert(filteredScan, block)
		end
	end
	return next(filteredScan) and filteredScan or scan
end

return FiltersHandler
