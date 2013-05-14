
--- WorldManager implementation.
-- @class module
-- @name data.core.WorldManager

local Class = require 'lib.hump.class'

local Player = require 'data.core.Player'
local Stage = require 'data.core.Stage'
local ElementFactory = require 'data.core.ElementFactory'
local CameraManager = require 'data.core.WorldManager.CameraManager'


local ActiveCollider = require 'lib.HardonCollider'
local TileCollider = require 'lib.TileCollider'


local vector = require 'lib.hump.vector'

local Timer = globals.Timer


--- Builds a new, empty WorldManager
-- @class function
-- @name WorldManager
-- @return The newly created WorldManager
local WorldManager = Class {
	name = "WorldManager",

	init = 
		function (self, topLeft, bottomRight)
			self.topLeft = topLeft
			self.bottomRight = bottomRight
			self.players = {}
			self.paused = false
		end
}


--- Class that handles interactions between the Stage, the Player(s) and 
-- other Elements. It uses an instance of @{CameraManager} to handle the camera.
-- @type WorldManager

-----------------------------------------------------------------
-- World building
-- @section building

--- Loads a stage from a file and sets it as the WorldManager's stage.
-- @param stageName The name of the stage's folder.
function WorldManager:setStage(stageName)
	
	self.stage = Stage.loadFromFolder(stageName)
	self.tileCollider = TileCollider(self.stage)
	self.activeCollider = ActiveCollider(100, self.onDynamicCollide)

	for i, player in ipairs(self.players) do
		player:setColliders(self.tileCollider, self.activeCollider)
	end

	self.stage:initialize(self.tileCollider, self.activeCollider, self.topLeft, self.bottomRight)

end

--- Starts the WorldManager and all of its elements (player, enemies, etc)
function WorldManager:start()
	local startingPosition = self.stage:getPixelStartingPosition()
	self.stage:setRoom(self.stage:getRoomAt(startingPosition))
	self.cameraManager = CameraManager(self.players, self.stage, self.topLeft, self.bottomRight)
	self.cameraManager:start()

	for i, player in ipairs(self.players) do
		player:setStartingPosition(startingPosition)
		player:start()
	end

	self.paused = false

end

--- Loads a player from a folder and adds it to the WorldManager.
-- Having multiple players in the same world is not fully supported (in fact, it's very limited at the moment)
-- but should be added at some point.
-- @param playerName The name of the player's folder
function WorldManager:addPlayer(playerName)
	local parameters = self:loadPlayerParameters(playerName, Player.characterFolder)

	local player = Player.loadBasicFromParams(parameters, Player.characterFolder .. '/' .. playerName )

	if self.stage then 
		player:setColliders(self.tileCollider, self.activeCollider)
	end
	
	player:loadSpritesFromParams(parameters)
	player:loadBasicStates(parameters)
	player:loadStatesFromParams(parameters)

	if parameters.postBuild then
		parameters.postBuild(player)
	end

	table.insert(self.players, player)
	
end


-----------------------------------------------------------------
-- Drawing and updating
-- @section draw

--- Draws all of the Elements managed by the WorldManager
function WorldManager:draw()
	self.cameraManager:draw(self.players)
end


--- Updates all of the Elements managed by the WorldManager, as well as the colliders
-- and the camera.
-- @param dt The time slice for the update.
function WorldManager:update(dt)

	if not self.paused then

		for i, player in ipairs(self.players) do
			player:update(dt)
		end

		self.stage:update(dt)

		
		-- Collisions between a dynamic object and
		-- a static object (ie an interactive tile)
		-- are handled by our own module
		self.tileCollider:update(dt)
		
	    -- Collisions between dynamic objects are
	    -- handled by HardonCollider
	    self.activeCollider:update(dt)
		
	    -- We check for state changes after everything is done.
	    for i, player in ipairs(self.players) do
	    	player:checkStateChange()

	    	local roomChange = self.stage:checkRoomChange(player)

		    if i == 1 and roomChange then
		    	self.cameraManager:roomTransition(player, roomChange, self)
		    end
	    end

		self.stage:checkStateChanges()

	end

	-- camera managing

	self.cameraManager:updateCameraFocus(self.players)
	self.stage:refreshElementSpawning(self.cameraManager:getVisible())
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

--- Called when two active elements collide. 
-- If the collision needs to be resolved in a particular order, this should be the 
-- place to decide it. For now there is no guarantee on which of the two objects is the first to
-- resolve the collision.
-- @param dt The time slice for the frame when the collision is detected
-- @param shapeA The first colliding shape, as a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape.
-- @param shapeB The second colliding shape, as a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape.
function WorldManager.onDynamicCollide(dt, shapeA, shapeB)
   	if shapeA.parent and shapeB.parent then
   		shapeA.parent:onDynamicCollide(dt, shapeA, shapeB.parent)
   		shapeB.parent:onDynamicCollide(dt, shapeB, shapeA.parent)
   	end
end

--- Loads a Player's parameters from a file.
-- @param path The character's folder path.
-- @param rootFolder (Optional) Any base path to add to the character's path.
function WorldManager:loadPlayerParameters(path, rootFolder)
	rootFolder = rootFolder or ""

	local folder = rootFolder .. string.gsub(path, '[^%a%d-_/]', '')
	assert(love.filesystem.isFile(folder .. "/config.lua"), "Character configuration file \'".. folder .. "/config.lua"   .."\' not found")
	local ok, paramsFile = pcall(love.filesystem.load, folder .. "/config.lua")

	assert(ok, "Parameters file " .. path .. " has syntax errors: " .. tostring(playerFile))

	local parameters = paramsFile()
	assert(type(parameters) == "table", "Parameters file " .. path .. " must return a table")

	return parameters
end

return WorldManager