local GearshiftClass = {}
GearshiftClass.__index = GearshiftClass

function GearshiftClass:new(name)
  local obj = {}
  local perepRes = peripheral.wrap(name)
  if perepRes ~= nil then obj.gearshift = perepRes end
  return setmetatable(obj, self)
end

function GearshiftClass:moveAfterRunning(lengthOffset, direction)
  local running = self.gearshift.isRunning()
  while running do
    local timer_id = os.startTimer(2)
    local _, id
    repeat _, id = os.pullEvent("timer") until id == timer_id
    running = self.gearshift.isRunning()
  end
  self.gearshift.move(lengthOffset, direction)
end

return GearshiftClass
