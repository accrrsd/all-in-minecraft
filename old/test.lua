local leftLeg = {
	outputStrength = 1,
	moveBaseOutputStrength = 3,
	inputStrength = 15,
	moving = false,
	currentPos = -1,
	side = "left",
	calibrationInputStrength = 15,
	checkLenghtPosStrength = 8,
	inputSide = "left",
	outputSide = "back",
	calibrationSide = "right"
}

local rightLeg = {
	outputStrength = 2,
	moveBaseOutputStrength = 4,
	inputStrength = 14,
	moving = false,
	currentPos = -1,
	side = "right",
	calibrationInputStrength = 14,
	checkLenghtPosStrength = 7,
	inputSide = "left",
	outputSide = "back",
	calibrationSide = "right"
}

WaitCalibration = true

local function TicksToSeconds(ticks) return ticks / 20 end
local function secondsToTicks(seconds) return seconds * 20 end

local function OutputPulse(side, strength, ticks)
	redstone.setAnalogOutput(side, strength)
	os.sleep(ticks)
	redstone.setAnalogOutput(side, 0)
end

local function checkDefaultLegPosition(leg)
	OutputPulse(leg.outputSide, leg.checkLenghtPosStrength, TicksToSeconds(4))
	local limitTimer = os.startTimer(TicksToSeconds(20))
	while true do
		local event, timerID = os.pullEvent()
		if timerID == limitTimer then return false end
		if event == "redstone" then
			return true
		end
	end
end

local function calibrateLeg(leg)
	if checkDefaultLegPosition(leg) == true then return end
	local signal
	while signal ~= leg.calibrationInputStrength do
		OutputPulse(leg.outputSide, leg.outputStrength, TicksToSeconds(4))
		os.pullEvent("redstone")
		signal = redstone.getAnalogInput(leg.calibrationSide)
	end
end

local function moveLeg90Deg(leg)
	OutputPulse(leg.outputSide, leg.outputStrength, TicksToSeconds(4))
end

local function moveBase180Deg(leg)
	OutputPulse(leg.outputSide, leg.moveBaseOutputStrength, TicksToSeconds(4))
end



local function HandleCalibration() calibrateLeg(rightLeg) calibrateLeg(leftLeg) end


local function HandleForwardMotion(leg)
	moveLeg90Deg(leg)
	os.pullEvent("redstone")
	moveLeg90Deg(leg)
	os.pullEvent("redstone")
	moveBase180Deg(leg)
	os.pullEvent("redstone")
	calibrateLeg(leg)
end

local function HandleBackwardMotion(leg)
	moveBase180Deg(leg)
	os.pullEvent("redstone")
	calibrateLeg(leg)
end

local function HandleUpMotion(leg)
	moveLeg90Deg(leg)
	os.pullEvent("redstone")
	moveLeg90Deg(leg)
	os.pullEvent("redstone")
	moveLeg90Deg(leg)
	os.pullEvent("redstone")
	moveBase180Deg(leg)
	os.pullEvent("redstone")
	calibrateLeg(leg)
end

local function HandleDownMotion(leg)
	moveLeg90Deg(leg)
	os.pullEvent("redstone")
	moveBase180Deg(leg)
	os.pullEvent("redstone")
	calibrateLeg(leg)
end

local function main()
	HandleCalibration()
	 while true do
	 	local _, key = os.pullEvent("key")
	 	if key==keys.s then HandleBackwardMotion(rightLeg) end
	 	if key==keys.w then HandleForwardMotion(leftLeg) end
	 	if key==keys.space then HandleUpMotion(rightLeg) end
	 	if key==keys.leftShift then HandleDownMotion(leftLeg) end
	 end
end

main()

-- local function main()
-- 	while true do
		
-- 	end
-- end

-- parallel.waitForAny(main, wait_for_exit_key)

-- local function LegMovementLogic(leg)
-- 	if leg.moving == true then
-- 		redstone.setAnalogOutput(leg.outputSide, leg.outputStrength)
-- 		increaseLegPos(leg)
-- 		leg.moving = false
-- 	else
-- 		leg.moving = true
-- 	end
-- end

-- local function increaseLegPos(leg)
-- 	if leg.currentPos + 1 == 4 then
-- 		leg.currentPos = 0
-- 	else
-- 		leg.currentPos = leg.currentPos + 1
-- 	end
-- end

-- local function impulseAnalogOutput(outputSide, outputStrength, timeInSec)
-- 	if (timeInSec == nil) then timeInSec = TicksToSeconds(10) end
-- 	redstone.setAnalogOutput(outputSide, outputStrength)
-- 	os.sleep(timeInSec)
-- 	redstone.setAnalogOutput(outputSide, 0)
-- 	return true
-- end


-- local function calibrateLeg(leg)
-- 	if leg.currentPos ~= -1 then return end
-- 	local signal
-- 	while signal ~= leg.calibrationInputStrength do
-- 		redstone.setAnalogOutput(leg.outputSide, leg.outputStrength)
-- 		os.sleep(1)
-- 		redstone.setAnalogOutput(leg.outputSide, 0)
-- 		signal = redstone.getAnalogInput(leg.inputSide)
-- 	end
-- 	leg.currentPos = 0
-- end

-- local function getRedstoneInput()
-- 	while true do
-- 		local redstoneInput = redstone.getAnalogInput("right")
-- 		if redstoneInput == rightLeg.inputStrength then
-- 			LegMovementLogic(rightLeg)
-- 		elseif redstoneInput == leftLeg.inputStrength then
-- 			LegMovementLogic(leftLeg)
-- 		end
-- 		os.sleep(0)
-- 	end
-- end

-- -- local function HandleCalibration() parallel.waitForAll(calibrateLeg(leftLeg), calibrateLeg(rightLeg)) WaitCalibration = false end
-- local function HandleCalibration()
-- 	parallel.waitForAll(calibrateLeg(rightLeg))
-- 	WaitCalibration = false
-- 	print(leftLeg.currentPos, rightLeg.currentPos)
-- end


-- local function main()
-- 	HandleCalibration()
-- 	while waitCalibration == true do os.sleep(0) end

-- end

-- local function wait_for_exit_key()
-- 	repeat
-- 		local _, key = os.pullEvent("key")
-- 	until key == keys.q
-- end

-- parallel.waitForAny(main, wait_for_exit_key)
