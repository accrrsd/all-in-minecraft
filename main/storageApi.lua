BasicApi = require("basicApi")

local StorageApi = {
	storage = nil,
	name = "",
	size = 0,
	currentData = {},
	binName = "",
	binStorage = nil,
	dropChuteName=  "",
	dropChuteStorage = nil,
}

local function divideIntoSectors(number, sectors)
	local result = {}
	local sectorSize = math.ceil(number / sectors)
	local startNumber = 1
	local endNumber = 0

	for _ = 1, sectors do
		endNumber = math.min(startNumber + sectorSize - 1, number)
		if startNumber < endNumber then
			table.insert(result, { startNumber, endNumber })
		end
		startNumber = endNumber + 1
	end

	-- filter
	local seen = {}
	local uniqueResult = {}
	for _, pair in ipairs(result) do
		local key = pair[1] .. "-" .. pair[2]
		if not seen[key] then
			table.insert(uniqueResult, pair)
			seen[key] = true
		end
	end

	return uniqueResult
end

local function getAsyncInfoForRegion(startIndex, endIndex, list)
	for i = startIndex, endIndex do
		-- Check of rewrite + optimization
		if list[i] == nil then
			local itemInfo = StorageApi.storage.getItemDetail(i)
			if itemInfo then
				list[i] = itemInfo
			end
		end
	end
end

local function asyncFunctionsGenerator(regions, iList, functionToCall)
	local fList = {}
	for i = 1, #regions do
		fList[i] = function()
			functionToCall(regions[i][1], regions[i][2], iList)
		end
	end
	return fList
end

StorageApi.start = function()
	local bottomModem = peripheral.wrap("bottom")
	local namesFromBottom = bottomModem.getNamesRemote()

	local _, storageName = BasicApi.findInTableFirst(namesFromBottom, "minecraft:barrel")
	local storage = peripheral.wrap(storageName)

	local _, binName = BasicApi.findInTableFirst(namesFromBottom, "create:chute")
	local binStorage = peripheral.wrap(binName)

	local _, dropChuteName = BasicApi.findInTableFirst(namesFromBottom, "create:smart_chute")
	local dropChuteStorage = peripheral.wrap(dropChuteName)

	StorageApi.storage = storage
	StorageApi.name = storageName
	StorageApi.size = storage.size()

	StorageApi.binName = binName
	StorageApi.binStorage = binStorage

	StorageApi.dropChuteName = dropChuteName
	StorageApi.dropChuteStorage = dropChuteStorage

	return StorageApi.updateDataWithSearch()
end

StorageApi.updateDataWithSearch = function(asyncStreams)
	asyncStreams = asyncStreams or math.floor(StorageApi.size / 5)
	StorageApi.currentData = StorageApi.calculateData(StorageApi.getAllSlotsDetails(asyncStreams))
	return StorageApi.currentData
end

StorageApi.updateDataWithoutSearch = function(newItemList)
	newItemList = newItemList or StorageApi.currentData.list or nil
	if newItemList == nil then return StorageApi.updateDataWithSearch() end
	StorageApi.currentData = StorageApi.calculateData(newItemList)
	return StorageApi.currentData
end

-- 	-- todo концептуально подумать. при каждом обновлении - считывать данные, и если данные отличаются, асинхронно искать информацию о предметах.
-- StorageApi.updateDataWithSmartSearch = function (itemsList)
-- 	itemsList = itemsList or StorageApi.currentData.list or nil
-- 	if itemsList == nil then return StorageApi.updateDataWithSearch() end
-- 	local lowCheckList = StorageApi.storage.list()
-- 	local indexesForNewCheck = {}
-- 	-- find diff
-- 	for k, v in pairs(lowCheckList) do
-- 		if v["name"]~=itemsList[k]["name"] or v["count"]~=itemsList[k]["count"] then
-- 			indexesForNewCheck[k] = v
-- 		end
-- 	end


-- end

