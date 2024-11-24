-- term size is 26x20
local ScannerClass = require("api/scanner")
local NumericClass = require("modes/numericMode")
local ReliefClass = require("modes/reliefMode")
local VisualLib = require("api/canvasLib/init")
local MatrixHandler = require("api/matrixHandler")
local WindowClass = VisualLib.WindowClass

local scanner = ScannerClass:new("back", 16)
local mode = "numeric"
local matrixHandler = MatrixHandler:new()

local autoRotate = true

local numericWin = (function()
	local Xoffset = 1
	local Yoffset = 4
	return WindowClass:new(
		term.current(),
		Xoffset,
		Yoffset,
		26 - Xoffset + 1,
		20 - Yoffset + 1,
		mode == "numeric",
		false,
		0.5
	)
end)()

local reliefWin = (function()
	local Xoffset = 1
	local Yoffset = 4
	return WindowClass:new(
		term.current(),
		Xoffset,
		Yoffset,
		26 - Xoffset + 1,
		20 - Yoffset + 1,
		mode == "relief",
		true,
		0.5
	)
end)()

local numeric = NumericClass:new(numericWin)
local relief = ReliefClass:new(reliefWin)

--- colors
local block_colors_by_name = {
	["minecraft:iron_ore"] = colors.lightGray,
	["minecraft:deepslate_iron_ore"] = colors.lightGray,
	["minecraft:gold_ore"] = colors.orange,
	["minecraft:deepslate_gold_ore"] = colors.orange,
	["minecraft:redstone_ore"] = colors.red,
	["minecraft:deepslate_redstone_ore"] = colors.red,
	["minecraft:diamond_ore"] = colors.lightBlue,
	["minecraft:deepslate_diamond_ore"] = colors.lightBlue,
	["minecraft:emerald_ore"] = colors.green,
	["minecraft:deepslate_emerald_ore"] = colors.green,
	["minecraft:coal_ore"] = colors.gray,
	["minecraft:deepslate_coal_ore"] = colors.gray,
	["minecraft:copper_ore"] = colors.brown,
	["minecraft:deepslate_copper_ore"] = colors.brown,
}

-- less specific filter
local block_tags_filter = nil
-- more specific filter
local block_names_filter = nil

--- examples
--- Usual you want you one of them, not both (tags and filter)
-- local block_tags_filter = { "minecraft:block/forge:ores" }
-- local block_names_filter = { "minecraft:iron_ore" }

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

local function updateTitle()
	local width, height = term.getSize()
	local title = "X-Vision: " .. mode
	term.setCursorPos(math.floor((width - #title) / 2) + 1, 1)
	term.clearLine()
	term.write(title)
	term.setCursorPos(1, 3)
	term.clearLine()
	local dirs = matrixHandler.directions[matrixHandler.directionIndex]
	if dirs then
		local text = "Axis: "
		if dirs.x > 0 then
			text = text .. "+X"
		elseif dirs.x < 0 then
			text = text .. "-X"
		elseif dirs.z > 0 then
			text = text .. "+Z"
		elseif dirs.z < 0 then
			text = text .. "-Z"
		end
		term.setCursorPos(width - #text + 1, 3)
		term.write(text)
	end
	term.setCursorPos(1, 3)
	term.write("Level: " .. matrixHandler.currentLevel)
end

local function drawActiveScreen()
	local rotatedMatrix, currentLevel = matrixHandler:getCurrentMatrix()
	if rotatedMatrix then
		if mode == "numeric" then
			numeric:drawLayer(rotatedMatrix, currentLevel, block_colors_by_name)
		elseif mode == "relief" then
			relief:drawLayer(rotatedMatrix, currentLevel)
		end
	end
end

local function mainLoop()
	while true do
		local event, key = os.pullEvent("key")
		if key == keys.enter then
			local scanRes = scanner:scan()
			if scanRes then
				matrixHandler:loadMatrix(scanner:sortScanByLevel(scanRes))
				if autoRotate and scanner.prevScan then
					local dir = scanner:determineDirections()
					if dir then
						matrixHandler:setDirection(dir)
					end
				end
				numeric:setOffset({ x = 0, y = 0 })
				updateTitle()
				drawActiveScreen()
			end
		elseif key == keys.right then
			matrixHandler:setDirectionIndex(1)
			updateTitle()
			drawActiveScreen()
		elseif key == keys.left then
			matrixHandler:setDirectionIndex(-1)
			updateTitle()
			drawActiveScreen()
		elseif key == keys.up then
			if matrixHandler:changeLevel(1) then
				updateTitle()
				drawActiveScreen()
			end
		elseif key == keys.down then
			if matrixHandler:changeLevel(-1) then
				updateTitle()
				drawActiveScreen()
			end
		elseif key == keys.w then
			numeric:addOffset({ x = 0, y = 3 })
			drawActiveScreen()
		elseif key == keys.a then
			numeric:addOffset({ x = 3, y = 0 })
			drawActiveScreen()
		elseif key == keys.s then
			numeric:addOffset({ x = 0, y = -3 })
			drawActiveScreen()
		elseif key == keys.d then
			numeric:addOffset({ x = -3, y = 0 })
			drawActiveScreen()
		elseif key == keys.space then
			mode = (mode == "numeric") and "relief" or "numeric"
			numericWin.win.setVisible(mode == "numeric")
			reliefWin.win.setVisible(mode == "relief")
			updateTitle()
			drawActiveScreen()
		elseif key == keys.backspace then
			term.clear()
			term.setCursorPos(1, 1)
			return
		end
	end
end

term.clear()
updateTitle()
mainLoop()
