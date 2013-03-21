--- WorldManager implementation.
-- @class module
-- @name data.core.WorldManager

local Class = require 'lib.hump.class'
local Timer = require 'lib.hump.timer'

local Player = require 'data.core.Player'
local Stage = require 'data.core.Stage'
local ElementFactory = require 'data.core.ElementFactory'

local Camera = require 'lib.gamera'

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
		function (self)
			self.players = {}
			self.fullScreenTint = {255, 255, 255, 255}
			self.paused = false
			self.lookingAt = vector(0,0)
			self.elementFactories = {}
			self.stageElements = {}
		end

}


--- Class that handles interactions between the Stage, the Player(s) and 
-- other Elements. Is also in charge of moving the camera around and apply some
-- effects such as transitions and fullscreen fading.
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

	self.stage.elementTypes = self.stage.elementTypes or {}

	for _, elementType in ipairs(self.stage.elementTypes) do
		self.elementFactories[elementType.name] = ElementFactory(elementType, self.tileCollider, self.activeCollider, self.stage:getFolder())
	end

	self.stage.elementLocations = self.stage.elementLocations or {}
end

--- Starts the WorldManager and all of its elements (player, enemies, etc)
function WorldManager:start()
	local startingPosition = self.stage:getPixelStartingPosition()
	self.stage:setRoom(self.stage:getRoomAt(startingPosition))

	self.lookingAt = self.stage:getPixelStartingFocus()

	self.camera = Camera.new(self.stage:getBounds())	
	self.camera:setScale(2)

	for i, player in ipairs(self.players) do
		player:setStartingPosition(startingPosition:unpack())
		player:start()
	end


	for _, element in ipairs(self.stage.elementLocations) do 
		local facing = element.facing or 1
		local elem = self.elementFactories[element.name]:createAt(element.position, element.facing)
		table.insert(self.stageElements, elem)
		elem:start()
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

	player:setColliders(self.tileCollider, self.activeCollider)
	player:loadSpritesFromParams(parameters)
	player:loadBasicStates(parameters)
	player:loadStatesFromParams(parameters)

	table.insert(self.players, player)
	
	if self.stage then 
		player:setColliders(self.tileCollider, self.activeCollider)
	end
end


-----------------------------------------------------------------
-- Drawing and updating
-- @section draw

--- Draws all of the Elements managed by the WorldManager
function WorldManager:draw()

	love.graphics.setColor(self.fullScreenTint)
	self.camera:setPosition(self.lookingAt:unpack())
	self.camera:draw(function (l, t, w, h)
   						self.stage:moveTo(l, t)
						self.stage:draw()

						for i, element in ipairs(self.stageElements) do
							element:draw()
							love.graphics.setColor(self.fullScreenTint)
						end

						for i, player in ipairs(self.players) do
							player:draw()
							love.graphics.setColor(self.fullScreenTint)
						end

					end)
end


--- Updates all of the Elements managed by the WorldManager, as well as the colliders
-- and the camera.
function WorldManager:update(dt)

	if not self.paused then

		for i, player in ipairs(self.players) do
			player:update(dt)
		end

		for i, element in ipairs(self.stageElements) do
			element:update(dt)
		end

		
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

		    if roomChange then
		    	self:roomTransition(player, roomChange)
		    end
	    end

	    for i, element in ipairs(self.stageElements) do
			element:checkStateChange()
		end
	end

	-- camera managing

	local playerPos = self.players[1]:getPosition()
	local tension = self.stage:getTension()

	self:updateCameraFocus()
end

-----------------------------------------------------------------
-- Camera modes and focusing
-- @section camera

