-- computercraft script for geoscranner from advanced peripherals
local scanner = peripheral.wrap("back")
local scanner_result = {}

-- screen size for pocket computer is 26x20

local function _draw_title()
	term.clear()
	local title = "X-Vision"
	term.setCursorPos((26 - #title) / 2, 1)
	term.write(title)
end

-- level 0 is same as player stands
local function _filter_blocks_by_level(level)
	local filtered = {}
	for _, block in pairs(scanner_result) do
		if block.y == level then
			table.insert(filtered, block)
		end
	end
	return filtered
end

local function _do_scan_thing()
	-- name: string 	The registry name of the block
	-- tags: table 	A list of block tags
	-- x: number 	The block's x coordinate
	-- y: number 	The block's y coordinate
	-- z: number 	The block's z coordinate
	local error_message = ""
	scanner_result, error_message = scanner.scan(16)
	if error_message then
		term.clear()
		term.setCursorPos(1, 1)
		print("Error: " .. error_message)
	end
	local filtered = _filter_blocks_by_level(0)
end

local function _wait_for_key()
	while true do
		local event, param1, param2, param3 = os.pullEvent()
		if event == "key" then
			if param1 == keys.backspace then
				return
			elseif param1 == keys.enter then
				_do_scan_thing()
			end
		end
	end
end

_draw_title()
_wait_for_key()

-- function WinCanvas:setPixel(x, y, active)
-- 	x = x - 1
-- 	y = y - 1
-- 	local charX = math.floor(x / 2)
-- 	local charY = math.floor(y / 3)
-- 	local pixelX = x - charX * 2
-- 	local pixelY = y - charY * 3
-- 	charX = charX + 1
-- 	charY = charY + 1
-- 	-- if out of bounds
-- 	if
-- 		charX <= 0
-- 		or charX > #self.symbols
-- 		or charY <= 0
-- 		or charY > #self.symbols[charX]
-- 		or pixelX < 0
-- 		or pixelX >= #self.symbols[charX][charY].pixel
-- 		or pixelY < 0
-- 		or pixelY >= #self.symbols[charX][charY].pixel[pixelX + 1]
-- 	then
-- 		return
-- 	end
--
-- 	self.symbols[charX][charY].pixel[pixelX + 1][pixelY + 1] = active
-- 	self.symbols[charX][charY]:update()
-- end
