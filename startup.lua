local RelayHandlerClass = require("handlers/RelayHandler")
local GearshiftHandlerClass = require("handlers/GearshiftHandler")
local MovementHandlerClass = require("handlers/MovementHandler")
local ActionsHandlerClass = require("handlers/ActionsHandler")

local RelayHandler = RelayHandlerClass:new()
local GearshiftHandler = GearshiftHandlerClass:new()
local MovementHandler = MovementHandlerClass:new(RelayHandler, GearshiftHandler)

local ActionsHandler = ActionsHandlerClass:new(MovementHandler)

ActionsHandler:load()
ActionsHandler:doActions()
