local m = peripheral.find("monitor") or term
if m.setTextScale then m.setTextScale(0.5) end
MAX_CIRCLES = 100

local Symbol = {}
Symbol.__index = Symbol

local CircleForm = { { x = -2, y = 1 }, { x = -2, y = 0 }, { x = -1, y = -1 },
  { x = 0,  y = -2 }, { x = 1, y = -2 }, { x = 2, y = -1 },
  { x = 3, y = 0 }, { x = 3, y = 1 }, { x = 2, y = 2 },
  { x = 1, y = 3 }, { x = 0, y = 3 }, { x = -1, y = 2 } }

local WinObj = {}
WinObj.__index = WinObj

local WinCanvas = {}
WinCanvas.__index = WinCanvas

function Symbol:new(source)
  local obj = {}
  setmetatable(obj, self)
  obj.textColor = colors.white
  obj.bgColor = colors.black
  obj.pixel = { { false, false, false }, { false, false, false } }
  obj.invert = false
  obj.display = source
  obj.char = " "
  return obj
end

function Symbol:update()
  local char = 128
  if not self.pixel[2][3] then
    char = char + (self.pixel[1][1] and 1 or 0)
    char = char + (self.pixel[2][1] and 2 or 0)
    char = char + (self.pixel[1][2] and 4 or 0)
    char = char + (self.pixel[2][2] and 8 or 0)
    char = char + (self.pixel[1][3] and 16 or 0)
    self.invert = false
  else
    char = char + (self.pixel[1][1] and 0 or 1)
    char = char + (self.pixel[2][1] and 0 or 2)
    char = char + (self.pixel[1][2] and 0 or 4)
    char = char + (self.pixel[2][2] and 0 or 8)
    char = char + (self.pixel[1][3] and 0 or 16)
    self.invert = true
  end
  self.char = string.char(char)
end

function Symbol:draw()
  if self.invert then
    self.display.setBackgroundColor(self.textColor)
    self.display.setTextColor(self.bgColor)
  else
    self.display.setBackgroundColor(self.bgColor)
    self.display.setTextColor(self.textColor)
  end
  self.display.write(self.char)
end

function WinCanvas:new(win, scale)
  if win.setTextScale then win.setTextScale(scale or 0.5) end
  win.clear()
  local obj = {}
  setmetatable(obj, self)
  obj.x = 1
  obj.y = 1
  obj.display = win
  local w, h = win.getSize()
  obj.width = w
  obj.height = h
  obj.symbols = {}
  for i = 1, obj.width do
    obj.symbols[i] = {}
    for j = 1, obj.height do
      obj.symbols[i][j] = Symbol:new(win)
    end
  end
  return obj
end

function WinCanvas:setPixel(x, y, value)
  x = x - 1
  y = y - 1
  local charX = math.floor(x / 2)
  local charY = math.floor(y / 3)
  local pixelX = x - charX * 2
  local pixelY = y - charY * 3
  charX = charX + 1
  charY = charY + 1
  self.symbols[charX][charY].pixel[pixelX + 1][pixelY + 1] = value;
  self.symbols[charX][charY]:update()
end

function WinCanvas:draw()
  for j = self.y, (self.height + self.y - 1) do
    self.display.setCursorPos(self.x, j)
    for i = self.x, (self.width + self.x - 1) do
      self.symbols[i][j]:draw()
    end
  end
end

function WinCanvas:drawCircle(x, y, value)
  for _, pixelPos in ipairs(CircleForm) do
    self:setPixel(x + pixelPos.x, y + pixelPos.y, value)
  end
  self:draw()
end

function WinCanvas:updateColor(textColor, bgColor)
  for j = self.y, (self.height + self.y - 1) do
    for i = self.x, (self.width + self.x - 1) do
      self.symbols[i][j].textColor = textColor
      self.symbols[i][j].bgColor = bgColor
    end
  end
end

