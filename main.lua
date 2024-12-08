-- term size is 26x20
local ScannerClass = require("api/scanner")
local NumericClass = require("modes/numericMode")
local ReliefClass = require("modes/reliefMode")
local VisualLib = require("api/canvasLib/init")
local MatrixHandlerClass = require("api/matrixHandler")
local WindowClass = VisualLib.WindowClass
local FiltersHandlerClass = require("api/filtersHandler")

local matrixHandler = MatrixHandlerClass:new()
local filtersHandler = FiltersHandlerClass:new()

local scanner = ScannerClass:new("back", filtersHandler.defaults.scanRadius)

-- that variable use for proper retrun from help mode
local lastMode = filtersHandler.defaults.mode
local mode = filtersHandler.defaults.mode
local autoRotate = filtersHandler.defaults.autoRotate
local heightMode = filtersHandler.defaults.heightMode

local numericWin = (function()
	local Xoffset = 1
	local Yoffset = 4
	return WindowClass:new({
		source = term.current(),
		xPos = Xoffset,
		yPos = Yoffset,
		width = 26 - Xoffset + 1,
		height = 20 - Yoffset + 1,
		startVisible = mode == "numeric",
		createCanvas = false,
	})
end)()

local reliefWin = (function()
	local Xoffset = 1
	local Yoffset = 4
	return WindowClass:new({
		source = term.current(),
		xPos = Xoffset,
		yPos = Yoffset,
		width = 26 - Xoffset + 1,
		height = 20 - Yoffset + 1,
		startVisible = mode == "relief",
		createCanvas = true,
	})
end)()

local helpWin = (function()
	local Xoffset = 1
	return WindowClass:new({
		source = term.current(),
		xPos = Xoffset,
		yPos = -1,
		width = 26 - Xoffset + 1,
		height = 24,
		startVisible = false,
		createCanvas = false,
	})
end)()

local numeric = NumericClass:new(numericWin)
local relief = ReliefClass:new(reliefWin)

