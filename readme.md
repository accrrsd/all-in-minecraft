This program scans an area with a radius of 16 blocks and displays the scanned blocks on the portable computer screen. To run this program, you need a portable computer from ComputerCraft and a geo-scanner from Advanced Peripherals connected as a peripheral device. The computer screen can be either color or monochrome.

# Features

## Modes:
Modes are switched by pressing the spacebar, and the help menu opens with the 'h' key.
- **numeric** - Displays blocks as symbols, usually indicating the distance to the block relative to the leading axis (the direction the character is facing; more on this later). All filters apply to this mode.
- **relief** - Provides an overview of the landscape. Due to how the canvas mechanics work, blocks cannot be colored in this mode, but it takes up 2-3 times less space on the screen. Think of it as a zoom-out mode.
- **help** - Shows basic hotkeys for controlling the program; it's just a simple help menu.

## Axis:
The program automatically tries to determine the leading axis based on the character's movement. However, if the character has moved far or has only scanned once, this may not work (since the program operates without GPS, it can only determine direction based on already scanned areas). You can also manually rotate the axes using the arrow keys. For accurate distance display, it's recommended to align the axis with the character's view. You can open the F3 menu to check the correct axis; the axes in the program are oriented the same way as in the world, so there should be no issues.

You can toggle automatic direction detection with the 'R' key, and you can check the current mode in the help menu.
## Settings
### defaults
These settings define the standard value of the variables:
- **scanRadius** - default is max, max = 16, min = 1, more blocks - more laggy and energy cost scanner is, but pocket computer dont have energy, so it can be max without debuffs.
- **autoRotate** - default is true, if false autoRotate would be disable from start, sometimes you dont need it, or it can work buggy for you - here you can disable it.
- **mode** - default is numeric, can be relief or help.
- **firstScan** - default is false, if true program will immediately scan after start.

### Filters:
X-vision have 4 filters:
- **colorByName** - Uses a specific color if the name matches.
- **symbolByName** - Changes the symbol drawn to represent the block, determined by the name.
- **nameFilter** - Hides all blocks except those whose names are specified in the filter.
- **tagsFilter** - Hides all blocks except those that match AT LEAST ONE of the provided tags.

In most cases, I recommend using the color and symbol filters. However, if you want to strictly limit displayed values or if your screen does not support color, narrower filters may be useful.

## Setting Up Filters
Filters are configured similarly, but it's important to clarify how they work. The color filter accepts any of the pre-defined colors from ComputerCraft; these colors can be changed using Lua commands, but the names remain reserved.

### Possible Color Values:
- white
- orange
- magenta
- lightBlue
- yellow
- lime
- pink
- gray
- lightGray
- cyan
- purple
- blue
- brown
- green
- red
- black

### Using nameFilter and tagsFilter:
- Usually, you want to use one of them, not both.
- Both filters use empty keys and NBT values. For example:
  - `"": "minecraft:block/forge:ores"` - this filter would show only blocks that match.
  - For names, you can use `"": "minecraft:diamond_ore"` to display only diamond ores.

## Controls:
- **h** - Open the help menu
- **W A S D** - Move the camera around the scan
- **arrow left, arrow right** - Change the axis direction (rotate the scan)
- **arrow up, arrow down** - Change the displayed level (slice of the scan)
- **enter** - Perform a scan
- **r** - Toggle automatic direction detection (on/off)
- **space** - Switch display mode (numeric, relief)
- **backspace** - Exit the program