--- Sets the point to where the camera should point to (i.e. the camera's focus).
-- The focus is set depending on the current camera mode.
function WorldManager:updateCameraFocus() 
	local snapDistance = 10
	local cameraMode = self.stage:getCameraMode() or { mode = "default" }

	local cameraFunction = WorldManager.cameraModes[cameraMode.mode]
	 or WorldManager.cameraModes["default"]

	cameraFunction(self, self.players[1], self.stage, cameraMode)
	
--[[	if (targetPosition - self.lookingAt):len2() > snapDistance then
		if not self.currentCameraMovement then
			self:scrollCamera(0.5, targetPosition)
		end
	else]]
	
end

--- Scrolls the camera from the current position to a target position, with
-- the given speed.
-- @param speed The speed (in pixels/second) to give to the camera
-- @param pointB The target position (in pixels) for the camera.
-- @param postFunction (Optional) A function that receives no parameters, to be executed after the
-- scrolling finished.
function WorldManager:scrollCameraWithSpeed(speed, pointB, postFunction)
	local pointA = self.lookingAt
	local distance = (pointB - pointA):len()

	self:scrollCameraWithTime(distance/speed, pointB, postFunction)

end

--- Scrolls the camera from the current position to a target position, such that the scrolling 
-- lasts a given time.
-- @param time The time for the scrolling to last, in seconds.
-- @param pointB The target position (in pixels) for the camera.
-- @param postFunction (Optional) A function that receives no parameters, to be executed after the
-- scrolling finished.
function WorldManager:scrollCameraWithTime(time, pointB, postFunction)

	local pointA = self.lookingAt

	if self.currentCameraMovement then
		Timer.cancel(self.currentCameraMovement)
		self.currentCameraMovement = nil
	else

		local cameraVelocity = (pointB - pointA)/time

		self.currentCameraMovement = Timer.do_for(time, 
			function (dt) 
				self.lookingAt = self.lookingAt + cameraVelocity * dt 
			end,
			function ()
				if postFunction then
					postFunction()
				end
				self.currentCameraMovement = nil
			end)
	end
end

--- Camera mode that follows the given player. 
-- @param player The player to follow.
-- @param stage The world's stage.
-- @param cameraMode The cameraMode parameters. Check the stage documentation to see 
-- the details on this parameter.
function WorldManager:followCameraMode(player, stage, cameraMode)

	local targetPosition = self.lookingAt:clone()

	if cameraMode.tension then
		local tension = cameraMode.tension

		local playerPos = player:getPosition()
		local lastPlayerPos = player:getLastPosition()
		

		-- horizontal following
		if playerPos.x > (self.lookingAt.x + tension.x) or
			playerPos.x < (self.lookingAt.x - tension.x) then 

			targetPosition.x = targetPosition.x + (playerPos.x - lastPlayerPos.x)

		end

		-- horizontal following
		if playerPos.y > (self.lookingAt.y + tension.y) or
			playerPos.y < (self.lookingAt.y - tension.y) then 

			targetPosition.y =  targetPosition.y + (playerPos.y - lastPlayerPos.y)

		end

	else 

		targetPosition = player:getPosition()
	end

	self.lookingAt = targetPosition
end

--- Camera mode that locks to a position in zero, one or more axes, 
-- and follows the given player in the remaining axes. It is not recommended to use this
-- mode if you're aiming to follow the player in both axes: followPlayer (and by extension
--	@{WorldManager:followCameraMode}) is more efficient and achieves this.
-- @param player The player to follow.
-- @param stage The world's stage.
-- @param cameraMode The cameraMode parameters. Check the stage documentation to see 
-- the details on this parameter.
function WorldManager:lockCameraMode(player, stage, cameraMode)
	local targetPosition 
	-- if we have to follow the player in one direction, then we do that first
	if not (cameraMode.verticalLock and cameraMode.horizontalLock) then 
		targetPosition = self:followCameraMode(player, stage, cameraMode)
	else 
		targetPosition = self.lookingAt:clone()
	end

	if cameraMode.horizontalLock then
		targetPosition.x = cameraMode.horizontalLock * self.stage.tileWidth
	end

	if cameraMode.verticalLock then
		targetPosition.y = cameraMode.verticalLock * self.stage.tileHeight
	end

	self.lookingAt = targetPosition
end

--- Camera mode that locks to the platform where the player is standing as the player 
-- goes up, and follows the player if it's going down. It follows the player in the horizontal 
-- axis.
-- @param player The player to follow.
-- @param stage The world's stage.
-- @param cameraMode The cameraMode parameters. Check the stage documentation to see 
-- the details on this parameter.
function WorldManager:platformCameraMode(player, stage, cameraMode)

	local tension = cameraMode.tension or vector(0, 0)

	local playerPos = player:getPosition()
	local lastPlayerPos = player:getLastPosition()

	-- horizontal following
	if playerPos.x > (self.lookingAt.x + tension.x) or
		playerPos.x < (self.lookingAt.x - tension.x) then 

		self.lookingAt.x = self.lookingAt.x + (playerPos.x - lastPlayerPos.x)

	end

	--vertical following
	if playerPos.y > (self.lookingAt.y + tension.y) or cameraMode._scrolling then
		self.lookingAt.y = self.lookingAt.y + (playerPos.y - lastPlayerPos.y)
	end


	local targetPosition = self.lookingAt:clone()

	-- Snapping to a platform. We only snap to the platform if the player gets to a higher platform.
	-- This is the behavior observed in Super Mario World's "Yoshi's Island 3" stage.

	if player:getStateFlags()["grounded"] then
		local oldLock = cameraMode.verticalLock	or math.floor(player:getPosition().y /  self.stage.tileHeight)

		cameraMode.verticalLock = math.floor(player:getPosition().y /  self.stage.tileHeight)

		if cameraMode.verticalLock < oldLock and not cameraMode._scrolling then

			targetPosition.y = cameraMode.verticalLock * self.stage.tileHeight

			self:scrollCameraWithSpeed(cameraMode.snapSpeed,
										targetPosition,
										function() 
											cameraMode._scrolling = nil
										end)

			cameraMode._scrolling = self.currentCameraMovement
		end
	end
