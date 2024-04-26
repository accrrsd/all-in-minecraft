LegsApi = require("legsApi")
BasicApi = require("basicApi")
BasicApi = require("basicApi")
GeneralApi = require("generalApi")
StorageApi = require("storageApi")

DisplayApi = {}
-- #2E2114 = 	rgb(46, 33, 20)

DisplayApi.createSquare = function(cords, color, fill)
	fill = fill == nil and true or fill
	color = color == nil and colors.orange or color
	local a, b, c, d = unpack(cords)
	if fill then
		paintutils.drawFilledBox(a, b, c, d, color)
	else
		paintutils.drawBox(a, b, c, d, color)
	end
	return cords
end

DisplayApi.stylishClear = function(fgColor, bgColor)
	fgColor = fgColor or colors.orange
	bgColor = bgColor or colors.brown
	term.setTextColor(fgColor)
	term.setBackgroundColor(bgColor)
	term.clear()
	term.setCursorPos(0, 0)
end

DisplayApi.getCenterStrokeCord = function(text, wOrh, customValue)
	local w, h
	if customValue ~= nil then
		w, h = unpack(customValue)
	else
		w, h = term.getSize()
	end
	if wOrh == "h" then
		return BasicApi.round((h - #text) / 2)
	elseif wOrh == "w" then
		return BasicApi.round((w - #text) / 2)
	else
		return BasicApi.round((w - #text) / 2), BasicApi.round((h - 1) / 2)
	end
end

DisplayApi.pressButton = function(cords, textCords, text)
	local c1, c2, c3, c4 = unpack(cords)
	local tc1, tc2 = unpack(textCords)

	paintutils.drawFilledBox(c1, c2, c3, c4, colors.gray)
	term.setCursorPos(tc1, tc2)
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.gray)
	term.write(text)

	os.sleep(0.1)

	paintutils.drawFilledBox(c1, c2, c3, c4, colors.orange)
	term.setCursorPos(tc1, tc2)
	term.setTextColor(colors.black)
	term.setBackgroundColor(colors.orange)
	term.write(text)

	term.setCursorPos(0, 0)
end

DisplayApi.drawText = function(x, y, text, color, bgColor, name)
	if x == nil or y == nil then
		return
	end
	if color ~= nil then
		term.setTextColor(color)
	end
	if bgColor ~= nil then
		term.setBackgroundColor(bgColor)
	end
	term.setCursorPos(x, y)
	term.write(text)
	return { x, y }, name or text
end

DisplayApi.MouseEventInsideSquare = function(mx, my, cords)
	local x, y, x2, y2 = unpack(cords)
	if mx >= x and my >= y and mx <= x2 and my <= y2 then
		return true
	else
		return false
	end
end

DisplayApi.mainMenu = function()
	local function mainMenuBackground()
		DisplayApi.stylishClear()
		local startLogoCord = 13
		DisplayApi.drawText(startLogoCord, 1, "   _  __  _____   __  ___")
		DisplayApi.drawText(startLogoCord, 2, "  | |/ / |__  /  /  |/  /")
		DisplayApi.drawText(startLogoCord, 3, "  |   /   /_ <  / /|_/ / ")
		DisplayApi.drawText(startLogoCord, 4, " /   |_ ___/ / / /  / /  ")
		DisplayApi.drawText(startLogoCord, 5, "/_/|_(_)____(_)_/  /_/   ")
		DisplayApi.drawText(startLogoCord, 6, "")
		DisplayApi.drawText(18, 7, "STATUS:")
		DisplayApi.drawText(18 + #"STATUS:", 7, "AWAITING", colors.lightGray)
	end

	local function OptionsMenu(array, x, y, spaceBetweenOptions)
		-- options settings
		spaceBetweenOptions = spaceBetweenOptions == nil and 3 or spaceBetweenOptions
		array = array == nil and { "Mine", "Storage", "Move" } or array
		-- start cords
		x = x == nil and 19 or x
		y = y == nil and 8 or y

		local select = 1

		-- cords for button press work
		local optionsCords = {}
		local optionsTextCords = {}

		local function printOptions()
			for i = 1, #array do
				local resultY = y + spaceBetweenOptions * i
				local squareCords = { x - 1, resultY - 1, x + 12, resultY + 1 }
				local textCords, textName
				if select == i then
					optionsCords[i] = DisplayApi.createSquare(squareCords, colors.orange)
					textCords, textName = DisplayApi.drawText(x, resultY, array[i], colors.black)
				else
					optionsCords[i] = DisplayApi.createSquare(squareCords, colors.brown)
					textCords, textName = DisplayApi.drawText(x, resultY, array[i], colors.orange)
				end
				optionsTextCords[i] = { cords = textCords, name = textName }
				term.setCursorPos(0, 0)
			end
		end

		local function confirmSelect()
			printOptions()
			DisplayApi.pressButton(
				optionsCords[select],
				optionsTextCords[select]["cords"],
				optionsTextCords[select]["name"]
			)
			os.sleep(0.1)
		end

		-- do things
		printOptions()
		while true do
			local event, param1, param2, param3 = os.pullEvent()
			-- handle mouse select
			if event == "mouse_click" then
				local res = false
				for i = 1, #optionsCords do
					if DisplayApi.MouseEventInsideSquare(param2, param3, optionsCords[i]) then
						select = i
						res = true
					end
				end
				if res == true then
					confirmSelect()
					return array[select]
				end
			end
			if event == "key" then
				if param1 == keys.enter then
					confirmSelect()
					return array[select]
				elseif #array > 1 then
					if param1 == keys.up or param1 == keys.w then
						select = select - 1 < 1 and #array or select - 1
						printOptions()
					elseif param1 == keys.down or param1 == keys.s then
						select = select + 1 > #array and 1 or select + 1
						printOptions()
					end
				end
			end
		end
	end

	mainMenuBackground()
	local selected = OptionsMenu()
	if selected == "Move" then
		return DisplayApi.moveMenu()
	elseif selected == "Storage" then
		return DisplayApi.storageMenu()
	end
end

DisplayApi.moveMenu = function()
	-- check if we here without finded legs
	if LegsApi.legsFinded == false then
		parallel.waitForAny(function()
			DisplayApi.simpleLoader("Await legs...", 0, 0, true)
		end, function()
			local wasFinded = LegsApi.legsFinded
			while wasFinded == false do
				os.sleep(1)
				wasFinded = LegsApi.legsFinded
			end
		end)
	end

	-- clear menu
	DisplayApi.stylishClear()

	local keyCords = {}
	local keyText = {}
	local movingSomething = false

	local bufferCopy = (function()
		local originalBuffer = LegsApi.ReadBuffer()
		if originalBuffer == nil then
			return nil
		end
		return { unpack(originalBuffer) }
	end)()

	local function createButtons()
		keyCords["w"] = DisplayApi.createSquare({ 8, 3, 10, 5 })
		keyCords["a"] = DisplayApi.createSquare({ 4, 7, 6, 9 })
		keyCords["d"] = DisplayApi.createSquare({ 12, 7, 14, 9 })
		keyCords["s"] = DisplayApi.createSquare({ 8, 11, 10, 13 })
		keyCords["up"] = DisplayApi.createSquare({ 4 - 1, 16 - 1, 4 + 2, 16 + 1 })
		keyCords["down"] = DisplayApi.createSquare({ 14 - 1, 16 - 1, 14 + #"Down", 16 + 1 })
		keyCords["apply"] = DisplayApi.createSquare({ 23, 10, 23 + 7, 10 + 2 })
		keyCords["back"] = DisplayApi.createSquare({ 23, 14, 23 + 7, 14 + 2 })
		keyCords["removeLast"] = DisplayApi.createSquare({ 40, 0, 55, 0 + 1 })
		keyCords["list"] = DisplayApi.createSquare({ 40, 2, 55, 30 })
		keyCords["inputButton"] = DisplayApi.createSquare({ 20, 1, 35, 3 })
		keyCords["calibrateButton"] = DisplayApi.createSquare({ 20, 5, 35, 7 })

		term.setTextColor(colors.black)
		term.setBackgroundColor(colors.orange)

		local temp1, temp2

		temp1, temp2 = DisplayApi.drawText(9, 4, "W")
		keyText[temp2] = temp1

		temp1, temp2 = DisplayApi.drawText(5, 8, "A")
		keyText[temp2] = temp1

		temp1, temp2 = DisplayApi.drawText(13, 8, "D")
		keyText[temp2] = temp1

		temp1, temp2 = DisplayApi.drawText(9, 12, "S")
		keyText[temp2] = temp1

		temp1, temp2 = DisplayApi.drawText(4, 16, "Up")
		keyText[temp2] = temp1

		temp1, temp2 = DisplayApi.drawText(14, 16, "Down")
		keyText[temp2] = temp1

		temp1, temp2 = DisplayApi.drawText(24, 11, "Apply")
		keyText[temp2] = temp1

		temp1, temp2 = DisplayApi.drawText(24, 15, "Back")
		keyText[temp2] = temp1

		temp1, temp2 = DisplayApi.drawText(41, 1, "Remove last")
		keyText[temp2] = temp1

		temp1, temp2 = DisplayApi.drawText(21, 2, "Write command")
		keyText[temp2] = temp1

		temp1, temp2 = DisplayApi.drawText(22, 6, "Legs Calibr.")
		keyText[temp2] = temp1

		term.setCursorPos(0, 0)
	end

	local bufferCopyApi = {}

	bufferCopyApi.removeLast = function()
		if bufferCopy == nil then
			return nil
		end
		table.remove(bufferCopy, #bufferCopy)
	end

	bufferCopyApi.addLast = function(command)
		if bufferCopy == nil then
			bufferCopy = {}
		end
		table.insert(bufferCopy, command)
	end

	local function unpackMovementPresets(tableWithCommands)
		if tableWithCommands == nil then
			return nil
		end
		for i = 1, #tableWithCommands do
			local command = tableWithCommands[i]
			bufferCopyApi.addLast(command)
		end
	end

	local function displayBuffer()
		local bufferLines = bufferCopy
		DisplayApi.createSquare(keyCords["list"], colors.gray)
		if bufferLines == nil then
			return nil
		end
		for i, line in ipairs(bufferLines) do
			DisplayApi.drawText(41, 2 + i, line, colors.white)
		end
	end

	local function readCommandButton()
		local completion = require("cc.completion")
		local commands = { "BL", "BR", "LU", "LD", "LF", "LB", "RU", "RD", "RF", "RB" }
		-- different array needed to autocompletion
		local resCommands = {}
		for i, v in ipairs(commands) do
			table.insert(resCommands, v:upper())
			table.insert(resCommands, v:lower())
		end

		DisplayApi.createSquare(keyCords["inputButton"], colors.orange)
		DisplayApi.drawText(21, 2, ">")
		local command = read(nil, nil, function(text)
			return completion.choice(text, resCommands)
		end)
		if command ~= "" and command ~= nil then
			if BasicApi.findInTableFirst(resCommands, command) then
				-- here we add command to buffer, without lower register
				bufferCopyApi.addLast(command:upper())
			end
		end
		DisplayApi.createSquare(keyCords["inputButton"], colors.orange)
		DisplayApi.drawText(21, 2, "Write command")
	end

	local function reCalibrateLegs()
		parallel.waitForAny(function()
			GeneralApi.rewriteFileWithDataTable("legsConfig", nil)
			LegsApi.findLegs()
		end, function()
			DisplayApi.simpleLoader("Calibrating...", 0, 0, true)
		end)
	end

	local function handleEvents(event, param1, param2, param3)
		if movingSomething == true then
			return
		end
		if event == "key" then
			if param1 == keys.w then
				DisplayApi.pressButton(keyCords["w"], keyText["W"], "W")
				unpackMovementPresets(LegsApi.movementPresets("forward"))
			elseif param1 == keys.a then
				DisplayApi.pressButton(keyCords["a"], keyText["A"], "A")
			elseif param1 == keys.s then
				DisplayApi.pressButton(keyCords["s"], keyText["S"], "S")
				unpackMovementPresets(LegsApi.movementPresets("backward"))
			elseif param1 == keys.d then
				DisplayApi.pressButton(keyCords["d"], keyText["D"], "D")
			elseif param1 == keys.up then
				DisplayApi.pressButton(keyCords["up"], keyText["Up"], "Up")
				unpackMovementPresets(LegsApi.movementPresets("up"))
			elseif param1 == keys.down then
				DisplayApi.pressButton(keyCords["down"], keyText["Down"], "Down")
				unpackMovementPresets(LegsApi.movementPresets("down"))
			elseif param1 == keys.enter then
				DisplayApi.pressButton(keyCords["apply"], keyText["Apply"], "Apply")
				return "Apply"
				-- bufferCopyApi.apply()
			elseif param1 == keys.backspace then
				DisplayApi.pressButton(keyCords["back"], keyText["Back"], "Back")
				return "To main"
			elseif param1 == keys.delete then
				DisplayApi.pressButton(keyCords["removeLast"], keyText["Remove last"], "Remove last")
				bufferCopyApi.removeLast()
			end
			displayBuffer()
		end

		if event == "mouse_click" then
			if DisplayApi.MouseEventInsideSquare(param2, param3, keyCords["w"]) then
				DisplayApi.pressButton(keyCords["w"], keyText["W"], "W")
				unpackMovementPresets(LegsApi.movementPresets("forward"))
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyCords["a"]) then
				DisplayApi.pressButton(keyCords["a"], keyText["A"], "A")
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyCords["d"]) then
				DisplayApi.pressButton(keyCords["d"], keyText["D"], "D")
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyCords["s"]) then
				DisplayApi.pressButton(keyCords["s"], keyText["S"], "S")
				unpackMovementPresets(LegsApi.movementPresets("backward"))
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyCords["up"]) then
				DisplayApi.pressButton(keyCords["up"], keyText["Up"], "Up")
				unpackMovementPresets(LegsApi.movementPresets("up"))
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyCords["down"]) then
				DisplayApi.pressButton(keyCords["down"], keyText["Down"], "Down")
				unpackMovementPresets(LegsApi.movementPresets("down"))
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyCords["apply"]) then
				DisplayApi.pressButton(keyCords["apply"], keyText["Apply"], "Apply")
				return "Apply"
				-- bufferCopyApi.apply()
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyCords["back"]) then
				DisplayApi.pressButton(keyCords["back"], keyText["Back"], "Back")
				return DisplayApi.mainMenu()
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyCords["removeLast"]) then
				DisplayApi.pressButton(keyCords["removeLast"], keyText["Remove last"], "Remove last")
				bufferCopyApi.removeLast()
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyCords["inputButton"]) then
				DisplayApi.pressButton(keyCords["inputButton"], keyText["Write command"], "Write command")
				readCommandButton()
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyCords["calibrateButton"]) then
				DisplayApi.pressButton(keyCords["calibrateButton"], keyText["Legs Calibr."], "Legs Calibr.")
				reCalibrateLegs()
				return "Refresh"
			end
			displayBuffer()
		end
	end

	--do things
	createButtons()
	displayBuffer()

	while true do
		local event, param1, param2, param3 = os.pullEvent()
		local res = handleEvents(event, param1, param2, param3)
		if res == "To main" then
			return DisplayApi.mainMenu()
		elseif res == "Refresh" then
			return DisplayApi.moveMenu()
		elseif res == "Apply" then
			DisplayApi.simpleLoader("Moving...")
			LegsApi.RewriteBuffer(bufferCopy)
			LegsApi.doWithMovementBuffer()
			movingSomething = true
			return DisplayApi.moveMenu()
		end
	end
