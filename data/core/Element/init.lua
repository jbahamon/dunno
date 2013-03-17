local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'


local GeometryUtils = require 'lib.GeometryUtils'
local shapes = require 'lib.HardonCollider.shapes'

local StateMachine = require 'data.core.StateMachine'
local ElementState = require 'data.core.Element.ElementState'

local Element = Class {

	name = 'Element',
	__includes = StateMachine,

	init =
		function (self, width, height)
			StateMachine.init(self)

		    self.defaultCollisionBox = shapes.newPolygonShape(
		    	- math.floor(width/2), 0,
		    	  math.ceil(width/2), 0,
		    	  math.ceil(width/2), - height,
		    	- math.floor(width/2), - height)

		    self.defaultCollisionBox.width = width
		    self.defaultCollisionBox.height = height
			self.defaultCollisionBox.color = {255, 255, 255, 255}
			self.currentCollisionBox = self.defaultCollisionBox

		    -- Collision flags
		    self.collisionFlags = { canMoveLeft = true,
				    				canMoveRight = true,
				    				canMoveUp = true,
				    				canMoveDown = true,
				    				specialEvents = {}}

			self.pendingCollisions = {}

		end	

}

function Element:setFolder(path)
	self.folder = path
end


function Element:getFolder(path)
	return self.folder
end

-----------------------------------------------------------------
-- Drawing
-----------------------------------------------------------------

function Element:setSpriteData(sprites, spriteSizeX, spriteSizeY, offset)
	self.spriteSizeX = spriteSizeX
	self.spriteSizeY = spriteSizeY
	self.sprites = love.graphics.newImage(sprites)
	self.sprites:setFilter('nearest', 'nearest')
	self.spritesGrid = anim8.newGrid(self.spriteSizeX,
                                         self.spriteSizeY,
                                         self.sprites:getWidth(),
                                         self.sprites:getHeight())

	self.spriteOffset = offset or vector(0,0)
end

function Element:draw()

	if self.currentState.draw then
		self.currentState:draw()
	end	

    if DEBUG then
        love.graphics.setColor(self.currentCollisionBox.color)
        self.currentCollisionBox:draw()
    end

end

-----------------------------------------------------------------
-- Positioning, dynamics
-----------------------------------------------------------------

function Element:move(dx, dy)
	self.currentCollisionBox:move(dx, dy)
	self.currentState:move(dx, dy)
end

function Element:moveTo(x, y)
	self.currentCollisionBox:moveTo(x, y - self.currentCollisionBox.height/2)
	self.currentState:moveTo(x, y)
end

function Element:setStartingPosition(x, y)
	self.startingPosition = vector(x, y)
end

function Element:getPosition()
	return self.currentState.dynamics.position
end

function Element:getLastPosition()
	return self.currentState.dynamics.oldPosition
end

function Element:getVelocity()
	return self.currentState.dynamics.velocity
end

function Element:center()
	return self.currentCollisionBox:center()
end

-----------------------------------------------------------------
-- State handling
-----------------------------------------------------------------

function Element:start()
	StateMachine.start(self)

	if self.currentState.collisionBox then
		self:setCollisionBox(self.currentState.collisionBox)
	else
		self:setCollisionBox(self.defaultCollisionBox)
	end

	self:moveTo(self.startingPosition:unpack())

end

function Element:checkStateChange()
	local currentState = self.currentState
	for _ , transition in ipairs(currentState.transitions) do
		if transition.condition(currentState, self.collisionFlags) then
			self:changeToState(self.states[transition.targetState])
			return
		end
	end
	
end

function Element:changeToState(nextState)
	local previousState = self.currentState

	StateMachine.changeToState(self, nextState)

	if self.currentState.collisionBox or
	 (previousState.collisionBox and (previousState.collisionBox ~= self.defaultCollisionBox)) then
		self:setCollisionBox(self.currentState.collisionBox or self.defaultCollisionBox)
	end

end

function Element:addState(state)
	if self.states[state.name] and self.states[state.name].collisionBox then
		self.activeCollider:remove(self.states[state.name])
		self.tileCollider:remove(self.states[state.name])
	end

	StateMachine.addState(self, state)

	if state.collisionBox then
		self.element.activeCollider:addShape(state.collisionBox)
		self.element.activeCollider:setGhost(state.collisionBox)
		self.element.tileCollider:addElement(state.collisionBox)
	end
end

function Element:removeState(stateName)

	if self.states[state.name] and self.states[state.name].collisionBox then
		self.activeCollider:remove(self.states[state.name])
		self.tileCollider:remove(self.states[state.name])
	end

	StateMachine.removeState(self, state)

end

-----------------------------------------------------------------
-- Collisions
-----------------------------------------------------------------

