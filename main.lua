DEBUG = false

-- one of the few global variables we'll have. Time is absolute!
Timer = require 'lib.hump.timer'


function math.clamp(input, min_val, max_val)
	input = math.min(input, max_val)
	input = math.max(input, min_val)
	return input
end

local WorldManager = require 'data.core.WorldManager'

local manager

function love.load()

	manager = WorldManager()

	--manager:setStage("TomahawkMan")
	manager:setStage("SMB3-1-1")
	--manager:setStage("YoshisIsland3")
	manager:addPlayer("Scrooge")

	manager:start()

end


function love.draw()
	manager:draw()

end

function love.update(dt)
	if dt > 0.3 then
		return 
	end
	Timer.update(dt)
	manager:update(dt)
end