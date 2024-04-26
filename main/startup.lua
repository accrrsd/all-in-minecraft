LegsApi = require("legsApi")
DisplayApi = require("displayApi")
BasicApi = require("basicApi")

-- DisplayApi.simpleLoader("Please Stand By!", 0, 0, false, colors.black, colors.white)

-- new - async version
if LegsApi.ReadBuffer() ~= nil then
	LegsApi.findLegs()
	os.sleep(0)
	LegsApi.doWithMovementBuffer()
  -- if movement is not base - run system as always
  term.setPaletteColour(colors.brown, colors.packRGB(0.2, 0.15, 0.1))
	term.setPaletteColour(colors.yellow, colors.packRGB(0.3, 0.3, 0.3))
  DisplayApi.mainMenu()
else
  -- if we dont need to move - can async find legs
	term.setPaletteColour(colors.brown, colors.packRGB(0.2, 0.15, 0.1))
	term.setPaletteColour(colors.yellow, colors.packRGB(0.3, 0.3, 0.3))
  -- async find legs, and open main menu
	-- WARNING! If we call return "displayApi.mainMenu" - it will run mainMenu only, without other parralel functions 
	parallel.waitForAll(LegsApi.findLegs, DisplayApi.mainMenu)
end
