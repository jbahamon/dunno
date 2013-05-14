
--- CameraManager implementation.
-- @class module
-- @name data.core.CameraManager


local Class = require 'lib.hump.class'

local Player = require 'data.core.Player'
local Stage = require 'data.core.Stage'
local ElementFactory = require 'data.core.ElementFactory'

local Camera = require 'lib.gamera'

local ActiveCollider = require 'lib.HardonCollider'
local TileCollider = require 'lib.TileCollider'

local vector = require 'lib.hump.vector'

local Timer = globals.Timer

--- Builds a new, empty CameraManager
-- @class function
-- @name CameraManager
-- @return The newly created CameraManager
local CameraManager = Class {
	name = "CameraManager",

	init = 
		function (self, players, stage, topLeft, bottomRight)
			self.players = players
			self.stage = stage

			self.topLeft = topLeft
			self.bottomRight = bottomRight

			self.camera = Camera.new(self.stage:getBounds())
			self.camera:setWindow(self.topLeft.x, 
								  self.topLeft.y, 
								  self.bottomRight.x - self.topLeft.x,
								  self.bottomRight.y - self.topLeft.y)	

			self.fullScreenTint = {255, 255, 255, 255}
			self.lookingAt = vector(0,0)
			self.camera:setScale(globals.scale)
		end

}



--- Class that handles the camera: room transitions, camera modes, fullscreen fading, etcetera.
-- @type CameraManager

-----------------------------------------------------------------
-- Basic camera functions
-- @section basics


--- Centers the camera on a given position.
-- @param position The position to center the camera on, as a vector.
function CameraManager:setPosition(position)
	self.camera:setPosition(position:unpack())
end

--- Draws everything the camera sees. 
-- The camera will draw the stage ands its elements first, and the players
-- on top of them.
-- @param players The players to draw on the stage, as an array.
function CameraManager:draw(players)

	love.graphics.setColor(self.fullScreenTint)
	self:setPosition(self.lookingAt)
	
	self.camera:draw(function (l, t, w, h)
   						self.stage:moveTo(vector(l, t))
						self.stage:draw()

						for i, player in ipairs(players) do
							player:draw()
							love.graphics.setColor(self.fullScreenTint)
						end

					end)
end

--- Sets the bounds of the camera. 
-- The camera will try to not draw anything beyond its bounds, adjusting its position adequately.
-- @param l The horizontal coordinate of the top-left corner of the camera's bounds.
-- @param t The vertical coordinate of the top-left corner of the camera's bounds.
-- @param w The width of the camera's bounds.
-- @param h The height of the camera's bounds.
function CameraManager:setWorld(l, t, w, h)
	self.camera:setWorld(l, t, w, h)
end

--- Starts the camera manager, centering the camera in its starting position.
function CameraManager:start()
	self.lookingAt = self.stage:getPixelStartingFocus()
end

function CameraManager:getVisible()
	local l, t, w, h = self.camera:getVisible()
	return vector(l, t), vector(l + w, t + h)
end
-----------------------------------------------------------------
-- Camera modes and centering
-- @section modes