StorageApi.filterItemList = function(itemsTbl)
	local res = {}

	local function resSearchIndex(item)
		for i, resItem in pairs(res) do
			if resItem and resItem.name == item.name then
				return i
			end
		end
		return nil
	end

	for _, item in pairs(itemsTbl) do
		if item then
			local searchIndex = resSearchIndex(item)
			if searchIndex then
				res[searchIndex]["count"] = res[searchIndex]["count"] + item["count"]
			else
				res[#res + 1] = { name = item["name"], count = item["count"] }
			end
		end
	end

	-- simplify names
	for _, resItem in pairs(res) do
		if resItem and resItem["name"] then
			resItem["name"] = resItem["name"]:match(":([^:]*)$")
		end
	end

	return res
end

StorageApi.getAllSlotsDetails = function(asyncStreams)
	asyncStreams = asyncStreams or 5
	local itemsList = {}
	local regions = divideIntoSectors(StorageApi.size, asyncStreams)
	local fList = asyncFunctionsGenerator(regions, itemsList, getAsyncInfoForRegion)
	parallel.waitForAll(unpack(fList))
	return itemsList
end

StorageApi.calculateData = function(itemsList)
	local storageSize = StorageApi.size
	local itemsSum = 0
	local itemsSumLimit = 0

	for i = 1, storageSize do
		local item = itemsList[i]
		if item then
			itemsSum = itemsSum + item.count
			itemsSumLimit = itemsSumLimit + item.maxCount
		else
			itemsSumLimit = itemsSumLimit + 64
		end
	end

	local percentageOfSlotsLimit = BasicApi.getRealLength(itemsList) / storageSize * 100
	local percentageOfCountLimit = itemsSum / itemsSumLimit * 100
	local maxPercentageUsage = math.max(percentageOfCountLimit, percentageOfSlotsLimit)

	return {
		list = itemsList,
		storageSize = storageSize,
		itemsSum = itemsSum,
		itemsSumLimit = itemsSumLimit,
		maxPercentageUsage = maxPercentageUsage,

		percentageOfSlotsLimit = percentageOfSlotsLimit,
		percentageOfCountLimit = percentageOfCountLimit,
	}
end

-- todo theoretically could be optimized
StorageApi.defragment = function(itemsList)
	local function asyncDefrag(startIndex, endIndex, listToWorkWith)
		if startIndex == endIndex or startIndex - endIndex == 1 then return end
		for i = startIndex, endIndex do
			local item = listToWorkWith[i]
			for i2 = startIndex, endIndex do
				local item2 = listToWorkWith[i2]
				if
				item ~= nil
				and item2 ~= nil
				and (item.count ~= item.maxCount or item2.count ~= item2.maxCount)
				and item.name == item2.name
				then
					local res = StorageApi.storage.pushItems(StorageApi.name, i2, nil, i)
					item.count = item.count + res
					item2.count = item2.count - res
					if item2.count == 0 then
						listToWorkWith[i2] = nil
					end
				end
			end
		end
	end
	local itemsListSize = BasicApi.getRealLength(itemsList)
	
	local function iterationOfDefrag(asyncStreams)
		local regions = divideIntoSectors(itemsListSize, asyncStreams)
		local fList = asyncFunctionsGenerator(regions, itemsList, asyncDefrag)
		parallel.waitForAll(unpack(fList))
	end
	
	-- disable for small storage sizes
	if itemsListSize > 20 then
		iterationOfDefrag(itemsListSize / 20)
	end
	
	iterationOfDefrag(itemsListSize / 10)
	iterationOfDefrag(itemsListSize / 5)
	iterationOfDefrag(itemsListSize / 2)
	iterationOfDefrag(1)
	
	return itemsList
end

StorageApi.dropMoreThanFilter = function(itemsList)
	-- get filter
	local filterData = GeneralApi.readFileAsDataTable("storageFilter")
	if filterData == nil then return itemsList end
	itemsList = itemsList or StorageApi.currentData.list or nil
	if itemsList == nil then return itemsList end
	for k, line in ipairs(filterData) do
		local fItemName = line:match("([^=]+)=.+")
		local fItemMaxCount = tonumber(line:match("=([0-9]+)"))
		if fItemName and fItemMaxCount then
			-- find items as in filter
			local summOfItemsWithSameName = 0
			for k2, item in pairs(itemsList) do
				if item["name"] == fItemName then
					summOfItemsWithSameName = summOfItemsWithSameName + item["count"]
				end
			end
			-- calculate currentItem count
			if summOfItemsWithSameName > fItemMaxCount then
				-- drop cycle for each item
				local needToDropCount = summOfItemsWithSameName - fItemMaxCount
				local dropI = 1
				while needToDropCount > 0 and dropI <= StorageApi.size do
					local currentItem = itemsList[dropI]
					if currentItem ~= nil and currentItem["name"] == fItemName then
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
							dropResAcc = dropResAcc + StorageApi.storage.pushItems(StorageApi.binName, dropI, currentDropValue)
						end
						if currentItemCount - currentDropValue <= 0 then
							itemsList[dropI] = nil
						else
							itemsList[dropI]["count"] = itemsList[dropI]["count"] - currentDropValue
						end
						-- update drop counter
						needToDropCount = needToDropCount - currentDropValue
					end
					dropI = dropI + 1
				end
			end
		end
	end

	return itemsList
end

return StorageApi


-- late todo - адаптировать под мультиинвентарь
