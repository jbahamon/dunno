--- Dunno entry point. Also the point of definition of global variables.
-- @module main

--- Global variables.
-- @class table
-- @name globals
-- @field DEBUG Debug flag. If set to true, hitboxes are visible and other
--  debug messages are enabled.
-- @field Timer Utility for programming delayed events and others.
-- See <a href="http://vrld.github.com/hump/">hump's documentation</a> for 
-- more info on its use and behavior.
globals = {
	
	DEBUG = false,
	Timer = require 'lib.hump.timer'
}


local WorldManager = require 'data.core.WorldManager'
local manager

--- Clamp number between two values.
-- Returns input if it is between min_val and max_val; max_val if it is 
-- larger than it; min_val if it is smaller than it.
-- @param input The value to be clamped
-- @param min_val The lower bound of the clamping interval.
-- @param max_val The upper bound of the clamping interval. Must be 
-- greater than or equal to min_val

function math.clamp(input, min_val, max_val)
	input = math.min(input, max_val)
	input = math.max(input, min_val)
	return input
end

--- Load objects and properties needed to start the game.
-- Starts a WorldManager for each view, stages and players.
function love.load()

	manager = WorldManager()

	--manager:setStage("TomahawkMan")
	manager:setStage("SMB3-1-1")
	--manager:setStage("YoshisIsland3")
	manager:addPlayer("Megaman")
	--manager:addPlayer("Scrooge")

	manager:start()

end

--- Draw everything on the screen.
function love.draw()

	manager:draw()

end

--- Update everything.
-- If the time elapsed between two consecutive updates is greater than 
-- 0.3s, the update is skipped. This is useful to avoid glitches when
-- dragging the screen around or temporary drops in frame rate.
-- @param dt Time elapsed since the last update, in seconds.
function love.update(dt)
	if dt > 0.3 then
		return 
	end
	globals.Timer.update(dt)
	manager:update(dt)

end