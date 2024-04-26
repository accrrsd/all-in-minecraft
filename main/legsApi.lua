LegsApi = {
  legsFinded = false,
  lastMovedLegSide = nil,
}

BasicApi = require("basicApi")
GeneralApi = require("generalApi")

LegsApi.leftLeg = {
  side = "left",
  gearshift = nil,
  integrator = nil,
  integratorName = nil,

  sideToWatchMovement = "front",
  sideToMoveBase = "top",
  sideToDefaultPos = "bottom"
}

LegsApi.rightLeg = {
  side = "right",
  gearshift = nil,
  integrator = nil,
  integratorName = nil,

  sideToWatchMovement = "front",
  sideToMoveBase = "top",
  sideToDefaultPos = "bottom"
}

local legsModem = peripheral.wrap("bottom")
local names = legsModem.getNamesRemote()
local redstoneIntegratorNames = BasicApi.findInTableMultiple(names, "redstoneIntegrator")
local gearshiftNames = BasicApi.findInTableMultiple(names, "Create_SequencedGearshift")

LegsApi.findLegs = function()
  local file
  LegsApi.legsFinded = false

  local function startCalibration()
    file = fs.open("legsConfig", "w")
    local randomLegIndex, randomLeg = BasicApi.pickRandom({ LegsApi.leftLeg, LegsApi.rightLeg })
    local oppositeRandomLeg = randomLegIndex == 1 and LegsApi.rightLeg or LegsApi.leftLeg

    local randomGearshiftIndex, randomGearshiftName = BasicApi.pickRandom(gearshiftNames)
    local oppositeGearshiftName = gearshiftNames[randomGearshiftIndex == 1 and 2 or 1]
    local randomGearshift = peripheral.wrap(randomGearshiftName)

    local randomRedstoneIntegratorIndex, randomRedstoneIntegratorName = BasicApi.pickRandom(redstoneIntegratorNames)
    local oppositeRedstoneIntegratorName = redstoneIntegratorNames[randomRedstoneIntegratorIndex == 1 and 2 or 1]

    local firstIntegratorSide = peripheral.call(randomRedstoneIntegratorName, "getInput", "left") == true and "right" or
        "left"
    local secondIntegratorSide = firstIntegratorSide == "right" and "left" or "right"

    if firstIntegratorSide == "right" then
      LegsApi.rightLeg.integratorName = randomRedstoneIntegratorName
    else
      LegsApi.leftLeg.integratorName =
          randomRedstoneIntegratorName
    end
    if secondIntegratorSide == "right" then
      LegsApi.rightLeg.integratorName = oppositeRedstoneIntegratorName
    else
      LegsApi.leftLeg.integratorName =
          oppositeRedstoneIntegratorName
    end

    LegsApi.rightLeg.integrator = peripheral.wrap(LegsApi.rightLeg.integratorName)
    LegsApi.leftLeg.integrator = peripheral.wrap(LegsApi.leftLeg.integratorName)

    local BeforeMovementinput = randomLeg.integrator.getInput(randomLeg.sideToDefaultPos)
    randomGearshift.rotate(90, 1)
    os.sleep(2)
    local AfterMovementinput = randomLeg.integrator.getInput(randomLeg.sideToDefaultPos)
    if BeforeMovementinput ~= AfterMovementinput then
      file.writeLine(randomLeg.side .. " = " .. randomGearshiftName .. " = " .. randomLeg.integratorName)
      randomLeg.gearshift = randomGearshift
      file.writeLine(oppositeRandomLeg.side ..
        " = " .. oppositeGearshiftName .. " = " .. oppositeRandomLeg.integratorName)
    else
      file.writeLine(randomLeg.side .. " = " .. oppositeGearshiftName .. " = " .. randomLeg.integratorName)
      randomLeg.gearshift = peripheral.wrap(oppositeGearshiftName)
      file.writeLine(oppositeRandomLeg.side .. " = " .. randomGearshiftName .. " = " .. oppositeRandomLeg.integratorName)
    end
    file.close()
    randomGearshift.rotate(90, -1)
    os.sleep(2)
  end

  local function findLegInfoInLine(leg, line)
    if not line:match(leg.side) then return nil end
    local gearshiftName = line:match("Create_SequencedGearshift_%d+")
    local integratorName = line:match("redstoneIntegrator_%d+")
    if gearshiftName == nil or integratorName == nil then return nil end
    return gearshiftName, integratorName
  end

  -- check if calibration exist
  if not fs.exists("legsConfig") then startCalibration() end
  file = fs.open("legsConfig", "r")
  local first = file.readLine()
  local second = file.readLine()
  if first == nil or second == nil then
    startCalibration()
  else
    for _, line in ipairs({ first, second }) do
      for _, leg in ipairs({ LegsApi.leftLeg, LegsApi.rightLeg }) do
        local gearshiftName, integratorName = findLegInfoInLine(leg, line)
        if gearshiftName ~= nil and integratorName ~= nil then
          leg.gearshift = peripheral.wrap(gearshiftName)
          leg.integrator = peripheral.wrap(integratorName)
          leg.integratorName = integratorName
        end
      end
    end
    if LegsApi.leftLeg.gearshift == nil or LegsApi.rightLeg.gearshift == nil then
      startCalibration()
    end
  end
  LegsApi.legsFinded = true
