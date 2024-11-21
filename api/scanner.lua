-- computercraft script for geoscranner from advanced peripherals

local function _sortResByLevel(res)
	local res_by_level = {}
	for _, block in pairs(res) do
		if res_by_level[block.y] == nil then
			res_by_level[block.y] = {}
		end
		table.insert(res_by_level[block.y], block)
	end
	return res_by_level
end

local Scanner = {}
Scanner.__index = Scanner

function Scanner:new(side, radius)
	if side == nil then
		side = "back"
	end
	if radius == nil then
		radius = 16
	end

	local obj = {}
	setmetatable(obj, self)
	obj.side = side
	obj.s = peripheral.wrap(side)
	obj.levels = {}
	obj.error = nil
	obj.radius = radius
	return obj
end

function Scanner:changeRadius(radius)
	self.radius = radius
end

function Scanner:scan(radius)
	if radius == nil then
		radius = self.radius
	end
	local res, err = self.s.scan(radius)
	self.error = err
	if res == nil then
		return
	end
	self.levels = _sortResByLevel(res)
end

return Scanner
