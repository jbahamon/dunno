
--- WorldManager implementation.
-- @class module
-- @name data.core.WorldManager

local Class = require 'lib.hump.class'

local Loader = globals.Loader

local GameObjectManager = require 'data.core.WorldManager.GameObjectManager'
local CameraManager = require 'data.core.WorldManager.CameraManager'

local vector = require 'lib.hump.vector'

local Timer = globals.Timer

local WorldManager = Class {
	name = "WorldManager"
}

--- Builds a new, empty WorldManager
-- @class function
-- @name WorldManager
-- @return The newly created WorldManager
function WorldManager:init(name)
	self.name = name
	self.gameObjectManager = GameObjectManager(self)	
end

function WorldManager:addViewport(topLeft, bottomRight)
	if self.topLeft or self.bottomRight then
		error("We only support one view for now.")
	end

	self.topLeft = topLeft
	self.bottomRight = bottomRight

	if self.stage then
		self.stage:setBounds(self.topLeft, self.bottomRight)
	end
end



--- Class that handles interactions between the Stage, the Player(s) and 
-- other Elements. It uses an instance of @{CameraManager} to handle the camera.
-- @type WorldManager

-----------------------------------------------------------------
-- World building
-- @section building

--- Loads a stage from a file and sets it as the WorldManager's stage.
-- @param stageName The name of the stage's folder.
function WorldManager:setStage(stageName)

	if self.stage then self.stage.world = nil end

	self.stage = Loader.loadStage(stageName)
	self.stage.world = self
end

--- Starts the WorldManager and all of its elements (player, enemies, etc)
function WorldManager:start()

	assert(self.topLeft and self.bottomRight, "Cannot start without a viewport")

	local startingPosition = self.stage:getPixelStartingPosition()

	self.gameObjectManager:start(self.stage, startingPosition)
	self.stage:start(self.gameObjectManager.tileCollider, self.gameObjectManager.activeCollider, self.topLeft, self.bottomRight)
	self.stage:setRoom(self.stage:getRoomAt(startingPosition))

	
	--self.stage:start(self.gameObjectManager.tileCollider, self.gameObjectManager.activeCollider)
	
	-- Camera Management
	self.cameraManager = CameraManager(self, self.stage, self.topLeft, self.bottomRight)
	self.cameraManager:start()

	self.paused = false
	self.over = false
	
end

--- Loads a player from a folder and adds it to the world.
-- Having multiple players in the same world is not fully supported (in fact, it's very limited at the moment)
-- but should be added at some point.
-- @param playerName The name of the player's folder
function WorldManager:createPlayer(playerName)
	local player = Loader.loadCharacterFromName(playerName)
	player.world = self
	self.gameObjectManager:addPlayer(player)
end


function WorldManager:addObject(newObject)
	self.gameObjectManager:addObject(newObject)
	newObject.world = self
end

function WorldManager:removeObject(object)
	self.gameObjectManager:removeObject(object)
	object.world = nil
end


-----------------------------------------------------------------
-- Drawing and updating
-- @section draw

--- Draws all of the Elements managed by the WorldManager
function WorldManager:draw()
	self.cameraManager:draw(self.gameObjectManager.managedObjects)
end

--- Updates all of the Elements managed by the WorldManager, as well as the colliders
-- and the camera.
-- @param dt The time slice for the update.
function WorldManager:update(dt)

	if not self.paused then

		self.stage:update(dt)

		self.gameObjectManager:update(dt)

		self.stage:lateUpdate(dt)

		for i, player in ipairs(self.gameObjectManager.players) do
		    local roomChange = self.stage:checkRoomChange(player)

		    if i == 1 and roomChange then
		        self.cameraManager:roomTransition(player, roomChange, self)
		    end
		end

	end

	-- camera managing

	self.cameraManager:updateCameraFocus(self.gameObjectManager.players)
	self.stage:refreshElementSpawning(self.cameraManager:getVisible())
end

function WorldManager:win()
	self:pauseGame()
	self.gameFinished = true
	self.endState = "Win"
end

function WorldManager:lose()
	self:pauseGame()
	self.gameFinished = true
	self.endState = "Lose"
end


-----------------------------------------------------------------
-- Effects
-- @section effects

--- Pauses the game. While the game is paused, nothing moves by itself: 
-- no update functions are called.
-- @param time (Optional) The time for which the game will be paused, in seconds. If omitted, 
-- the game will be paused until @{WorldManager:unPauseGame} is called.
function WorldManager:pauseGame(time)
	self.paused = true
	if time then 
		self.pauseTimer = Timer.add(time, function() self.paused = false end )
	end

end

--- Unpauses the game. Update functions will start being called again after this function is called.
function WorldManager:unPauseGame()
	self.paused = false
	if self.pauseTimer then
		Timer.cancel(self.pauseTimer)
		self.pauseTimer = nil
	end
end


function WorldManager:getActiveCollider()
	return self.gameObjectManager.activeCollider
end

--- Called when two active elements collide. 
-- If the collision needs to be resolved in a particular order, this should be the 
-- place to decide it. For now there is no guarantee on which of the two objects is the first to
-- resolve the collision.
-- @param dt The time slice for the frame when the collision is detected
-- @param shapeA The first colliding shape, as a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape.
-- @param shapeB The second colliding shape, as a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape.
function WorldManager.onDynamicCollide(dt, shapeA, shapeB)
   	if shapeA.parent and shapeB.parent then
   		shapeA.parent:onDynamicCollide(dt, shapeB.parent)
   		shapeB.parent:onDynamicCollide(dt, shapeA.parent)
   	end
end

function WorldManager:destroySelf()
	self.gameObjectManager:destroySelf()
	self.cameraManager:destroySelf()
end

return WorldManager