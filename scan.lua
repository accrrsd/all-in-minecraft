-- term size is 26x20

local ScannerClass = require("api/scanner")
local VisualLib = require("api/canvasLib/init")
local WindowClass = VisualLib.WindowClass

local currentLevel = 0

local Xoffset = 1
local Yoffset = 7

local winObj = WindowClass:new(term.current(), Xoffset, Yoffset, 26 - Xoffset + 1, 20 - Yoffset + 1, true, false, 0.5)

local scanner = ScannerClass:new("back", 16)

local canHandleColors = winObj.win.isColour()

--- Usual you want you one of them, not both (tags and filter)

--- Less specific filter
-- local block_tags_filter = nil
-- local block_tags_filter = { "minecraft:block/forge:ores" }

--- More specific filter
-- local block_names_filter = nil
-- local block_names_filter = { "minecraft:iron_ore" }

-- todo Добавить регулярное обновление (мб ленивое)
-- todo Добавить калибровку в сторону движения.

--- colors
local block_colors_by_name = {
	["minecraft:iron_ore"] = colors.gray,
	["minecraft:gold_ore"] = colors.orange,
	["minecraft:redstone_ore"] = colors.red,
	["minecraft:diamond_ore"] = colors.lightBlue,
	["minecraft:emerald_ore"] = colors.green,
	["minecraft:coal_ore"] = colors.brown,
}

local function check_block_tags(block)
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

local function check_block_name(block)
	if block.name then
		for _, name in pairs(block_names_filter) do
			if block.name == name then
				return true
			end
		end
	end
	return false
end

local function write_with_colors(text, symX, symY, color)
	if canHandleColors then
		if color == nil then
			color = colors.white
		end
		winObj.win.setTextColor(color)
	end
	winObj.win.setCursorPos(symX, symY)
	winObj.win.write(text)
	winObj.win.setTextColor(colors.white)
end

local function drawNumbers(target_level)
	local windowCenterX, windowCenterY = (function()
		local w, h = winObj.win.getSize()
		return math.floor(w / 2), math.floor(h / 2)
	end)()

	for level, levelContent in pairs(scanner.levels) do
		if level == target_level then
			for _, block in pairs(levelContent) do
				local pass = true
				if block_tags_filter then
					pass = check_block_tags(block)
				end
				if block_names_filter then
					pass = check_block_name(block)
				end
				if pass then
					local symX = windowCenterX + block.x
					local symY = windowCenterY + block.z
					local text = math.min(math.abs(block.x) + math.abs(block.z), 9)
					write_with_colors(text, symX, symY, block_colors_by_name[block.name])
				end
			end
		end
	end

	winObj.win.setCursorPos(windowCenterX, windowCenterY)
	winObj.win.write(" ")
end

local function updateScreen()
	term.clear()
	winObj.win.clear()
	local currentLevelStr = "Current level: " .. currentLevel
	term.setCursorPos((26 - #currentLevelStr) / 2 + 1, 5)
	term.write(currentLevelStr)
	drawNumbers(currentLevel)
end

local function changeCurrentLevel(val)
	if val > 0 and currentLevel + 1 <= #scanner.levels then
		currentLevel = currentLevel + 1
	elseif val < 0 then
		local lowestLevel = math.huge
		for level, levelContent in pairs(scanner.levels) do
			if level < lowestLevel then
				lowestLevel = level
			end
		end
		if currentLevel - 1 >= lowestLevel then
			currentLevel = currentLevel - 1
		end
	end
end

local function mainLoop()
	while true do
		local event, param1, param2 = os.pullEvent()
		if event == "key" then
			if param1 == keys.up then
				local prevCurrentLevel = currentLevel
				changeCurrentLevel(1)
				if prevCurrentLevel ~= currentLevel then
					updateScreen()
				end
			elseif param1 == keys.down then
				local prevCurrentLevel = currentLevel
				changeCurrentLevel(-1)
				if prevCurrentLevel ~= currentLevel then
					updateScreen()
				end
			elseif param1 == keys.backspace then
				term.clear()
				term.setCursorPos(1, 1)
				return
			elseif param1 == keys.enter then
				scanner:scan()
				updateScreen()
			end
		end
	end
end

scanner:scan()
updateScreen()
mainLoop()
