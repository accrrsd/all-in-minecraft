-- term size is 26x20
local ScannerClass = require("api/scanner")
local NumericClass = require("modes/numericMode")
local ReliefClass = require("modes/reliefMode")
local VisualLib = require("api/canvasLib/init")
local MatrixHandlerClass = require("api/matrixHandler")
local WindowClass = VisualLib.WindowClass
local FiltersHandlerClass = require("api/filtersHandler")

local scanner = ScannerClass:new("back", 16)

-- that variable use for proper retrun from help mode
local lastMode = "numeric"
local mode = "numeric"

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

local helpWin = (function()
	local Xoffset = 1
	local Yoffset = 4
	return WindowClass:new(term.current(), Xoffset, Yoffset, 26 - Xoffset + 1, 20 - Yoffset + 1, false, true, 0.5)
end)()

local matrixHandler = MatrixHandlerClass:new()
local filtersHandler = FiltersHandlerClass:new()

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
	term.setCursorPos(1, 3)
	term.write("Level: " .. matrixHandler.currentLevel)
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
		helpWin.win.setCursorPos(1, 11)
		helpWin.win.write("Arrow keys - rotate matrix")
		helpWin.win.setCursorPos(1, 13)
		helpWin.win.write("R - change autoRotate")
		helpWin.win.setCursorPos(1, 14)
		helpWin.win.write("current: " .. tostring(autoRotate))
		helpWin.win.setCursorPos(1, 16)
		helpWin.win.write("Use h or space to leave")
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
		end
	end
end

local function mainLoop()
	while true do
		local event, key = os.pullEvent("key")
		if key == keys.enter then
			local scanRes = scanner:scan()
			if scanRes then
				scanRes = filtersHandler:filter_by_tags_and_name(scanRes)
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
			numericWin.win.setVisible(mode == "numeric")
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
			if mode == "numeric" then
				numeric:addOffset({ x = 0, y = 3 })
				drawActiveScreen()
			end
		elseif key == keys.a then
			if mode == "numeric" then
				numeric:addOffset({ x = 3, y = 0 })
				drawActiveScreen()
			end
		elseif key == keys.s then
			if mode == "numeric" then
				numeric:addOffset({ x = 0, y = -3 })
				drawActiveScreen()
			end
		elseif key == keys.d then
			if mode == "numeric" then
				numeric:addOffset({ x = -3, y = 0 })
				drawActiveScreen()
			end
		elseif key == keys.space then
			lastMode = mode
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
