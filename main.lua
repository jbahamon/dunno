DEBUG = false

local vector = require 'lib.hump.vector'
local Camera = require 'lib.gamera'

local Player = require 'data.core.Player'
local Stage = require 'data.core.Stage.Stage'

local DynamicCollider = require 'lib.HardonCollider'
local TileCollider = require 'lib.TileCollider'

function love.load()
	currentStage = Stage()
	dynamicCollider = DynamicCollider(100, onDynamicCollide)
	tileCollider = TileCollider(currentStage)

	player = Player.loadFromFolder("Scrooge",
									tileCollider,
									dynamicCollider)

	player:setStartingPosition(currentStage:getStartingPosition():unpack())
	player:start()

	local stageSize = currentStage:getPixelSize()
	camera = Camera.new(0, 0, stageSize.x, stageSize.y)
	camera:setScale(2.0)

end


function love.draw()

	love.graphics.setColor(255, 255, 255, 255)

	camera:setPosition(player:getPosition():unpack())
	camera:draw(drawWorldElements)

end

function drawWorldElements(l, t, w, h)
	currentStage:moveTo(l, t)
	currentStage:draw()
	player:draw()
end



function love.update(dt)

	if dt > 0.3 then return end

	player:update(dt)
	
	-- Collisions between a dynamic object and
	-- a static object (ie an interactive tile)
	-- are handled by our own module
	tileCollider:update(dt)
	
    -- Collisions between dynamic objects are
    -- handled by HardonCollider
    
    dynamicCollider:update(dt)
	
    -- We check for state changes after everything is done.
    player:checkStateChange()


end



function onDynamicCollide(dt, shapeA, shapeB)
   
end