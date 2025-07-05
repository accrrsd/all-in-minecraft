local RelayHandlerClass = require("handlers/RelayHandler")
local GearshiftHandlerClass = require("handlers/GearshiftHandler")
local RelayClass = require("api/RelayClass")
local MovementHandlerClass = require("handlers/MovementHandler")
local ActionsHandlerClass = require("handlers/ActionsHandler")

local RelayHandler = RelayHandlerClass:new()
local GearshiftHandler = GearshiftHandlerClass:new(RelayHandler)
local MovementHandler = MovementHandlerClass:new(RelayHandler, GearshiftHandler)

local ActionsHandler = ActionsHandlerClass:new(MovementHandler)

-- MovementHandler:moveBackward()
-- MovementHandler:moveForward()

MovementHandler:changeArmLength(0)

-- MovementHandler.RelayHandler:moveFromEngine180Deg(math.random() > 0.5)

-- todo Разобрать с акшенами, в том плане, что они удаляются немного не так, а еще они кажется не выполняют одно движение назад из 4-х


--[[ ActionsHandler:add(ActionsHandler:createMovementAction("backward"))
ActionsHandler:add(ActionsHandler:createMovementAction("backward"))
ActionsHandler:add(ActionsHandler:createMovementAction("backward"))
ActionsHandler:add(ActionsHandler:createMovementAction("backward"))
ActionsHandler:save() ]]