--- Sets the point to where the camera should point to (i.e. the camera's focus).
-- The focus is set depending on the current camera mode.
-- @param players The players on the stage, as an array.
-- Currently, the camera manager tries to center itself around the first player in this array.
function CameraManager:updateCameraFocus(players) 
	local cameraMode = self.stage:getCameraMode() or { mode = "default" }
	local cameraFunction = CameraManager.cameraModes[cameraMode.mode]
	 or CameraManager.cameraModes["default"]

	cameraFunction(self, players[1], self.stage, cameraMode)
	
end

--- Scrolls the camera from the current position to a target position, with
-- the given speed.
-- @param speed The speed (in pixels/second) to give to the camera
-- @param pointB The target position (in pixels) for the camera.
-- @param postFunction (Optional) A function that receives no parameters, to be executed after the
-- scrolling finished.
function CameraManager:scrollCameraWithSpeed(speed, pointB, postFunction)
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
function CameraManager:scrollCameraWithTime(time, pointB, postFunction)
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
function CameraManager:followCameraMode(player, stage, cameraMode)

	local targetPosition = self.lookingAt:clone()

	if cameraMode.tension then
		local tension = cameraMode.tension

		local playerPos = player:getPosition()
		local lastPlayerPos = player:getLastPosition()
		
		-- horizontal following
		if playerPos.x > (targetPosition.x + tension.x) then
			targetPosition.x = playerPos.x - tension.x
		elseif playerPos.x < (targetPosition.x - tension.x) then 
			targetPosition.x = (playerPos.x + tension.x)
		end

		-- vertical following
		if playerPos.y > (targetPosition.y + tension.y) then
			targetPosition.y =  playerPos.y - tension.y
		elseif playerPos.y < (targetPosition.y - tension.y) then 
			targetPosition.y =  playerPos.y + tension.y
		end

	else 

		targetPosition = player:getPosition()
	end

	self.lookingAt = targetPosition

end

--- Camera mode that locks to a position in zero, one or more axes, 
-- and follows the given player in the remaining axes. It is not recommended to use this
-- mode if you're aiming to follow the player in both axes: followPlayer (and by extension
--	@{CameraManager:followCameraMode}) is more efficient and achieves this.
-- @param player The player to follow.
-- @param stage The world's stage.
-- @param cameraMode The cameraMode parameters. Check the stage documentation to see 
-- the details on this parameter.
function CameraManager:lockCameraMode(player, stage, cameraMode)
	local targetPosition

	-- if we have to follow the player in one direction, then we do that first
	if not (cameraMode.verticalLock and cameraMode.horizontalLock) then 
		self:followCameraMode(player, stage, cameraMode)
	end

	targetPosition = self.lookingAt:clone()

	if cameraMode.horizontalLock then
		targetPosition.x = cameraMode.horizontalLock * self.stage.tileSize.x
	end

	if cameraMode.verticalLock then
		targetPosition.y = cameraMode.verticalLock * self.stage.tileSize.y
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
function CameraManager:platformCameraMode(player, stage, cameraMode)

	local tension = cameraMode.tension or vector(0, 0)

	local playerPos = player:getPosition()
	local lastPlayerPos = player:getLastPosition()

	local targetPosition = self.lookingAt:clone()

	-- horizontal following

	if playerPos.x > (targetPosition.x + tension.x) then
		targetPosition.x = playerPos.x - tension.x
	elseif playerPos.x < (targetPosition.x - tension.x) then 
		targetPosition.x = (playerPos.x + tension.x)
	end


	--vertical following
	if playerPos.y > (targetPosition.y + tension.y) then
		targetPosition.y =  playerPos.y - tension.y
	elseif playerPos.y < (targetPosition.y - tension.y) then 
		targetPosition.y =  playerPos.y + tension.y
	end

	self.lookingAt.x = targetPosition.x

	
	-- Snapping to a platform. We only snap to the platform if the player gets to a higher platform.
	-- This is the behavior observed in Super Mario World's "Yoshi's Island 3" stage.

	-- First, we check if we are standing on something
	if player:getStateFlags()["grounded"] and not cameraMode._scrolling then
		
		local oldLock = cameraMode.verticalLock	or math.floor(playerPos.y /  self.stage.tileSize.y)

		cameraMode.verticalLock = math.floor(playerPos.y /  self.stage.tileSize.y)

		if cameraMode.verticalLock < oldLock then

			targetPosition.y = cameraMode.verticalLock * self.stage.tileSize.y

			self:scrollCameraWithSpeed(cameraMode.snapSpeed,
										targetPosition,
										function() 
											cameraMode._scrolling = nil
										end)

			cameraMode._scrolling = self.currentCameraMovement
		end
	elseif targetPosition.y > self.lookingAt.y then
		self.lookingAt.y = targetPosition.y
		if self.currentCameraMovement then
			Timer.cancel(self.currentCameraMovement)
		end
	end

end

CameraManager.cameraModes = {
	followPlayer = CameraManager.followCameraMode, -- 'free mode with tension'
	lock = CameraManager.lockCameraMode, -- 'snap to platforms with smooth transitions, horizontally free with tension (ignores vertical tension)' -- requires stateType
	snapToPlatform = CameraManager.platformCameraMode, -- 'snap to ceiling (?) (ignores vertical tension) '
	default = CameraManager.followCameraMode -- more modes can be added here "custom" modes with names. same for transitions
}

-----------------------------------------------------------------
-- Room Transitions
-- @section transitions

--- Executes a transition between two rooms, moving the camera as needed.
-- @param player The player that will transition between rooms.
-- @param roomChange The room transition parameters. It includes two fields: previousRoom and nextRoom.
-- A room includes a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (specifically, a rectangle) that represents the room and a tags dictionary
-- @param worldManager The WorldManager that manages the world the CameraManager belongs to.
-- @param mode The transition mode. If there isn't a transition mode with this name, 
-- the transition uses the default mode.
function CameraManager:roomTransition(player, roomChange, worldManager, mode)
	local transitionMode = mode or self.stage.roomTransitionMode
	local transition = CameraManager.transitions[transitionMode] or CameraManager.transitions["default"]

	transition(self, player, roomChange, worldManager)
end

