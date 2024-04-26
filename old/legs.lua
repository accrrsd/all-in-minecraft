local LeftLeg = {
  inDefaultPos = false,
  outputStrength = 3,
  inputStrangth=14,
  -- relative to pc
  side="right",
  outputSide="back",
  Controller = peripheral.wrap("Create_SequencedGearshift_2"),
}

local RightLeg = {
  inDefaultPos = false,
  outputStrength = 2,
  inputStrangth=13,
  side="left",
  outputSide="back",
  Controller = peripheral.wrap("Create_SequencedGearshift_1"),
}


local function checkLegIsDefaultPos(leg)
  if redstone.getInput(leg.side) then
    leg.inDefaultPos = true
    return true
  else
    leg.inDefaultPos = false
    return false
  end
end


local function moveLeg(leg, deg, speed)
  if deg == nil then deg = 90 end
  if speed == nil then speed = 2 end
  leg.Controller.rotate(90, speed)
end

local function TicksToSeconds(ticks) return ticks / 20 end
local function secondsToTicks(seconds) return seconds * 20 end

local function OutputPulse(side, strength, ticks)
	redstone.setAnalogOutput(side, strength)
	os.sleep(ticks)
	redstone.setAnalogOutput(side, 0)
end


local function ReturnLegToDefPos(leg)
  if checkLegIsDefaultPos(leg)==true then return end
  while checkLegIsDefaultPos(leg) == false do
    moveLeg(leg)
    os.pullEvent("redstone")
  end
end

moveLeg(RightLeg)
os.pullEvent("redstone")
ReturnLegToDefPos(RightLeg)