end

DisplayApi.storageMenu = function(storageState)
	DisplayApi.stylishClear()
	DisplayApi.simpleLoader("Loading...")
	term.setCursorPos(1, 1)

	local sd = storageState or StorageApi.start()
	local itemsList, storageSize, itemsSum, itemsSumLimit, maxPercentageUsage =
			StorageApi.dropMoreThanFilter(sd.list), sd.storageSize, sd.itemsSum, sd.itemsSumLimit, sd.maxPercentageUsage

	local temp1, temp2

	local filteredItemList = StorageApi.filterItemList(itemsList)

	local screenW, screenH = term.getSize()
	local ScreenW_MiDDLE_POINT = BasicApi.round(screenW / 2)

	local keyButtonCords = {}
	local keyTextCords = {}

	local itemListCurrentPage = 1
	local itemListMaxPage = math.ceil(#filteredItemList > 0 and #filteredItemList / 5 or 1)

	local bageSelectedByKey = 0

	local ibStart = 9
	local ibOffset = 2
	local itemBageOffsets = {
		ibStart + ibOffset * 1,
		ibStart + ibOffset * 2,
		ibStart + ibOffset * 3,
		ibStart + ibOffset * 4,
		ibStart + ibOffset * 5,
	}

	local function createBaseGrapics()
		term.setTextColor(colors.orange)
		term.setBackgroundColor(colors.brown)

		local slotsStr = BasicApi.getRealLength(itemsList) .. "/" .. storageSize
		local countStr = itemsSum .. "/" .. itemsSumLimit

		temp1, temp2 = DisplayApi.drawText(ScreenW_MiDDLE_POINT - screenW / 4 - #"Slots" + 2, 1, "Slots")
		keyTextCords[temp2] = temp1
		temp1, temp2 = DisplayApi.drawText(ScreenW_MiDDLE_POINT + screenW / 4, 1, "Count")
		keyTextCords[temp2] = temp1

		temp1, temp2 = DisplayApi.drawText(1, 2, slotsStr)
		temp1, temp2 = DisplayApi.drawText(screenW - #countStr + 1, 2, countStr)

		-- write percentage bar and percent in center
		local maxPercentageUsageRound = math.floor(maxPercentageUsage)
		local maxValueForProgressbar = math.floor(screenW / 100 * maxPercentageUsageRound)
		maxValueForProgressbar = maxValueForProgressbar < 2 and 2 or maxValueForProgressbar

		-- draw progress bar
		DisplayApi.createSquare({ 1, 6, maxValueForProgressbar, 6 }, colors.orange)
		local percentageStr = maxPercentageUsageRound .. "%"
		DisplayApi.drawText(
			DisplayApi.getCenterStrokeCord(percentageStr, "w", { maxValueForProgressbar + 1, 1 }),
			6,
			percentageStr,
			colors.black,
			colors.orange
		)
	end

	local function drawButtons()
		if bageSelectedByKey == -2 then
			keyButtonCords["refreshBtn"] =
					DisplayApi.createSquare({ ScreenW_MiDDLE_POINT - 4, 1, ScreenW_MiDDLE_POINT + 4, 1 }, colors.orange)
			temp1, temp2 =
					DisplayApi.drawText(ScreenW_MiDDLE_POINT - 3, 1, "refresh", colors.black, colors.orange, "refreshBtn")
			keyTextCords[temp2] = temp1
		else
			keyButtonCords["refreshBtn"] =
					DisplayApi.createSquare({ ScreenW_MiDDLE_POINT - 4, 1, ScreenW_MiDDLE_POINT + 4, 1 }, colors.brown)
			temp1, temp2 =
					DisplayApi.drawText(ScreenW_MiDDLE_POINT - 3, 1, "refresh", colors.orange, colors.brown, "refreshBtn")
			keyTextCords[temp2] = temp1
		end

		local compactBtnTextXCord = ScreenW_MiDDLE_POINT - screenW / 4 - #"compact" / 2
		if bageSelectedByKey == -1 then
			keyButtonCords["compactBtn"] = DisplayApi.createSquare({
				compactBtnTextXCord - 1,
				3,
				ScreenW_MiDDLE_POINT - screenW / 4 + #"compact" / 2,
				3,
			}, colors.orange)
			temp1, temp2 = DisplayApi.drawText(compactBtnTextXCord, 3, "compact", colors.black, colors.orange, "compactBtn")
			keyTextCords[temp2] = temp1
		else
			keyButtonCords["compactBtn"] = DisplayApi.createSquare({
				compactBtnTextXCord - 1,
				3,
				ScreenW_MiDDLE_POINT - screenW / 4 + #"compact" / 2,
				3,
			}, colors.brown)
			temp1, temp2 = DisplayApi.drawText(compactBtnTextXCord, 3, "compact", colors.orange, colors.brown, "compactBtn")
			keyTextCords[temp2] = temp1
		end

		if bageSelectedByKey == -3 then
			local filterBtnTextCord = ScreenW_MiDDLE_POINT + screenW / 4
			keyButtonCords["filterBtn"] =
					DisplayApi.createSquare({ filterBtnTextCord, 3, filterBtnTextCord + #"filter" + 1, 3 }, colors.orange)
			temp1, temp2 = DisplayApi.drawText(filterBtnTextCord + 1, 3, "filter", colors.black, colors.orange, "filterBtn")
			keyTextCords[temp2] = temp1
		else
			local filterBtnTextCord = ScreenW_MiDDLE_POINT + screenW / 4
			keyButtonCords["filterBtn"] =
					DisplayApi.createSquare({ filterBtnTextCord, 3, filterBtnTextCord + #"filter" + 1, 3 }, colors.brown)
			temp1, temp2 = DisplayApi.drawText(filterBtnTextCord + 1, 3, "filter", colors.orange, colors.brown, "filterBtn")
			keyTextCords[temp2] = temp1
		end
	end

	local function drawItemList()
		local function createItemBage(y, name, count, index)
			if name == nil or count == nil then
				return
			end
			if index ~= bageSelectedByKey then
				term.setTextColor(colors.orange)
				term.setBackgroundColor(colors.brown)
			else
				term.setTextColor(colors.black)
				term.setBackgroundColor(colors.orange)
				DisplayApi.createSquare({ 0, y - 1, screenW, y }, colors.orange)
			end

			DisplayApi.drawText(1, y, name)
			DisplayApi.drawText(screenW - 4 - #tostring(count), y, count)
			-- here we write string.code(25)
			DisplayApi.drawText(screenW - 3, y, string.char(25))
			DisplayApi.drawText(screenW - 1, y, "X", colors.red)
		end

		-- draw menu items in list
		term.setTextColor(colors.orange)
		DisplayApi.createSquare({ 0, 10, screenW, screenH }, colors.brown)
		local pageString = "page " .. itemListCurrentPage .. "/" .. itemListMaxPage
		DisplayApi.drawText(screenW - #pageString + 1, 9, pageString, colors.orange, colors.brown)

		local unloadTextStart = screenW - #pageString - 1 - #"Unload"
		if bageSelectedByKey == -4 then
			keyButtonCords["unloadBtn"] = DisplayApi.createSquare({ unloadTextStart - 1, 9, unloadTextStart + #"unload", 9 },
				colors.orange)
			keyTextCords["unload"] = DisplayApi.drawText(unloadTextStart, 9, "unload", colors.black, colors.orange)
		else
			keyButtonCords["unloadBtn"] = DisplayApi.createSquare({ unloadTextStart - 1, 9, unloadTextStart + #"unload", 9 },
				colors.brown)
			keyTextCords["unload"] = DisplayApi.drawText(unloadTextStart, 9, "unload", colors.orange, colors.brown)
		end


		if bageSelectedByKey == 0 then
			keyButtonCords["backBtn"] = DisplayApi.createSquare({ 0, 8, #"Back" + 1, 9 }, colors.orange)
			keyTextCords["back"] = DisplayApi.drawText(1, 9, "Back", colors.black)
		else
			keyButtonCords["backBtn"] = DisplayApi.createSquare({ 0, 8, #"Back" + 1, 9 }, colors.brown)
			keyTextCords["back"] = DisplayApi.drawText(1, 9, "Back", colors.orange)
		end

		-- 5 items for one page
		local startIndex
		if itemListCurrentPage - 1 < 1 then
			startIndex = 1
		else
			startIndex = ((itemListCurrentPage - 1) * 5) + 1
		end

		-- limit selected bage with max bages on page
		local bagesOnCurrentPage = 0
		for pageIterator = startIndex, itemListCurrentPage * 5 do
			if filteredItemList[pageIterator] ~= nil then
				bagesOnCurrentPage = bagesOnCurrentPage + 1
			end
		end
		bageSelectedByKey = bageSelectedByKey > bagesOnCurrentPage and bagesOnCurrentPage or bageSelectedByKey

		local offsetCounter = 1
		for pageIterator = startIndex, itemListCurrentPage * 5 do
			if filteredItemList[pageIterator] ~= nil then
				createItemBage(
					itemBageOffsets[offsetCounter],
					filteredItemList[pageIterator]["name"],
					filteredItemList[pageIterator]["count"],
					offsetCounter
				)
				bagesOnCurrentPage = bagesOnCurrentPage + 1
			end
			offsetCounter = offsetCounter + 1 > 5 and 1 or offsetCounter + 1
		end
	end

	local function findDelClickItem(x, y)
		for i = 1, #itemBageOffsets do
			local searchRes = DisplayApi.MouseEventInsideSquare(
				x,
				y,
				{ screenW - 2, itemBageOffsets[i], screenW - 1, itemBageOffsets[i] }
			)
			if searchRes == true then
				return i
			end
		end
	end

	local function findDropClickItem(x, y)
		for i = 1, #itemBageOffsets do
			local searchRes = DisplayApi.MouseEventInsideSquare(
				x,
				y,
				{ screenW - 4, itemBageOffsets[i], screenW - 3, itemBageOffsets[i] }
			)
			if searchRes == true then
				return i
			end
		end
	end

	local function handleEvents(event, param1, param2, param3)
		if event == "mouse_click" then
			-- handle back button
			if DisplayApi.MouseEventInsideSquare(param2, param3, keyButtonCords["backBtn"]) then
				DisplayApi.pressButton(keyButtonCords["backBtn"], keyTextCords["back"], "Back")
				return "To main"
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyButtonCords["refreshBtn"]) then
				DisplayApi.pressButton(keyButtonCords["refreshBtn"], keyTextCords["refreshBtn"], "refresh")
				return "Refresh"
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyButtonCords["compactBtn"]) then
				DisplayApi.pressButton(keyButtonCords["compactBtn"], keyTextCords["compactBtn"], "compact")
				DisplayApi.simpleLoader("Compacting...")
				sd = StorageApi.updateDataWithoutSearch(StorageApi.defragment(itemsList))
				return "Refresh without search"
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyButtonCords["filterBtn"]) then
				DisplayApi.pressButton(keyButtonCords["filterBtn"], keyTextCords["filterBtn"], "filter")
				return "Open filter"
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, keyButtonCords["unloadBtn"]) then
				DisplayApi.pressButton(keyButtonCords["unloadBtn"], keyTextCords["unload"], "unload")
				return "Open all unload confirm modal"
			end
			-- handle bage remove button
			local deleteItemIndex = findDelClickItem(param2, param3)
			if deleteItemIndex then
				local currentItem = filteredItemList[(itemListCurrentPage - 1) * 5 + deleteItemIndex]
				return "Open delete Modal", currentItem
			end
			local dropItemIndex = findDropClickItem(param2, param3)
			if dropItemIndex then
				local currentItem = filteredItemList[(itemListCurrentPage - 1) * 5 + dropItemIndex]
				return "Open unload modal", currentItem
			end
			drawButtons()
			drawItemList()
		end
		-- handle scroll list
		if event == "mouse_scroll" then
			itemListCurrentPage = itemListCurrentPage + param1
			itemListCurrentPage = itemListCurrentPage < 1 and 1 or itemListCurrentPage
			itemListCurrentPage = itemListCurrentPage > itemListMaxPage and itemListMaxPage or itemListCurrentPage
			drawButtons()
			drawItemList()
		end
		-- handle scroll list by keys
		if event == "key" then
			if param1 == keys.d or param1 == keys.right then
				itemListCurrentPage = itemListCurrentPage + 1
				itemListCurrentPage = itemListCurrentPage < 1 and 1 or itemListCurrentPage
				itemListCurrentPage = itemListCurrentPage > itemListMaxPage and itemListMaxPage or itemListCurrentPage
			elseif param1 == keys.a or param1 == keys.left then
				itemListCurrentPage = itemListCurrentPage - 1
				itemListCurrentPage = itemListCurrentPage < 1 and 1 or itemListCurrentPage
				itemListCurrentPage = itemListCurrentPage > itemListMaxPage and itemListMaxPage or itemListCurrentPage
			elseif param1 == keys.w or param1 == keys.up then
				bageSelectedByKey = bageSelectedByKey - 1 < -4 and -4 or bageSelectedByKey - 1
			elseif param1 == keys.s or param1 == keys.down then
				bageSelectedByKey = bageSelectedByKey + 1 > 5 and 5 or bageSelectedByKey + 1
			elseif param1 == keys.backspace then
				DisplayApi.pressButton(keyButtonCords["backBtn"], keyTextCords["back"], "Back")
				return "To main"
			elseif param1 == keys.r then
				DisplayApi.pressButton(keyButtonCords["refreshBtn"], keyTextCords["refreshBtn"], "refresh")
				return "Refresh"
			elseif param1 == keys.delete and bageSelectedByKey > 0 then
				local currentIndex = (itemListCurrentPage - 1) * 5 + bageSelectedByKey
				local currentItem = filteredItemList[currentIndex]
				return "Open delete Modal", currentItem
			elseif param1 == keys.c then
				DisplayApi.pressButton(keyButtonCords["compactBtn"], keyTextCords["compactBtn"], "compact")
				DisplayApi.simpleLoader("Compacting...")
				sd = StorageApi.updateDataWithoutSearch(StorageApi.defragment(itemsList))
				return "Refresh without search"
			elseif param1 == keys.f then
				DisplayApi.pressButton(keyButtonCords["filterBtn"], keyTextCords["filterBtn"], "filter")
				return "Open filter"
			elseif param1 == keys.enter then
				if bageSelectedByKey > 0 then
					local currentIndex = (itemListCurrentPage - 1) * 5 + bageSelectedByKey
					local currentItem = filteredItemList[currentIndex]
					return "Open unload modal", currentItem
				elseif bageSelectedByKey == 0 then
					DisplayApi.pressButton(keyButtonCords["backBtn"], keyTextCords["back"], "Back")
					return "To main"
				elseif bageSelectedByKey == -1 then
					DisplayApi.pressButton(keyButtonCords["compactBtn"], keyTextCords["compactBtn"], "compact")
					DisplayApi.simpleLoader("Compacting...")
					sd = StorageApi.updateDataWithoutSearch(StorageApi.defragment(itemsList))
					return "Refresh without search"
				elseif bageSelectedByKey == -2 then
					DisplayApi.pressButton(keyButtonCords["refreshBtn"], keyTextCords["refreshBtn"], "refresh")
					return "Refresh"
				elseif bageSelectedByKey == -3 then
					DisplayApi.pressButton(keyButtonCords["filterBtn"], keyTextCords["filterBtn"], "filter")
					return "Open filter"
				elseif bageSelectedByKey == -4 then
					DisplayApi.pressButton(keyButtonCords["unloadBtn"], keyTextCords["unload"], "unload")
					return "Open all unload confirm modal"
				end
			end
			drawButtons()
			drawItemList()
		end
	end

	local function onUnloadModalConfirm()
		DisplayApi.simpleLoader("Unloading...")
		if StorageApi.dropChuteStorage==nil then return DisplayApi.storageMenu(sd) end
		term.setCursorPos(1,1)
		for k, v in pairs(itemsList) do
			if v then
				local currentDropValue = v.count
				local dropResAcc = 0
				while dropResAcc < currentDropValue do
					dropResAcc = dropResAcc + StorageApi.storage.pushItems(StorageApi.dropChuteName, k, currentDropValue)
				end
			end
		end
		return DisplayApi.storageMenu()
	end

	local function onUnloadModalDeny()
		return DisplayApi.storageMenu(sd)
	end

	-- do things
	DisplayApi.stylishClear()
	createBaseGrapics()
	drawButtons()
	drawItemList()

	while true do
		local event, param1, param2, param3 = os.pullEvent()
		local handleRes, handlePar1 = handleEvents(event, param1, param2, param3)
		if handleRes == "To main" then
			return DisplayApi.mainMenu()
		elseif handleRes == "Open delete Modal" then
			return DisplayApi.modalDropMenu(handlePar1)
		elseif handleRes == "Open unload modal" then
			return DisplayApi.modalDropMenu(handlePar1, "unload")
		elseif handleRes == "Open all unload confirm modal" then
			return DisplayApi.confirmModal("Are you sure you want to unload inventory?", onUnloadModalConfirm, onUnloadModalDeny)
		elseif handleRes == "Open filter" then
			return DisplayApi.filterMenu()
		elseif handleRes == "Refresh" then
			return DisplayApi.storageMenu()
		elseif handleRes == "Refresh with smart search" then
			return DisplayApi.storageMenu(sd)
		elseif handleRes == "Refresh without search" then
			return DisplayApi.storageMenu(sd)
		end
	end
end

DisplayApi.filterMenu = function()
	DisplayApi.stylishClear()

	local sd = StorageApi.currentData
	local itemsList = sd.list

	local filterState = GeneralApi.readFileAsDataTable("storageFilter")
	local filterAsList = (function()
		if filterState == nil then return nil end
		local res = {}
		for key, value in pairs(filterState) do
			local filterItemName = value:match("([^=]+)=")
			local filterItemMaxCount = value:match("=([0-9]+)")
			res[key] = { name = filterItemName, maxCount = filterItemMaxCount }
		end
		return res
	end)()

	local keyButtonCords = {}
	local keyTextCords = {}

	local screenW, screenH = term.getSize()


	local itemListCurrentPage = 1
	local itemListMaxPage = math.ceil(filterState and #filterState / 5 or 1)
	local bageSelectedByKey = 0

	local ibStart = 9
	local ibOffset = 2
	local itemBageOffsets = {
		ibStart + ibOffset * 1,
		ibStart + ibOffset * 2,
		ibStart + ibOffset * 3,
		ibStart + ibOffset * 4,
		ibStart + ibOffset * 5,
	}

	local modalRes = {
		name = "",
		maxCount = nil,
	}


	local function findDelClickItem(x, y)
		for i = 1, #itemBageOffsets do
			local searchRes = DisplayApi.MouseEventInsideSquare(
				x,
				y,
				{ screenW - 2, itemBageOffsets[i], screenW - 1, itemBageOffsets[i] }
			)
			if searchRes == true then
				return i
			end
		end
	end


	local function createGrapics()
		if modalRes.name == "" then
			if bageSelectedByKey == -3 then
				keyButtonCords["selectNameBtn"] = DisplayApi.createSquare({ 10, 0, screenW - 10, 1 }, colors.orange)
				keyTextCords["selectName"] = DisplayApi.drawText(10 + #"Select name" - 1, 1, "Select name", colors.black,
					colors.orange)
			else
				keyButtonCords["selectNameBtn"] = DisplayApi.createSquare({ 10, 0, screenW - 10, 1 }, colors.brown)
				keyTextCords["selectName"] = DisplayApi.drawText(10 + #"Select name" - 1, 1, "Select name", colors.orange,
					colors.brown)
			end
		else
			local temp1 = DisplayApi.getCenterStrokeCord(modalRes.name)
			local textCordsA, textCordsB = unpack(keyTextCords["selectName"])
			if bageSelectedByKey == -3 then
				DisplayApi.createSquare(keyButtonCords["selectNameBtn"], colors.orange)
				DisplayApi.drawText(temp1, textCordsB, modalRes.name, colors.black, colors.orange)
			else
				DisplayApi.createSquare(keyButtonCords["selectNameBtn"], colors.brown)
				DisplayApi.drawText(temp1, textCordsB, modalRes.name, colors.orange, colors.brown)
			end
		end

		if modalRes.maxCount == nil then
			if bageSelectedByKey == -2 then
				keyButtonCords["selectMaxCountBtn"] = DisplayApi.createSquare({ 17, 3, screenW - 18, 4 }, colors.orange)
				keyTextCords["selectMaxCount"] =
						DisplayApi.drawText(10 + #"Limit count" - 1, 4, "Limit count", colors.black, colors.orange)
			else
				keyButtonCords["selectMaxCountBtn"] = DisplayApi.createSquare({ 17, 3, screenW - 18, 4 }, colors.brown)
				keyTextCords["selectMaxCount"] =
						DisplayApi.drawText(10 + #"Limit count" - 1, 4, "Limit count", colors.orange, colors.brown)
			end
		else
			local temp1 = DisplayApi.getCenterStrokeCord(tostring(modalRes.maxCount))
			local textCordsA, textCordsB = unpack(keyTextCords["selectMaxCount"])
			if bageSelectedByKey == -2 then
				DisplayApi.createSquare(keyButtonCords["selectMaxCountBtn"], colors.orange)
				DisplayApi.drawText(temp1, textCordsB, modalRes.maxCount, colors.black, colors.orange)
			else
				DisplayApi.createSquare(keyButtonCords["selectMaxCountBtn"], colors.brown)
				DisplayApi.drawText(temp1, textCordsB, modalRes.maxCount, colors.orange, colors.brown)
			end
		end

		if bageSelectedByKey == -1 then
			keyButtonCords["ApplyBtn"] = DisplayApi.createSquare({ 22 - 1, 6, screenW - 22, 7 }, colors.orange)
			keyTextCords["ApplyText"] = DisplayApi.drawText(22 + 1, 7, "Apply", colors.black, colors.orange)
		else
			keyButtonCords["ApplyBtn"] = DisplayApi.createSquare({ 22 - 1, 6, screenW - 22, 7 }, colors.brown)
			keyTextCords["ApplyText"] = DisplayApi.drawText(22 + 1, 7, "Apply", colors.orange, colors.brown)
		end
	end

	local function drawFilterList()
		local function createItemBage(y, name, count, index)
			if name == nil or count == nil then
				return
			end
			if index ~= bageSelectedByKey then
				term.setTextColor(colors.orange)
				term.setBackgroundColor(colors.brown)
			else
				term.setTextColor(colors.black)
				term.setBackgroundColor(colors.orange)
				DisplayApi.createSquare({ 0, y - 1, screenW, y }, colors.orange)
			end
			DisplayApi.drawText(1, y, name)
			local maxCountString = "Max: " .. count
			DisplayApi.drawText(screenW - 1 - 1 - #maxCountString, y, maxCountString)
			DisplayApi.drawText(screenW - 1, y, "X", colors.red)
		end

		-- if filterState == nil then
		-- 	bageSelectedByKey = 0
		-- end

		-- draw menu items in list
		DisplayApi.createSquare({ 0, 10, screenW, screenH }, colors.brown)

		local pageString = "page " .. itemListCurrentPage .. "/" .. itemListMaxPage
		DisplayApi.drawText(screenW - #pageString + 1, 9, pageString, colors.orange, colors.brown)
		if bageSelectedByKey == 0 then
			keyButtonCords["backBtn"] = DisplayApi.createSquare({ 0, 8, #"Back" + 1, 9 }, colors.orange)
			keyTextCords["backBtn"] = DisplayApi.drawText(1, 9, "Back", colors.black)
		else
			keyButtonCords["backBtn"] = DisplayApi.createSquare({ 0, 8, #"Back" + 1, 9 }, colors.brown)
			keyTextCords["backBtn"] = DisplayApi.drawText(1, 9, "Back", colors.orange)
		end

		if filterState == nil or filterAsList == nil then
			return
		end

		-- 5 items for one page
		local startIndex
		if itemListCurrentPage - 1 < 1 then
			startIndex = 1
		else
			startIndex = ((itemListCurrentPage - 1) * 5) + 1
		end

		-- limit selected bage with max bages on page
		local bagesOnCurrentPage = 0
		for pageIterator = startIndex, itemListCurrentPage * 5 do
			if filterState[pageIterator] ~= nil then
				bagesOnCurrentPage = bagesOnCurrentPage + 1
			end
		end
		bageSelectedByKey = bageSelectedByKey > bagesOnCurrentPage and bagesOnCurrentPage or bageSelectedByKey

		local offsetCounter = 1
		for pageIterator = startIndex, itemListCurrentPage * 5 do
			if filterState[pageIterator] ~= nil then
				-- local filterItemName = filterState[pageIterator]:match("([^=]+)=")
				-- local filterItemMaxCount = filterState[pageIterator]:match("=([0-9]+)")
				-- filterItemName,
				-- filterItemMaxCount,

				createItemBage(
					itemBageOffsets[offsetCounter],
					filterAsList[pageIterator]["name"],
					filterAsList[pageIterator]["maxCount"],
					offsetCounter
				)
				bagesOnCurrentPage = bagesOnCurrentPage + 1
			end
			offsetCounter = offsetCounter + 1 > 5 and 1 or offsetCounter + 1
		end
	end

	local function onApplyClick()
		if modalRes.name == "" or modalRes.maxCount == nil then return end
		local res = modalRes.name .. "=" .. modalRes.maxCount .. '\n'
		local fileData = GeneralApi.readFileAsDataTable("storageFilter")
		if fileData then
			local hasSameKey = false
			for k, v in pairs(fileData) do
				if v:find(modalRes.name) then
					fileData[k] = res
					hasSameKey = true
					break
				end
			end
			if hasSameKey then
				GeneralApi.rewriteFileWithDataTable("storageFilter", fileData)
				modalRes.name = ""
				modalRes.maxCount = nil
				return
			end
		end

		local file = fs.open("storageFilter", fileData and "a" or "w")
		file.write(res)
		file.close()
		modalRes.name = ""
		modalRes.maxCount = nil
	end

	local function deleteItemFromFilter(currentItem)
		if currentItem == nil then return end
		local fileData = GeneralApi.readFileAsDataTable("storageFilter")
		if fileData == nil then return end
		for k, v in pairs(fileData) do
			if v:find(currentItem["name"]) then
				fileData[k] = nil
				break
			end
		end
		GeneralApi.rewriteFileWithDataTable("storageFilter", fileData)
	end

	local function onSelectNameClick()
		modalRes.name = ""
		local completion = require("cc.completion")
		local commands = (function()
			local res = {}
			for key, value in pairs(itemsList) do
				if value ~= nil and value["name"] then
					local filteredName = value["name"]:match(":([^:]*)$")
					if filteredName then
						table.insert(res, filteredName)
					else
						table.insert(res, value["name"])
					end
				end
			end
			return res
		end)()

		local function getItemUnfiltered(command)
			local commandRegEx = "[^_]" .. command .. "[^_]*$"
			for _, value in ipairs(itemsList) do
				if value["name"]:match(commandRegEx) then
					return value["name"]
				end
			end
			return nil
		end

		DisplayApi.pressButton(keyButtonCords["selectNameBtn"], keyTextCords["selectName"], " ")
		local textCordsA, textCordsB = unpack(keyTextCords["selectName"])
		DisplayApi.drawText(1, textCordsB, ">", colors.black, colors.orange)
		local command = read(nil, nil, function(text)
			return completion.choice(text, commands)
		end)
		DisplayApi.createSquare({ 0, textCordsB, screenW, textCordsB }, colors.brown)
		local UnfilteredCommand = getItemUnfiltered(command)
		if command ~= "" and command ~= nil and UnfilteredCommand then
			modalRes.name = UnfilteredCommand
		else
			modalRes.name = ""
		end
	end

	local function onSelectCountClick()
		modalRes.maxCount = nil
		local completion = require("cc.completion")
		local commands = { "0", "8192", "4096", "2048", "1024", "512", "256", "128", "64", "32", "16", "8", "4", "2", "1" }
		local textCordsA, textCordsB = unpack(keyTextCords["selectMaxCount"])
		DisplayApi.pressButton(keyButtonCords["selectMaxCountBtn"], keyTextCords["selectMaxCount"], " ")
		DisplayApi.drawText(textCordsA, textCordsB, ">", colors.black, colors.orange)
		local command = read(nil, nil, function(text)
			return completion.choice(text, commands)
		end)
		DisplayApi.createSquare({ 0, textCordsB, screenW, textCordsB }, colors.brown)
		if command ~= "" and command ~= nil and tonumber(command) then
			modalRes.maxCount = tonumber(command)
		else
			modalRes.maxCount = nil
		end
	end

	local function handleEvents(event, param1, param2, param3)
		if event == "mouse_click" then
			-- handle back button
			if DisplayApi.MouseEventInsideSquare(param2, param3, keyButtonCords["backBtn"]) then
				DisplayApi.pressButton(keyButtonCords["backBtn"], keyTextCords["backBtn"], "Back")
				return "Back"
			end
			if DisplayApi.MouseEventInsideSquare(param2, param3, keyButtonCords["selectNameBtn"]) then
				DisplayApi.pressButton(keyButtonCords["selectNameBtn"], keyTextCords["selectName"], "Select name")
				onSelectNameClick()
			end
			if DisplayApi.MouseEventInsideSquare(param2, param3, keyButtonCords["selectMaxCountBtn"]) then
				DisplayApi.pressButton(
					keyButtonCords["selectMaxCountBtn"],
					keyTextCords["selectMaxCount"],
					"Limit count"
				)
				onSelectCountClick()
			end
			if DisplayApi.MouseEventInsideSquare(param2, param3, keyButtonCords["ApplyBtn"]) then
				DisplayApi.pressButton(keyButtonCords["ApplyBtn"], keyTextCords["ApplyText"], "Apply")
				onApplyClick()
				return "Refresh"
			end
			local deleteItemIndex = findDelClickItem(param2, param3)
			if deleteItemIndex and filterAsList ~= nil then
				local currentIndex = (itemListCurrentPage - 1) * 5 + deleteItemIndex
				local currentItem = filterAsList[currentIndex]
				deleteItemFromFilter(currentItem)
				return "Refresh"
			end
			createGrapics()
			drawFilterList()
		end
		if event == "mouse_scroll" then
			itemListCurrentPage = itemListCurrentPage + param1
			itemListCurrentPage = itemListCurrentPage < 1 and 1 or itemListCurrentPage
			itemListCurrentPage = itemListCurrentPage > itemListMaxPage and itemListMaxPage or itemListCurrentPage
			drawFilterList()
		end
		if event == "key" then
			if param1 == keys.d or param1 == keys.right then
				itemListCurrentPage = itemListCurrentPage + 1
				itemListCurrentPage = itemListCurrentPage < 1 and 1 or itemListCurrentPage
				itemListCurrentPage = itemListCurrentPage > itemListMaxPage and itemListMaxPage or itemListCurrentPage
			elseif param1 == keys.a or param1 == keys.left then
				itemListCurrentPage = itemListCurrentPage - 1
				itemListCurrentPage = itemListCurrentPage < 1 and 1 or itemListCurrentPage
				itemListCurrentPage = itemListCurrentPage > itemListMaxPage and itemListMaxPage or itemListCurrentPage
			elseif param1 == keys.w or param1 == keys.up then
				bageSelectedByKey = bageSelectedByKey - 1 < -3 and -3 or bageSelectedByKey - 1
			elseif param1 == keys.s or param1 == keys.down then
				bageSelectedByKey = bageSelectedByKey + 1 > 5 and 5 or bageSelectedByKey + 1
			elseif param1 == keys.backspace then
				DisplayApi.pressButton(keyButtonCords["backBtn"], keyTextCords["backBtn"], "Back")
				return "Back"
			end
			if param1 == keys.enter then
				if bageSelectedByKey > 0 and bageSelectedByKey < 5 and filterAsList ~= nil then
					local currentIndex = (itemListCurrentPage - 1) * 5 + bageSelectedByKey
					local currentItem = filterAsList[currentIndex]
					modalRes.name = currentItem["name"]
					modalRes.maxCount = currentItem["maxCount"]
				end
				if bageSelectedByKey == 0 then
					DisplayApi.pressButton(keyButtonCords["backBtn"], keyTextCords["backBtn"], "Back")
					return "Back"
				elseif bageSelectedByKey == -3 then
					DisplayApi.pressButton(keyButtonCords["selectNameBtn"], keyTextCords["selectName"], "Select name")
					onSelectNameClick()
				elseif bageSelectedByKey == -2 then
					DisplayApi.pressButton(
						keyButtonCords["selectMaxCountBtn"],
						keyTextCords["selectMaxCount"],
						"Limit count"
					)
					onSelectCountClick()
				elseif bageSelectedByKey == -1 then
					DisplayApi.pressButton(keyButtonCords["ApplyBtn"], keyTextCords["ApplyText"], "Apply")
					onApplyClick()
					return "Refresh"
				end
			end
			if param1 == keys.delete then
				if bageSelectedByKey > 0 and bageSelectedByKey < 5 and filterAsList ~= nil then
					local currentIndex = (itemListCurrentPage - 1) * 5 + bageSelectedByKey
					local currentItem = filterAsList[currentIndex]
					deleteItemFromFilter(currentItem)
					return "Refresh"
				end
			end
			createGrapics()
			drawFilterList()
		end
	end

	createGrapics()
	drawFilterList()
	while true do
		local event, param1, param2, param3 = os.pullEvent()
		local handleRes, handlePar1 = handleEvents(event, param1, param2, param3)
		if handleRes == "Back" then
			return DisplayApi.storageMenu(sd)
		elseif handleRes == "Refresh" then
			return DisplayApi.filterMenu()
		end
	end
end

DisplayApi.modalDropMenu = function(currentItem, mode)
	mode = mode or "delete"
	if currentItem == nil then
		return DisplayApi.mainMenu()
	end

	local dropValueDefText = "Enter ".. mode.. " value"
	local loaderText = mode=="delete" and "Deleting..." or "Unloading..."

	local sd = StorageApi.currentData
	local itemsList = sd.list

	local deleteModal = {
		isOpen = false,
		name = "",
		count = 0,
		dropValue = 0,
		buttonText = "",
	}

	local keyButtonCords = {}
	local keyTextCords = {}

	local function openModal()
		deleteModal.isOpen = true
		DisplayApi.stylishClear()

		local tempCords, tempName
		keyButtonCords["modal"] = DisplayApi.createSquare({ 10, 5, 41, 13 }, colors.gray)
		tempCords, tempName = DisplayApi.drawText(41 + 1, 5 - 1, "X", colors.red, colors.brown, "closeButton")
		keyTextCords[tempName] = tempCords

		term.setTextColor(colors.orange)
		term.setBackgroundColor(colors.gray)
		-- write name
		tempCords, tempName = DisplayApi.drawText(10 + 1, 5 + 1, currentItem["name"], nil, nil, "name")
		keyTextCords[tempName] = tempCords
		-- write count
		local countStr = "count " .. currentItem["count"]
		tempCords, tempName = DisplayApi.drawText(41 - 1 - #countStr, 5 + 3, countStr, nil, nil, "count")
		keyTextCords[tempName] = tempCords
		-- write drop
		keyButtonCords["dropValue"] = DisplayApi.createSquare({ 15 + 1, 5 + 5, 36 - 1, 12 }, colors.orange)
		keyTextCords["dropValue"] = DisplayApi.drawText(15 + 2, 11, dropValueDefText, colors.black, nil)
		-- write apply
		keyButtonCords["apply"] = DisplayApi.createSquare({ 15 + 3, 15, 36 - 3, 17 }, colors.orange)
		keyTextCords["apply"] = DisplayApi.drawText(15 + 3 + #"Apply", 16, "Apply")

		deleteModal = {
			isOpen = true,
			name = currentItem["name"],
			count = currentItem["count"],
			dropValue = 0,
			buttonText = dropValueDefText,
			dropRightNow = false,
		}
	end

	local function closeModal()
		deleteModal = {
			isOpen = false,
		}
		DisplayApi.stylishClear()
	end

	local function onDeleteModalDropButtonClick()
		local completion = require("cc.completion")
		local modalCount = deleteModal.count
		local halfOfCount = tostring(BasicApi.round(modalCount / 2))
		local quarterOfCount = tostring(BasicApi.round(modalCount / 4))
		local commands = { "0", tostring(modalCount), halfOfCount, quarterOfCount }
		DisplayApi.pressButton(keyButtonCords["dropValue"], keyTextCords["dropValue"], " ")
		local textCordA, textCordB = unpack(keyTextCords["dropValue"])
		-- term.setCursorPos(textCordA, textCordB)

		DisplayApi.drawText(textCordA, textCordB, ">", colors.black)

		local command = read(nil, nil, function(text)
			return completion.choice(text, commands)
		end)
		DisplayApi.createSquare(keyButtonCords["dropValue"], colors.orange)

		if command ~= "" and command ~= nil and tonumber(command) then
			DisplayApi.drawText(textCordA, textCordB, command, colors.black)
			if tonumber(command) >= modalCount then
				local temp1 = DisplayApi.getCenterStrokeCord(tostring(modalCount))
				DisplayApi.createSquare(keyButtonCords["dropValue"], colors.orange)
				DisplayApi.drawText(temp1, textCordB, modalCount, colors.black, colors.orange)
				deleteModal.buttonText = modalCount
				deleteModal.dropValue = modalCount
			else
				deleteModal.buttonText = tostring(tonumber(command))
				deleteModal.dropValue = tonumber(command)
			end
		else
			DisplayApi.createSquare(keyButtonCords["dropValue"], colors.orange)
			DisplayApi.drawText(textCordA, textCordB, dropValueDefText, colors.black)
			deleteModal.buttonText = dropValueDefText
		end
	end

	local function onDeleteModalApplyButtonClick()
		-- here we get modal item and count to drop then - find and drop it throu all list
		if deleteModal.dropValue == 0 then
			return closeModal()
		end
		local neededItemName = deleteModal.name
		local needToDropCount = 0

		if deleteModal.dropValue > deleteModal.count then
			needToDropCount = deleteModal.count
		else
			needToDropCount = deleteModal.dropValue
		end

		deleteModal.dropRightNow = true
		local textCordA, textCordB = unpack(keyTextCords["dropValue"])
		DisplayApi.createSquare(keyButtonCords["dropValue"], colors.orange)
		DisplayApi.drawText(textCordA, textCordB, loaderText, colors.black)
		deleteModal.buttonText = loaderText

		local nameStorageToPushItemsin = mode=="delete" and StorageApi.binName or StorageApi.dropChuteName

		local i = 1
		while needToDropCount > 0 and i <= StorageApi.size do
			local currentItem = itemsList[i]
			if currentItem ~= nil and currentItem["name"]:match(neededItemName) then
				local currentItemCount = currentItem["count"]
				local currentDropValue = 0
				if currentItemCount >= needToDropCount then
					-- drop part of item
					currentDropValue = needToDropCount
				else
					-- drop full item
					currentDropValue = currentItemCount
				end
				-- drop
				local dropResAcc = 0
				while dropResAcc < currentDropValue do
					dropResAcc = dropResAcc + StorageApi.storage.pushItems(nameStorageToPushItemsin, i, currentDropValue)
				end
				if currentItemCount - currentDropValue <= 0 then
					itemsList[i] = nil
				else
					itemsList[i]["count"] = itemsList[i]["count"] - currentDropValue
				end

				sd = StorageApi.updateDataWithoutSearch(itemsList)
				-- update drop counter
				needToDropCount = needToDropCount - currentDropValue
			end
			i = i + 1
		end
		deleteModal.dropRightNow = false
	end

	local enterCounter = 0

	local function handleEvents(event, param1, param2, param3)
		if deleteModal.dropRightNow == true then
			return
		end
		if event == "mouse_click" then
			if DisplayApi.MouseEventInsideSquare(param2, param3, keyButtonCords["apply"]) then
				DisplayApi.pressButton(keyButtonCords["apply"], keyTextCords["Apply"], "Apply")
				onDeleteModalApplyButtonClick()
				return "Close"
			end
			if DisplayApi.MouseEventInsideSquare(param2, param3, keyButtonCords["dropValue"]) then
				DisplayApi.pressButton(
					keyButtonCords["dropValue"],
					keyTextCords["dropValue"],
					deleteModal.buttonText or dropValueDefText
				)
				onDeleteModalDropButtonClick()
			end
			local a, b = unpack(keyTextCords["closeButton"])
			if DisplayApi.MouseEventInsideSquare(param2, param3, { a - 1, b - 1, a + 1, b + 1 }) then
				return "Close"
			end
		end
		if event == "key" then
			if param1 == keys.enter then
				-- just in case - check less than 3
				enterCounter = enterCounter + 1 > 3 and 3 or enterCounter + 1
				if enterCounter == 1 then
					DisplayApi.pressButton(
						keyButtonCords["dropValue"],
						keyTextCords["dropValue"],
						deleteModal.buttonText or dropValueDefText
					)
					onDeleteModalDropButtonClick()
				elseif enterCounter == 2 then
					if tonumber(deleteModal.dropValue) and deleteModal.dropValue>0 then
						DisplayApi.pressButton(keyButtonCords["apply"], keyTextCords["apply"], "Apply")
						onDeleteModalApplyButtonClick()
						return "Close"
					else
						enterCounter = 1
						DisplayApi.pressButton(
							keyButtonCords["dropValue"],
							keyTextCords["dropValue"],
							deleteModal.buttonText or dropValueDefText
						)
						onDeleteModalDropButtonClick()
					end
				end
			elseif param1 == keys.backspace then
				return "Close"
			end
		end
	end

	-- do things
	openModal()

	while true do
		local event, param1, param2, param3 = os.pullEvent()
		local handleRes = handleEvents(event, param1, param2, param3)
		if handleRes == "Close" then
			closeModal()
			return DisplayApi.storageMenu(sd)
		end
	end
end

DisplayApi.simpleLoader = function(text, textWOffset, textHOffset, endless, textColor, bgColor)
	textColor = textColor or colors.orange
	bgColor = bgColor or colors.brown
	textWOffset = textWOffset or 0
	textHOffset = textHOffset or 0

	DisplayApi.stylishClear(textColor, bgColor)
	local temp1, temp2
	temp1, temp2 = DisplayApi.getCenterStrokeCord(text)
	DisplayApi.drawText(temp1 + textWOffset, temp2 + textHOffset, text, textColor, bgColor)
	term.setCursorPos(0, 0)
	if endless then
		while true do
			os.sleep(1)
		end
	end
end

DisplayApi.confirmModal = function(text, acceptCallback, cancelCallback)
	DisplayApi.stylishClear()
	local centeredTX, centeredTY = DisplayApi.getCenterStrokeCord(text)
	DisplayApi.drawText(centeredTX, 5, text, colors.orange, colors.brown)

	local acceptBtn, acceptTextCords
	local denyBtn, denyTextCords

	local selectedBtn = 0

	local textH = 8

	local function drawButtons()
		denyBtn = DisplayApi.createSquare({ 30, textH, 30 + 1 + #"Deny", textH+1 }, colors.brown)
		denyTextCords = DisplayApi.drawText(30 + 1, textH+1, "Deny", colors.orange, colors.brown)
		acceptBtn = DisplayApi.createSquare({ 13, textH, 13 + 1 + #"Accept", textH+1 }, colors.brown)
		acceptTextCords = DisplayApi.drawText(13 + 1, textH+1, "Accept", colors.orange, colors.brown)

		if selectedBtn == 0 then
			denyBtn = DisplayApi.createSquare({ 30, textH, 30 + 1 + #"Deny", textH+1 }, colors.orange)
			denyTextCords = DisplayApi.drawText(30 + 1, textH+1, "Deny", colors.black, colors.orange)
		elseif selectedBtn == 1 then
			acceptBtn = DisplayApi.createSquare({ 13, textH, 13 + 1 + #"Accept", textH+1 }, colors.orange)
			acceptTextCords = DisplayApi.drawText(13 + 1, textH+1, "Accept", colors.black, colors.orange)
		end
	end

	drawButtons()
	while true do
		local event, param1, param2, param3 = os.pullEvent()
		if event=="mouse_click" then
			if DisplayApi.MouseEventInsideSquare(param2, param3, denyBtn) then
				DisplayApi.pressButton(denyBtn, denyTextCords, "Deny")
				return cancelCallback()
			elseif DisplayApi.MouseEventInsideSquare(param2, param3, acceptBtn) then
				DisplayApi.pressButton(denyBtn, denyTextCords, "Accept")
				return acceptCallback()
			end
		end
		if event == "key" then
			if param1 == keys.enter then
				if selectedBtn == 0 then
					DisplayApi.pressButton(denyBtn, denyTextCords, "Deny")
					return cancelCallback()
				elseif selectedBtn == 1 then
					DisplayApi.pressButton(acceptBtn, acceptTextCords, "Accept")
					return acceptCallback()
				end
			end
			if param1 == keys.left or param1 == keys.a then
				selectedBtn = 1
			elseif param1 == keys.right or param1 == keys.d then
				selectedBtn = 0
			end
			drawButtons()
		end
	end
end

-- todo make move commands pages


return DisplayApi