function Element:setColliders(tileCollider, activeCollider)
	if self.activeCollider then
		self.activeCollider:remove(self.currentCollisionBox)
	end

	if self.tileCollider then
		self.tileCollider:remove(self.currentCollisionBox)
	end

	self.tileCollider = tileCollider
	self.activeCollider = activeCollider
	
    self.activeCollider:addShape(self.defaultCollisionBox)
	self.tileCollider:addElement(self.defaultCollisionBox)

	if self.currentCollisionBox ~= self.defaultCollisionBox then
		self.activeCollider:setGhost(self.defaultCollisionBox)
		self.defaultCollisionBox.active = false
	end

end

function Element:moveIntoCollidingBox(box)
	local collisionBox = self:getCollisionBox()


	local collides, dx, dy = collisionBox:collidesWith(box)

	if not collides then
		return
	end

	local elementCenter = vector(self:center())
	local boxCenter = vector(box:center())

	local displacement, direction
	if math.abs(dx) > math.abs(dy) then

		if elementCenter.x < boxCenter.x then
			direction = 1
		else 
			direction = -1
		end

		displacement = vector((self.width - math.abs(dx)) + 1, 0)
	else

		if elementCenter.y < boxCenter.y then
			direction = 1
		else 
			direction = -1
		end

		displacement = vector(0, (self.height - math.abs(dy)) + 1)
	end

	self:move((displacement * direction):unpack())

end

function Element:resetCollisionFlags()
	self.collisionFlags.canMoveLeft = true
	self.collisionFlags.canMoveRight = true
	self.collisionFlags.canMoveUp = true
	self.collisionFlags.canMoveDown = true

	self.collisionFlags.specialEvents = {}
end


function Element:onTileCollide(dt, tileElement, tile, x, y)

	if tile.properties.solid or tile.properties.oneWayPlatform or tile.properties.ladder then
		
		local collisionEvent = { x = x, y = y, tile = tile }

		collisionEvent.area = GeometryUtils.getCollisionArea(tileElement, self:getCollisionBox())

		table.insert(self.pendingCollisions, collisionEvent)

	end

	-- Insert other collision types here. One-way platforms, ladders and
	-- slopes are the most relevant. Each one resolves and sets flags in
	-- their own way.

end

function Element:resolveTileCollisions(sampleTile, tileSize)

	table.sort(self.pendingCollisions, function(a, b)
											return a.area > b.area
										end)
	local collides, dx, dy
	local highestLadderEvent

	for idx, event in pairs(self.pendingCollisions) do
	-- FIXME - this should be improved

		sampleTile:moveTo(event.x * tileSize.x + tileSize.x/2.0,
						  event.y * tileSize.y + tileSize.y/2.0)

		collides, dx, dy = self.currentCollisionBox:collidesWith(sampleTile)

		if collides then

			if event.tile.properties.solid then 
				self:move(dx, dy)
				if math.abs(dx) > math.abs(dy) then
					if dx > 0 then 
						self.collisionFlags.canMoveLeft = false
					elseif dx < 0 then
						self.collisionFlags.canMoveRight = false
					end
				else
					if dy > 0 then 
						self.collisionFlags.canMoveUp = false
						self:getVelocity().y = math.max(self:getVelocity().y, 0)
					elseif dy < 0 then 
						self.collisionFlags.canMoveDown = false
					end
				end
			elseif event.tile.properties.oneWayPlatform then
				
				local verticalDisplacement = event.y * tileSize.y - self:getPosition().y
				
				if event.y * tileSize.y >= self:getLastPosition().y then
					self:move(0, verticalDisplacement)
					self.collisionFlags.canMoveDown = false
				end
			elseif event.tile.properties.ladder then
				if (not highestLadderEvent) or highestLadderEvent.y > event.y then
					highestLadderEvent = event
				end

				local centerX, centerY = self.currentCollisionBox:center()
				if sampleTile:intersectsRay(centerX, centerY, 0, -1) or
					sampleTile:intersectsRay(centerX, centerY, 0, 1) then

					if not self.collisionFlags.specialEvents.ladder then
						self.collisionFlags.specialEvents.ladder = { position = vector(sampleTile:center()), element = self}
					end
				end
			end	
		end

	end

				
	if highestLadderEvent and highestLadderEvent.y * tileSize.y >= self:getLastPosition().y then
		self:move(0, highestLadderEvent.y * tileSize.y - self:getPosition().y)
		self.collisionFlags.canMoveDown = false
		self.collisionFlags.specialEvents.standingOnLadder = self.collisionFlags.specialEvents.ladder
		self.collisionFlags.specialEvents.ladder = nil
	end

	self.pendingCollisions = {}

end

function Element:setCollisionBox(collisionBox)
	if self.currentCollisionBox then
		self.currentCollisionBox.active = false

		--this if should be removed
		if self.activeCollider then
			self.activeCollider:setGhost(self.currentCollisionBox)
		end

	end
	
	collisionBox:moveTo(self.currentState.dynamics.position.x,
					    self.currentState.dynamics.position.y - collisionBox.height/2)
	self.currentCollisionBox = collisionBox
	self.currentCollisionBox.parent = self
	self.currentCollisionBox.active = true

	local x1, y1, x2, y2 = collisionBox:bbox()

	self.width = x2 - x1
	self.height = y2 - y1

	--this if should be removed
	if self.activeCollider then
		self.activeCollider:setSolid(self.currentCollisionBox)
	end