--- A transition that fades the screen to black and back as the player switches rooms.
-- @param player The player that will transition between rooms.
-- @param roomChange The room transition parameters. It includes two fields: previousRoom and nextRoom.
-- @param worldManager The WorldManager that manages the world the CameraManager belongs to.
-- Each includes a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (specifically, a rectangle) that represents the room and a tags dictionary
function CameraManager:fadingTransition(player, roomChange, worldManager)
	local rampTime = 0.5
	local blackTime = 0.5

	worldManager:pauseGame(2*rampTime + blackTime)
	self:fadeToColor(rampTime, {0, 0, 0, 255}, 5)
	Timer.add(rampTime + blackTime/2, 
		function () 
	    	player:moveIntoCollidingBox(roomChange.nextRoom.box)
	    	self.stage:setRoom(roomChange.nextRoom)
	    	self.camera:setWorld(self.stage:getBounds())
	    end,
	    function ()
	    	self:updateCameraFocus({player}) 
	    end)
	Timer.add(rampTime + blackTime, function () self:fadeToColor(rampTime, {255, 255, 255, 255}, 5) end )

end

--- A transition that scrolls both the player and the camera to the next room.
-- @param player The player that will scroll between rooms.
-- @param roomChange The room transition parameters. It includes two fields: previousRoom and nextRoom.
-- @param worldManager The WorldManager that manages the world the CameraManager belongs to.
-- Each includes a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (specifically, a rectangle) that represents the room and a tags dictionary
function CameraManager:scrollTransition(player, roomChange, worldManager)
	local scrollTime = 1.5
	local prevPlayerPos, prevCameraPos
	local nextPlayerPos, nextCameraPos

	-- We get the previous positions
	prevPlayerPos = player:getPosition():clone()

	-- We move both the player and the camera to the next room.

	--print(roomChange.previousRoom)
	x1, y1, x2, y2 = roomChange.nextRoom.box:bbox()
	self:setWorld(x1, y1, x2 - x1, y2 - y1)
	player:moveIntoCollidingBox(roomChange.nextRoom.box)

	self:setPosition(player:getPosition())

	-- We get the after-transition positions
	nextCameraPos = vector(self.camera:getVisible())
	nextPlayerPos = player:getPosition():clone()

	-- We revert the changes
	x1, y1, x2, y2 = roomChange.previousRoom.box:bbox()

	self:setWorld(x1, y1, x2 - x1, y2 - y1)
	player:moveTo(prevPlayerPos)
	self:setPosition(player:getPosition())
	prevCameraPos = vector(self.camera:getVisible())

	local playerVelocity = (nextPlayerPos - prevPlayerPos)/scrollTime
	local cameraVelocity = (nextCameraPos - prevCameraPos)/scrollTime

	worldManager:pauseGame(scrollTime)

	if self.currentCameraMovement then
		Timer.cancel(self.currentCameraMovement)
	end

	self.currentCameraMovement = Timer.do_for( scrollTime, 
		function (dt) 
			local l, t, w, h
			player:move(playerVelocity * dt)
			player.currentState.animation:update(dt)
			l, t, w, h = self.camera:getVisible()

			self.camera:setWorld( l + cameraVelocity.x * dt,
								  t + cameraVelocity.y * dt,
								  w,
								  h)
		end,
		function()
			self.stage:setRoom(roomChange.nextRoom)
			self:setWorld(self.stage:getBounds())
			self:setPosition(nextCameraPos)
			player:moveTo(nextPlayerPos)
			self.currentCameraMovement = nil
		end )

end

--- A simple room transition that teleports the player and the camera to the next room.
-- @param player The player that will scroll between rooms.
-- @param roomChange The room transition parameters. It includes two fields: previousRoom and nextRoom.
-- @param worldManager The WorldManager that manages the world the CameraManager belongs to.
-- Each includes a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (specifically, a rectangle) that represents the room and a tags dictionary
function CameraManager:instantTransition(player, roomChange, worldManager)
	player:moveIntoCollidingBox(roomChange.nextRoom.box)
	self.stage:setRoom(roomChange.nextRoom)
	self.camera:setWorld(self.stage:getBounds())
	self:updateCameraFocus({player}) 
end

CameraManager.transitions = {
	none = CameraManager.instantTransition,
	scrolling = CameraManager.scrollTransition,
	fading = CameraManager.fadingTransition,
	default = CameraManager.instantTransition
}


-----------------------------------------------------------------
-- Screen effects (fading, etcetera).
-- @section effects

--- Fades the screen to a solid tint. 
-- @param rampTime The time (in seconds) for the screen to get to the tint's full intensity.
-- @param color The color to apply to all elements, as an array (not a dictionary) of four values,
-- corresponding to red, green, blue, and alpha, in that order.
-- @param numSteps (Optional) The number of steps for the ramp. Use this to give the fading a "retro" look, 
-- having discrete intermediate values. If omitted, the transition is done as smoothly as possible.
function CameraManager:fadeToColor(rampTime, color, numSteps)

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
return CameraManager