end

local function moveLeg(leg, deg, speed)
  deg = deg or 90
  speed = speed or 2
  leg.gearshift.rotate(deg, speed)
end

LegsApi.moveLegByDir = function(leg, dir, speed)
  speed = speed or 2
  if dir == "up" then moveLeg(leg, 90, -speed) end
  if dir == "down" then moveLeg(leg, 90, speed) end
  if dir == "forward" then moveLeg(leg, 180, -speed) end
  if dir == "backward" then moveLeg(leg, 180, speed) end
end

LegsApi.moveLegWithSignal = function(leg, dir, speed)
  LegsApi.moveLegByDir(leg, dir, speed)
  os.sleep(0)
  return GeneralApi.WaitForAny(GeneralApi.redstoneIntegratorBoolInputEvent,
    { leg.integrator, leg.sideToWatchMovement, true },
    GeneralApi.pullEventByName,
    { "redstoneIntegratorBoolInput" })
end

LegsApi.moveBase = function(leg)
  leg.integrator.setOutput(leg.sideToMoveBase, true)
  os.sleep(0)
  leg.integrator.setOutput(leg.sideToMoveBase, false)
  -- in rande between 1 and 0
  os.sleep(0.5)
end


-- command like: base left, base right, left leg up, right leg down, left leg forward, right leg backward

-- command like: BR, BL, LU, RD, LF, RB

LegsApi.movementBufferAdd = function(command)
  local file = fs.open("legsMovementBuffer", fs.exists("legsMovementBuffer") and "a" or "w")
  file.writeLine(command)
  file.close()
end

LegsApi.getAndRemoveFirstFromBuffer = function()
  local buffer = LegsApi.ReadBuffer()
  if buffer == nil then return nil end
  local removed = table.remove(buffer, 1)
  LegsApi.RewriteBuffer(buffer)
  return removed
end

LegsApi.getAndRemoveLastFromBuffer = function()
  local buffer = LegsApi.ReadBuffer()
  if buffer == nil then return nil end
  local removed = table.remove(buffer, #buffer)
  LegsApi.RewriteBuffer(buffer)
  return removed
end

LegsApi.ReadBuffer = function()
  return GeneralApi.readFileAsDataTable("legsMovementBuffer")
end

LegsApi.RewriteBuffer = function(data)
  GeneralApi.rewriteFileWithDataTable("legsMovementBuffer", data)
end

LegsApi.doWithMovementBuffer = function()
  local bufferCommand = LegsApi.getAndRemoveFirstFromBuffer()
  while bufferCommand ~= nil do
    os.sleep(0.1)
    -- base
    if bufferCommand == "BR" then
      LegsApi.moveBase(LegsApi.rightLeg)
    elseif bufferCommand == "BL" then
      LegsApi.moveBase(LegsApi.leftLeg)
      -- left
    elseif bufferCommand == "LU" then
      LegsApi.moveLegWithSignal(LegsApi.leftLeg, "up")
    elseif bufferCommand == "LD" then
      LegsApi.moveLegWithSignal(LegsApi.leftLeg, "down")
    elseif bufferCommand == "LF" then
      LegsApi.moveLegWithSignal(LegsApi.leftLeg, "forward")
    elseif bufferCommand == "LB" then
      LegsApi.moveLegWithSignal(LegsApi.leftLeg, "backward")
      -- right
    elseif bufferCommand == "RU" then
      LegsApi.moveLegWithSignal(LegsApi.rightLeg, "up")
    elseif bufferCommand == "RD" then
      LegsApi.moveLegWithSignal(LegsApi.rightLeg, "down")
    elseif bufferCommand == "RF" then
      LegsApi.moveLegWithSignal(LegsApi.rightLeg, "forward")
    elseif bufferCommand == "RB" then
      LegsApi.moveLegWithSignal(LegsApi.rightLeg, "backward")
    else
      break;
    end
    bufferCommand = LegsApi.getAndRemoveFirstFromBuffer()
  end
end

LegsApi.movementPresets = function(command, legSide)
  if legSide == nil then
    if LegsApi.lastMovedLegSide == nil then
      _, legSide = BasicApi.pickRandom({ "left", "right" })
    elseif LegsApi.lastMovedLegSide == "right" then
      legSide = "left"
    elseif LegsApi.lastMovedLegSide == "left" then
      legSide = "right"
    end
    LegsApi.lastMovedLegSide = legSide
  end
  if command == "up" then
    if legSide == "left" then
      return { "LU", "BL", "LU" }
    else
      return { "RU", "BR", "RU" }
    end
  elseif command == "down" then
    if legSide == "left" then
      return { "LD", "BL", "LD" }
    else
      return { "RD", "BR", "RD" }
    end
  elseif command == "forward" then
    if legSide == "left" then
      return { "LF", "BL" }
    else
      return { "RF", "BR" }
    end
  elseif command == "backward" then
    if legSide == "left" then
      return { "BL", "LB" }
    else
      return { "BR", "RB" }
    end
  end
end

return LegsApi