-- term size is 26x20

local ScannerClass = require("api/scanner")
local VisualLib = require("api/canvasLib/init")
local CanvasClass = VisualLib.CanvasClass
local WindowClass = VisualLib.WindowClass

local currentLevel = 0

local Xoffset = 2
local Yoffset = 7

local winObj = WindowClass:new(term.current(), Xoffset, Yoffset, 26 - Xoffset + 1, 20 - Yoffset + 1, true, true, 0.5)

local scanner = ScannerClass:new("back", 16)

local function drawMap(target_level)
	local windowCenterX, windowCenterY = winObj.canvas:getPixelCordsCenter()
	for level, levelContent in pairs(scanner.levels) do
		if level == target_level then
			for _, block in pairs(levelContent) do
				local blockX = windowCenterX + block.x
				local blockZ = windowCenterY + block.z
				winObj.canvas:setPixelByPixGrid(blockX, blockZ, true)
			end
		end
	end
end

local function updateScreen()
	term.clear()
	winObj.canvas:clear()
	local currentLevelStr = "Current level: " .. currentLevel
	term.setCursorPos((26 - #currentLevelStr) / 2 + 1, 5)
	term.write(currentLevelStr)
	drawMap(currentLevel)
	winObj.canvas:draw()
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