end

function Element:getCollisionBox(collisionBox)
	return self.currentCollisionBox
end


function Element:disableTileCollisions()
	if self.currentCollisionBox then
		self.currentCollisionBox.active = false
	end
end


function Element:enableTileCollisions()
	if self.currentCollisionBox then
		self.currentCollisionBox.active = true
	end
end

function Element:getDefaultCollisionBox(collisionBox)
	return self.defaultCollisionBox
end

-----------------------------------------------------------------
-- Loading from File
-----------------------------------------------------------------

function Element:getDefaultStateClass()
	return ElementState
end

function Element:loadSpritesFromParams(parameters)

	------------------------------------
	-- Sprite Data
	------------------------------------

	assert(parameters.sprites,"No sprite info supplied")
	assert(parameters.sprites.sheet, "No spritesheet info supplied" )

	local folder = parameters.sprites.folder or self:getFolder()

	local sprites = folder .. "/" .. string.gsub(parameters.sprites.sheet, '[^%a%d-_/.]', '')

	assert(love.filesystem.isFile(sprites), "Spritesheet \'".. sprites .."\' supplied is not a file")	

	assert(parameters.sprites.spriteSizeX and parameters.sprites.spriteSizeY,
		"No sprite size supplied")

	self:setSpriteData(sprites, parameters.sprites.spriteSizeX, parameters.sprites.spriteSizeY)

end

function Element:loadStatesFromParams(parameters)

	------------------------------------
	-- States
	------------------------------------

	assert(parameters.states and type(parameters.states) == "table" and next(parameters.states) ~= nil,
		 "\'states\' parameter must not be empty.")

	local states = parameters.states
	local folder = states.folder or self:getFolder()

	------------------------------------
	-- Creating the States
	------------------------------------
	for stateName, stateParams in pairs(states) do
		self:addSingleStateFromParams(stateName, stateParams, folder)
	end

	assert(parameters.initialState and type(parameters.initialState) == "string" and self.states[parameters.initialState],
		"Must specify a valid initial state")

	self:setInitialState(parameters.initialState)
	
end

function Element:addSingleStateFromParams(stateName, stateParams, folder)
	local folder = folder or self:getFolder()

	assert(stateParams.dynamics, "Missing dynamics data for state \'".. stateName .."\'.")
	assert(stateParams.animation and stateParams.animation.mode and stateParams.animation.frames 
			and stateParams.animation.defaultDelay, "Missing animation data for state \'" .. stateName .. "\'.")

	local frames 

	if type(stateParams.animation.frames) == "table" then
		frames = self.spritesGrid(unpack(stateParams.animation.frames))
	else
		frames = self.spritesGrid(stateParams.animation.frames)
	end 

	local animation = anim8.newAnimation( stateParams.animation.mode, 
											self.spritesGrid(stateParams.animation.frames),
											stateParams.animation.defaultDelay,
											stateParams.animation.delays or {},
											stateParams.animation.flippedH or false,
											stateParams.animation.flippedV or false )


	local CustomState, newState

	if stateParams.class then
		local ok, classFile = pcall(love.filesystem.load, folder ..  '/' .. stateParams.class)
		assert(ok, "Element state class file has syntax errors: " .. tostring(classFile))
		CustomState = classFile()
	else
		CustomState = self:getDefaultStateClass()
	end

	local ok, dynamicsFile = pcall(love.filesystem.load, folder .. "/" .. stateParams.dynamics)
	
	assert(ok, "Character dynamics file has syntax errors: " .. tostring(dynamicsFile))

	local dynamics = dynamicsFile()

	newState = CustomState(stateName, dynamics, animation)

	self:addState(newState)

	if stateParams.transitions then
		for _, transition in ipairs(stateParams.transitions) do

			assert(transition.condition, "Transition condition not specified for state \'".. stateName .."\'")
			assert(transition.targetState, "Transition target not specified for state \'".. stateName .."\'")
			
			self.states[stateName]:addTransition(transition.condition, transition.targetState)
		end
	end


	if stateParams.flags then
		for _, flag in ipairs(stateParams.flags) do
			assert(type(flag) == "string", "Flag name must be a string, got \'".. tostring(flag) .."\'")
			self.states[stateName]:addFlag(flag)
		end
	end
end
--------------------------
-- STATIC FUNCTIONS
--------------------------
function Element.loadBasicFromParams(parameters, folder)

	assert(type(parameters) == "table", "Element configuration file must return a table")

	assert(parameters.size and parameters.size.width and parameters.size.height, "Element size not specified")

	local elem = Element(parameters.size.width, parameters.size.height)

	elem:setFolder(folder)

	return elem
end

return Element