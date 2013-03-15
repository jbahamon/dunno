local Class = require 'lib.hump.class'
local Timer = require 'lib.hump.timer'

local Player = require 'data.core.Player'
local Stage = require 'data.core.Stage.Stage'

local Camera = require 'lib.gamera'

local ActiveCollider = require 'lib.HardonCollider'
local TileCollider = require 'lib.TileCollider'

local vector = require 'lib.hump.vector'


local WorldManager = Class {
	name = "WorldManager",

	init = 
		function (self)
			self.players = {}
			self.fullScreenTint = {255, 255, 255, 255}
			self.paused = false
			self.lookingAt = vector(0,0)
		end

}


-----------------------------------------------------------------
-- Building
-----------------------------------------------------------------

function WorldManager:setStage(stageName)
	
	self.stage = Stage.loadFromFolder(stageName)
	self.tileCollider = TileCollider(self.stage)
	self.activeCollider = ActiveCollider(100, self.onDynamicCollide)

	for i, player in ipairs(self.players) do
		player:setColliders(self.tileCollider, self.activeCollider)
	end
end

function WorldManager:start()
	local startingPosition = self.stage:getPixelStartingPosition()
	self.stage:setRoom(startingPosition)

	self.lookingAt = self.stage:getPixelStartingFocus()

	self.camera = Camera.new(self.stage:getBounds())	
	self.camera:setScale(2)

	for i, player in ipairs(self.players) do
		player:setStartingPosition(startingPosition:unpack())
		player:start()
	end

	self.paused = false

end

function WorldManager:addPlayer(playerName)
	local player = Player.loadFromFolder(playerName,
										self.tileCollider,
										self.activeCollider)
	table.insert(self.players, player)

	if self.stage then 
		player:setColliders(self.tileCollider, self.activeCollider)
	end
end


-----------------------------------------------------------------
-- Drawing, Dynamics
-----------------------------------------------------------------

function WorldManager:draw()

	love.graphics.setColor(self.fullScreenTint)
	self.camera:setPosition(self.lookingAt:unpack())
	self.camera:draw(function (l, t, w, h)
   						self.stage:moveTo(l, t)
						self.stage:draw()

						for i, player in ipairs(self.players) do
							player:draw()
						end
					end)
end

function WorldManager:update(dt)

	if not self.paused then
		for i, player in ipairs(self.players) do
			player:update(dt)
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
	end

	-- camera managing

	local playerPos = self.players[1]:getPosition()
	local tension = self.stage:getTension()

	self:updateCameraFocus()
end

-----------------------------------------------------------------
-- Camera Managing
-----------------------------------------------------------------

function WorldManager:updateCameraFocus() 
	local cameraMode = self.stage:getCameraMode() or { mode = "default" }

	local cameraFunction = WorldManager.cameraModes[cameraMode.mode]
	 or WorldManager.cameraModes["default"]

	cameraFunction(self, self.players[1], self.stage, cameraMode)

end

function WorldManager:scrollCamera(time, pointB)

	local pointA = vector(self.camera:getVisible())

	if self.currentCameraMovement then
		Timer.cancel(self.currentCameraMovement)
		self.currentCameraMovement = nil
	else

		local cameraVelocity = (pointB - pointA)/time

		self.currentCameraMovement = Timer.do_for( time, 
			function (dt) 
				local l, t, w, h = self.camera:getVisible()
				self.camera:setWorld( l + cameraVelocity.x * dt,
									  t + cameraVelocity.y * dt,
									  w,
									  h)
			end,
			function ()
				self.currentCameraMovement = nil
			end)
	end
end

function WorldManager:followPlayerWithCamera(player, stage, cameraMode)
	local snapDistance = math.huge


	if cameraMode.tension then
		local tension = cameraMode.tension

		local snapTime = cameraMode.snapTime or 0.5

		local playerPos = player:getPosition()
		local lastPlayerPos = player:getLastPosition()
		
		-- horizontal following
		if playerPos.x > (self.lookingAt.x + tension.x) or
			playerPos.x < (self.lookingAt.x - tension.x)then 

			self.lookingAt.x = self.lookingAt.x + (playerPos.x - lastPlayerPos.x)

		end

		-- horizontal following
		if playerPos.y > (self.lookingAt.y + tension.y) or
			playerPos.y < (self.lookingAt.y - tension.y)then 

			self.lookingAt.y = self.lookingAt.y + (playerPos.y - lastPlayerPos.y)

		end

	else 

		self.lookingAt = player:getPosition()
	end
end

-- Lets see some camera modes. 
WorldManager.cameraModes = {
	followPlayer = WorldManager.followPlayerWithCamera, -- 'free mode with tension'
	scrolling = WorldManager.snapToPlatforms, -- 'snap to platforms with smooth transitions, horizontally free with tension (ignores vertical tension)' -- requires stateType
	fading = WorldManager.snapToCeiling, -- 'snap to ceiling (?) (ignores vertical tension) '
	default = WorldManager.followPlayerWithCamera -- more modes can be added here "custom" modes with names. same for transitions
}

-----------------------------------------------------------------
-- Transitions
-----------------------------------------------------------------

function WorldManager:roomTransition(player, roomChange, mode)
	local transitionMode = mode or self.stage.roomTransitionMode
	local transition = WorldManager.transitions[transitionMode] or WorldManager.transitions["default"]
	transition(self, player, roomChange)
end

function WorldManager:fadingTransition(player, roomChange)
	local rampTime = 0.5
	local blackTime = 0.5

	self:pauseGame(2*rampTime + blackTime)
	self:fadeToColor(rampTime, {0, 0, 0, 255}, 5)
	Timer.add(rampTime + blackTime/2, 
		function () 
	    	player:moveIntoCollidingBox(roomChange.nextRoom.box)
	    	self.stage:changeToRoom(roomChange.nextRoom)
	    	self.camera:setWorld(self.stage:getBounds())
	    	
	    end)
	Timer.add(rampTime + blackTime, function () self:fadeToColor(rampTime, {255, 255, 255, 255}, 5) end )

end

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
			self.stage:changeToRoom(roomChange.nextRoom)
			self.camera:setPosition(nextCameraPos:unpack())
			player:moveTo(nextPlayerPos:unpack())
			self.camera:setWorld(self.stage:getBounds())
			self.currentCameraMovement = nil
		end )
end


function WorldManager:instantTransition(player, roomChange)
	player:moveIntoCollidingBox(roomChange.nextRoom.box)
	self.stage:changeToRoom(roomChange.nextRoom)
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
-----------------------------------------------------------------
function WorldManager:pauseGame(time)
	self.paused = true

	if time then 
		Timer.add(time, function() self.paused = false end )
	end

end

function WorldManager:unPauseGame()
	self.paused = false
end

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

return WorldManager