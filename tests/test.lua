local redstone = require("redstone")

local function getRedstoneInput()
  local rightInput = redstone.getInput("right")
  local leftInput = redstone.getInput("left")

  if (rightInput == true) then print("Right input") end
  if (leftInput == true) then print("Left input") end
end

while true do
  getRedstoneInput()
end