function WinObj:new(source)
  local sW, sH = source.getSize()
  local obj = {}
  setmetatable(obj, self)
  obj.posX = math.random(1, sW - 2)
  obj.posY = math.random(1, sH - 2)
  obj.dirX = math.random(-1, 1)
  obj.dirY = math.random(-1, 1)
  obj.width = 3
  obj.height = 2
  obj.flashed = "flash"


  -- calcutae non zero velocity
  if obj.dirX == 0 and obj.dirY == 0 then
    local newVal = math.random(1, 2) == 1 and 1 or -1
    if math.random(1, 2) == 1 then
      obj.dirX = newVal
    else
      obj.dirY = newVal
    end
  end

  obj.source = source
  obj.sourceSize = { x = sW, y = sH }
  obj.win = window.create(source, obj.posX, obj.posY, obj.width, obj.height, true)
  obj.winCanvas = WinCanvas:new(obj.win)
  return obj
end

function WinObj:move(circlesArr)
  local predictedPosX = self.posX + self.dirX
  local predictedPosY = self.posY + self.dirY

  -- handle perpedicular
  if self.dirX == 0 and (self.posX <=1 + 2 or self.posX >= self.sourceSize.x - 2 - 2) then
    self.dirX = 1
  end
  if self.dirY == 0 and (self.posY <=1 + 2 or self.posY >= self.sourceSize.y - 2 - 2) then
    self.dirY = 1
  end

  -- Handle border collision
  if predictedPosX <= 1 or predictedPosX >= self.sourceSize.x - 2 then
    self.dirX = -self.dirX
    self.flashed = "flash"
  end
  if predictedPosY == 1 or predictedPosY >= self.sourceSize.y - 2 then
    self.dirY = -self.dirY
    self.flashed = "flash"
  end

  for i, winWithCircle in ipairs(circlesArr) do
    if winWithCircle ~= self then
      local distanceX = (winWithCircle.posX + winWithCircle.width / 2) - (predictedPosX + self.width / 2)
      local distanceY = (winWithCircle.posY + winWithCircle.height / 2) - (predictedPosY + self.height / 2)
      if math.sqrt(distanceX * distanceX + distanceY * distanceY) < 2 then
        -- Определение оси столкновения
        if math.abs(distanceX) > math.abs(distanceY) then
          self.dirX = -self.dirX ~= 0 and -self.dirX or -winWithCircle.dirX
          winWithCircle.dirX = -winWithCircle.dirX ~=0 and -winWithCircle.dirX or -self.dirX
        else
          self.dirY = -self.dirY ~= 0 and -self.dirY or -winWithCircle.dirY
          winWithCircle.dirY = -winWithCircle.dirY ~=0 and -winWithCircle.dirY or -self.dirY
        end
        -- Диагональное столкновение
        if math.abs(distanceX) > 1 and math.abs(distanceY) > 1 then
          self.dirY = -self.dirY ~= 0 and -self.dirY or -winWithCircle.dirY
          winWithCircle.dirY = -winWithCircle.dirY ~= 0 and -winWithCircle.dirY or -self.dirY
        end
      end
    end
  end

  self.posX = self.posX + self.dirX
  self.posY = self.posY + self.dirY
  self.win.reposition(self.posX, self.posY)

  if self.flashed=="flash" then
    self.winCanvas:updateColor(colors.black, colors.white)
    self.winCanvas:drawCircle(3,3,true)
    self.flashed = "normal"
  elseif self.flashed=="normal" then
    self.winCanvas:updateColor(colors.white, colors.black)
    self.winCanvas:drawCircle(3,3,true)
    self.flashed = ""
  end
end


m.clear()
local circles = {}
for i = 1, MAX_CIRCLES do
  circles[i] = WinObj:new(m)
  circles[i].win.setBackgroundColor(colors.black)
  circles[i].win.clear()
  circles[i].winCanvas:drawCircle(3, 3, true)
end

while true do
  sleep(0.08)
  m.clear()
  for i, v in ipairs(circles) do v:move(circles) end
end