local function updateTitle()
	local width, height = term.getSize()
	local title = "X-Vision"
	term.setCursorPos(math.floor((width - #title) / 2) + 1, 1)
	term.clearLine()
	term.write(title)
	term.setCursorPos(1, 2)
	term.clearLine()
	term.write("mode: " .. mode)
	local helpText = "[H]elp"
	term.setCursorPos(math.floor(width - #helpText), 2)
	term.write(helpText)
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
	if mode ~= "p-numeric" then
		term.setCursorPos(1, 3)
		term.write("Level: " .. matrixHandler.currentLevel)
	elseif heightMode then
		term.setCursorPos(1, 3)
		term.write("dir: " .. heightMode)
	end
end

local function drawActiveScreen()
	local rotatedMatrix, currentLevel = matrixHandler:getCurrentMatrix()

	if mode == "help" then
		local width, height = helpWin.win.getSize()
		local welcome = "Welcome to X-Vision!"
		helpWin.win.clear()
		helpWin.win.setCursorPos(math.floor((width - #welcome) / 2) + 1, 3)
		helpWin.win.write(welcome)
		helpWin.win.setCursorPos(1, 5)
		helpWin.win.write("Enter - scan area")
		helpWin.win.setCursorPos(1, 6)
		helpWin.win.write("Backspace - exit program")
		helpWin.win.setCursorPos(1, 7)
		helpWin.win.write("Space - switch mode")
		helpWin.win.setCursorPos(1, 8)
		helpWin.win.write("W, A, S, D - move in")
		helpWin.win.setCursorPos(1, 9)
		helpWin.win.write("numeric mode")
		helpWin.win.setCursorPos(1, 10)
		helpWin.win.write("P - switch to p-numeric")
		helpWin.win.setCursorPos(1, 12)
		helpWin.win.write("Arrow keys:")
		helpWin.win.setCursorPos(1, 13)
		helpWin.win.write("left-right - rotate matrix")
		helpWin.win.setCursorPos(1, 14)
		helpWin.win.write("up-down - change level")
		helpWin.win.setCursorPos(1, 15)
		helpWin.win.write("or direction in p-numeric")
		helpWin.win.setCursorPos(1, 17)
		helpWin.win.write("R - change autoRotate")
		helpWin.win.setCursorPos(1, 18)
		helpWin.win.write("current: " .. tostring(autoRotate))
		helpWin.win.setCursorPos(1, 19)
		helpWin.win.write("Use H or space to leave")
	end

	if rotatedMatrix then
		if mode == "numeric" then
			numeric:drawLayer(
				rotatedMatrix,
				currentLevel,
				filtersHandler.block_colors_by_name,
				filtersHandler.symbol_by_name
			)
		elseif mode == "relief" then
			relief:drawLayer(rotatedMatrix, currentLevel)
		elseif mode == "p-numeric" then
			numeric:drawPriorityLayer(
				rotatedMatrix,
				heightMode,
				filtersHandler.block_colors_by_name,
				filtersHandler.symbol_by_name
			)
		end
	end
end

local function mainLoop()
	while true do
		local event, key = os.pullEvent("key")
		if key == keys.enter then
			local scanRes = scanner:scan()
			if scanRes then
				scanRes = filtersHandler:filterByTagsAndName(scanRes)
				scanRes = filtersHandler:setPriorityByTagsAndName(scanRes)
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
		elseif key == keys.h then
			if mode == "help" then
				mode = lastMode
			else
				mode = "help"
			end
			numericWin.win.setVisible(mode == "numeric" or mode == "p-numeric")
			reliefWin.win.setVisible(mode == "relief")
			helpWin.win.setVisible(mode == "help")
			updateTitle()
			drawActiveScreen()
		elseif key == keys.r then
			autoRotate = not autoRotate
			if mode == "help" then
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
			if mode == "p-numeric" then
				if heightMode ~= "up" then
					heightMode = "up"
					updateTitle()
					drawActiveScreen()
				end
			elseif matrixHandler:changeLevel(1) then
				updateTitle()
				drawActiveScreen()
			end
		elseif key == keys.down then
			if mode == "p-numeric" then
				if heightMode ~= "down" then
					heightMode = "down"
					updateTitle()
					drawActiveScreen()
				end
			elseif matrixHandler:changeLevel(-1) then
				updateTitle()
				drawActiveScreen()
			end
		elseif key == keys.w then
			if mode == "numeric" or mode == "p-numeric" then
				numeric:addOffset({ x = 0, y = 3 })
				drawActiveScreen()
			end
		elseif key == keys.a then
			if mode == "numeric" or mode == "p-numeric" then
				numeric:addOffset({ x = 3, y = 0 })
				drawActiveScreen()
			end
		elseif key == keys.s then
			if mode == "numeric" or mode == "p-numeric" then
				numeric:addOffset({ x = 0, y = -3 })
				drawActiveScreen()
			end
		elseif key == keys.d then
			if mode == "numeric" or mode == "p-numeric" then
				numeric:addOffset({ x = -3, y = 0 })
				drawActiveScreen()
			end
		elseif key == keys.p then
			if mode == "numeric" then
				mode = "p-numeric"
				lastMode = mode
				numericWin.win.setVisible(mode == "p-numeric")
				reliefWin.win.setVisible(mode == "relief")
				updateTitle()
				drawActiveScreen()
			elseif mode == "p-numeric" then
				mode = "numeric"
				lastMode = mode
				numericWin.win.setVisible(mode == "numeric")
				reliefWin.win.setVisible(mode == "relief")
				updateTitle()
				drawActiveScreen()
			end
		elseif key == keys.space then
			mode = (mode == "numeric") and "relief" or "numeric"
			lastMode = mode
			numericWin.win.setVisible(mode == "numeric" or mode == "p-numeric")
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
if filtersHandler.defaults.firstScan then
	local scanRes = scanner:scan()
	if scanRes then
		scanRes = filtersHandler:filterByTagsAndName(scanRes)
		scanRes = filtersHandler:setPriorityByTagsAndName(scanRes)
		matrixHandler:loadMatrix(scanner:sortScanByLevel(scanRes))
		updateTitle()
		drawActiveScreen()
	end
else
	updateTitle()
end
mainLoop()