end

WorldManager.cameraModes = {
	followPlayer = WorldManager.followCameraMode, -- 'free mode with tension'
	lock = WorldManager.lockCameraMode, -- 'snap to platforms with smooth transitions, horizontally free with tension (ignores vertical tension)' -- requires stateType
	snapToPlatform = WorldManager.platformCameraMode, -- 'snap to ceiling (?) (ignores vertical tension) '
	default = WorldManager.followCameraMode -- more modes can be added here "custom" modes with names. same for transitions
}

-----------------------------------------------------------------
-- Room Transitions
-- @section transitions

--- Executes a transition between two rooms, moving the camera as needed.
-- @param player The player that will transition between rooms.
-- @param roomChange The room transition parameters. It includes two fields: previousRoom and nextRoom.
-- A room includes a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (specifically, a rectangle) that represents the room and a tags dictionary
-- @param mode The transition mode. If there isn't a transition mode with this name, 
-- the transition uses the default mode.
function WorldManager:roomTransition(player, roomChange, mode)
	local transitionMode = mode or self.stage.roomTransitionMode
	local transition = WorldManager.transitions[transitionMode] or WorldManager.transitions["default"]
	transition(self, player, roomChange)
end

--- A transition that fades the screen to black and back as the player switches rooms.
-- @param player The player that will transition between rooms.
-- @param roomChange The room transition parameters. It includes two fields: previousRoom and nextRoom.
-- Each includes a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (specifically, a rectangle) that represents the room and a tags dictionary
function WorldManager:fadingTransition(player, roomChange)
	local rampTime = 0.5
	local blackTime = 0.5

	self:pauseGame(2*rampTime + blackTime)
	self:fadeToColor(rampTime, {0, 0, 0, 255}, 5)
	Timer.add(rampTime + blackTime/2, 
		function () 
	    	player:moveIntoCollidingBox(roomChange.nextRoom.box)
	    	self.stage:setRoom(roomChange.nextRoom)
	    	self.camera:setWorld(self.stage:getBounds())
	    	
	    end)
	Timer.add(rampTime + blackTime, function () self:fadeToColor(rampTime, {255, 255, 255, 255}) end )

end

--- A transition that scrolls both the player and the camera to the next room.
-- @param player The player that will scroll between rooms.
-- @param roomChange The room transition parameters. It includes two fields: previousRoom and nextRoom.
-- Each includes a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (specifically, a rectangle) that represents the room and a tags dictionary
function WorldManager:scrollTransition(player, roomChange)
	local scrollTime = 1.5

	local prevPlayerPos, prevCameraPos
	local nextPlayerPos, nextCameraPos

	-- We get the previous positions
	prevCameraPos = vector(self.camera:getVisible())
	prevPlayerPos = player:getPosition()

	-- We move both the player and the camera to the next room.

	local x1, y1, x2, y2 = roomChange.nextRoom.box:bbox()
	self.camera:setWorld(x1, y1, x2 - x1, y2 - y1)
	player:moveIntoCollidingBox(roomChange.nextRoom.box)
	self.camera:setPosition(player:getPosition():unpack())

	-- We get the after-transition positions
	nextCameraPos = vector(self.camera:getVisible())
	nextPlayerPos = player:getPosition()

	-- We revert the changes
	x1, y1, x2, y2 = roomChange.previousRoom.box:bbox()
	self.camera:setWorld(x1, y1, x2 - x1, y2 - y1)
	player:moveTo(prevPlayerPos:unpack())
	self.camera:setPosition(player:getPosition():unpack())
	
	local playerVelocity = (nextPlayerPos - prevPlayerPos)/scrollTime
	local cameraVelocity = (nextCameraPos - prevCameraPos)/scrollTime
	self:pauseGame(scrollTime)

	if self.currentCameraMovement then
		Timer.cancel(self.currentCameraMovement)
	end

	self.currentCameraMovement = Timer.do_for( scrollTime, 
		function (dt) 
			local l, t, w, h
			player:move((playerVelocity * dt):unpack())

			l, t, w, h = self.camera:getVisible()
			self.camera:setWorld( l + cameraVelocity.x * dt,
								  t + cameraVelocity.y * dt,
								  w,
								  h)
		end,
		function()
			self.stage:setRoom(roomChange.nextRoom)
			self.camera:setPosition(nextCameraPos:unpack())
			player:moveTo(nextPlayerPos:unpack())
			self.camera:setWorld(self.stage:getBounds())
			self.currentCameraMovement = nil
		end )
