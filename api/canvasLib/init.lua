local current_dir = (...):gsub("%.", "/"):gsub("/init", "")

-- Termins:
-- PixGrid - pixel coords, its width*2 and height*3
-- SymGrid - symbol coords, its default symbols, width, height

local canvasLib = {
	private = {},
}
_G.canvasLib = canvasLib
canvasLib.private.PixelsClass = require(current_dir .. "/pixels")
canvasLib.private.SymbolClass = require(current_dir .. "/symbol")
canvasLib.CanvasClass = require(current_dir .. "/canvas")
canvasLib.WindowClass = require(current_dir .. "/window")
return canvasLib
