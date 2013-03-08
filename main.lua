DEBUG = false

local vector = require 'lib.hump.vector'
local Camera = require 'lib.gamera'

local Player = require 'data.core.Player'
local Stage = require 'data.core.Stage.Stage'

local DynamicCollider = require 'lib.HardonCollider'
local TileCollider = require 'lib.TileCollider'

function love.load()

	currentStage = Stage.loadFromFolder("TomahawkMan")
	dynamicCollider = DynamicCollider(100, onDynamicCollide)
	tileCollider = TileCollider(currentStage)

	player = Player.loadFromFolder("Scrooge",
									tileCollider,
									dynamicCollider)

	currentStage:initPlayer(player)
	player:start()

	local stageSize = currentStage:getPixelSize()

	camera = Camera.new(currentStage:getBounds())	
	camera:setScale(2)

end


function love.draw()

	love.graphics.setColor(255, 255, 255, 255)
	camera:setWorld(currentStage:getBounds())
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

    local roomChange = currentStage:checkRoomChange(player)

    if roomChange then
    	player:moveIntoCollidingBox(roomChange.nextRoom)
    	camera:setWorld(currentStage:getBounds())
    end

end



function onDynamicCollide(dt, shapeA, shapeB)
   
end