end

--- A simple room transition that teleports the player and the camera to the next room.
-- @param player The player that will scroll between rooms.
-- @param roomChange The room transition parameters. It includes two fields: previousRoom and nextRoom.
-- Each includes a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (specifically, a rectangle) that represents the room and a tags dictionary
function WorldManager:instantTransition(player, roomChange)
	player:moveIntoCollidingBox(roomChange.nextRoom.box)
	self.stage:setRoom(roomChange.nextRoom)
	self.camera:setWorld(self.stage:getBounds())
end

WorldManager.transitions = {
	none = WorldManager.instantTransition,
	scrolling = WorldManager.scrollTransition,
	fading = WorldManager.fadingTransition,
	default = WorldManager.instantTransition
}

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

--- Fades the screen to a solid tint. 
-- @param rampTime The time (in seconds) for the screen to get to the tint's full intensity.
-- @param color The color to apply to all elements, as an array (not a dictionary) of four values,
-- corresponding to red, green, blue, and alpha, in that order.
-- @param numSteps (Optional) The number of steps for the ramp. Use this to give the fading a "retro" look, 
-- having discrete intermediate values. If omitted, the transition is done as smoothly as possible.
function WorldManager:fadeToColor(rampTime, color, numSteps)

	if self.currentFadingEffect then
		Timer.cancel(self.currentFadingEffect)
	end
	
	local transitionSpeed

	if numSteps and numSteps > 0 then

		local stepTime = rampTime / numSteps
		self._numSteps = 0

		transitionSpeed = { (color[1] - self.fullScreenTint[1])/numSteps,
							  (color[2] - self.fullScreenTint[2])/numSteps, 
							  (color[3] - self.fullScreenTint[3])/numSteps,
							  (color[4] - self.fullScreenTint[4])/numSteps }

		self.currentFadingEffect = Timer.addPeriodic(
			stepTime,
			function() 
				self.fullScreenTint[1] = math.clamp(self.fullScreenTint[1] + transitionSpeed[1] , 0, 255)
				self.fullScreenTint[2] = math.clamp(self.fullScreenTint[2] + transitionSpeed[2] , 0, 255)
				self.fullScreenTint[3] = math.clamp(self.fullScreenTint[3] + transitionSpeed[3] , 0, 255)
				self.fullScreenTint[4] = math.clamp(self.fullScreenTint[4] + transitionSpeed[4] , 0, 255)
				self._numSteps = self._numSteps + 1

				return self._numSteps < numSteps 
			end,
			numsteps)

	else

		transitionSpeed = { (color[1] - self.fullScreenTint[1])/rampTime,
							  (color[2] - self.fullScreenTint[2])/rampTime, 
							  (color[3] - self.fullScreenTint[3])/rampTime,
							  (color[4] - self.fullScreenTint[4])/rampTime }


		self.currentFadingEffect = Timer.do_for(rampTime, 
				function (dt) 
					self.fullScreenTint[1] = math.clamp(self.fullScreenTint[1] + transitionSpeed[1] * dt, 0, 255)
					self.fullScreenTint[2] = math.clamp(self.fullScreenTint[2] + transitionSpeed[2] * dt, 0, 255)
					self.fullScreenTint[3] = math.clamp(self.fullScreenTint[3] + transitionSpeed[3] * dt, 0, 255)
					self.fullScreenTint[4] = math.clamp(self.fullScreenTint[4] + transitionSpeed[4] * dt, 0, 255)
				end,
				function ()
					self.fullScreenTint = color
					self.currentFadingEffect = nil
				end)
	end


end

function WorldManager.onDynamicCollide (dt, shapeA, shapeB)
   
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