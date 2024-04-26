local DrillControls = {
  nextChunkPosToDig = 0,
  lastHorizontalPos = 1,
}

--- Main dig function
function DrillControls:digAndReturnVertical()
  local res = DrillBase:moveUntillEnd("down")
  if not res then error("drills: cant dig down", 2) return false end
  DrillBase:moveUntillEnd("up", true)
  self.nextChunkPosToDig = self.nextChunkPosToDig + 1
  return true
end

--- Dig and return to base
function DrillControls:digAndReturnToBase()
  self:digAndReturnVertical()
  -- prevent to stuck in first iteration
  self.lastHorizontalPos = DrillBase.currentHorisontalPos
  if self.lastHorizontalPos == 1 then return true end
  local res = DrillBase:moveUntillEnd("backward")
  if not res then error("drills: cant return to base", 2) return false end
  return true
end

--- Move from base to the next chunk
function DrillControls:returnFromBaseToNextChunk()
  local neededBlocks = self.nextChunkPosToDig*2
  if neededBlocks == 0 then return true end
  if neededBlocks > DrillBase.LENGTH_OF_STICK then return false end
  local res = DrillBase:moveNBlocks("forward", neededBlocks, true)
  if not res then error("drills: cant return from base to needed chunk", 2) return false end
  return true
end

--- Move from base to last pos
function DrillControls:returnFromBaseToLastPos()
  if self.lastHorizontalPos == 1 then error("drills: lastHorizontalPos is not setted", 2) return false end
  local res = DrillBase:moveNBlocks("forward", self.lastHorizontalPos-1, true)
  if not res then error("drills: cant return from base to last pos", 2) return false end
  return true
end

--- Reset position and state
function DrillControls:resetPosition()
  DrillBase:moveUntillEnd("up")
  DrillBase:moveUntillEnd("backward")
  self.nextChunkPosToDig = 0
  self.lastHorizontalPos = 1
end

return DrillControls

-- ========================================
-- function DrillControls:autoDig()
--   while DrillBase.currentHorisontalPos < DrillBase.LENGTH_OF_STICK do
--     if not DrillControls:digAndReturnToBase() then break end
--     if not DrillControls:returnFromBaseToNextChunk() then break end
--   end
-- end

-- DrillControls:autoDig()