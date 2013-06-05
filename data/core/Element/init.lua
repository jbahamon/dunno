--- A game element implementation.
-- @class module
-- @name data.core.Element

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'

local GeometryUtils = require 'lib.GeometryUtils'
local shapes = require 'lib.HardonCollider.shapes'

local StateMachine = require 'data.core.StateMachine'
local ElementState = require 'data.core.Element.ElementState'

--- Builds a new Element with a collision box and no states.
-- @class function
-- @name Element
-- @param size The size of the Element's collision box, as a vector, in pixels.
-- @return The newly created Element.

local Element = Class {

	name = 'Element',
	__includes = StateMachine,

}

function Element:init(size)
	StateMachine.init(self)

	self.helperAnimations = {}

    self.defaultCollisionBox = shapes.newPolygonShape(
    	- math.floor(size.x/2), 0,
    	  math.ceil(size.x/2), 0,
    	  math.ceil(size.x/2), - size.y,
    	- math.floor(size.x/2), - size.y)

	self.currentCollisionBox = self.defaultCollisionBox
	self.currentCollisionBox.parent = self

	local x1, y1, x2, y2 = self.currentCollisionBox:bbox()
	self.size = vector(x2 - x1, y2 - y1)

    -- Collision flags
    self.collisionFlags = { canMoveLeft = true,
		    				canMoveRight = true,
		    				canMoveUp = true,
		    				canMoveDown = true,
		    				specialEvents = {}}

	self.pendingCollisions = {}

	self:setStartingPosition(vector(0, 0))

	self.drawTimer = 0
end	


--===============================================================
-- STATIC FUNCTIONS
--===============================================================


--- Creates a minimal Element from a parameter table.
-- See the parameter specification (TODO!) for details of building an Element from a set of parameters.
-- @param parameters The parameter table.
-- @param folder The folder where the Element's parameters are found.
-- @return The newly created Element.
function Element.loadBasicFromParams(parameters, folder)

	assert(type(parameters) == "table", "Element configuration file must return a table")

	assert(parameters.size, "Element size not specified")

	local elem

	if parameters.class then 
		local ok, classFile = pcall(love.filesystem.load, folder ..  '/' .. parameters.class)
		assert(ok, "Element state class file has syntax errors: " .. tostring(classFile))
		elem = classFile()(parameters.size)

	else
		elem = Element(parameters.size)
	end

	if parameters.helperAnimations then
		for name, helper in pairs(parameters.helperAnimations) do
			local newAnimation = {}

			newAnimation.sprites = love.graphics.newImage( folder .. '/' .. helper.sprites.sheet )
			newAnimation.sprites:setFilter('nearest', 'nearest')
			newAnimation.spriteSize = helper.sprites.spriteSize

			newAnimation.grid = anim8.newGrid(newAnimation.spriteSize.x,
                                newAnimation.spriteSize.y,
                                newAnimation.sprites:getWidth(),
                                newAnimation.sprites:getHeight())

			local frames

			if type(helper.animation.frames) == 'table' then
				frames = newAnimation.grid(unpack(helper.animation.frames))
			else
				frames = newAnimation.grid(helper.animation.frames)
			end

			newAnimation.animation = anim8.newAnimation( helper.animation.mode, 
											frames,
											helper.animation.defaultDelay,
											helper.animation.delays or {},
											helper.animation.flippedH or false,
											helper.animation.flippedV or false )
				
			elem.helperAnimations[name] = newAnimation
		end
	end
	
	elem:setFolder(folder)

	return elem
end

--- A game element implementation.  Extends @{data.core.StateMachine|StateMachine}.
-- Every dynamic element of a stage (players, enemies, interactive objects) is an Element
-- or inherits from this class. An Element's position is considered to be its feet's position 
-- (bottom-center). Elements are animated using <a href="https://github.com/kikito/anim8/">anim8</a>.
-- They're also collidable: every Element has an active collision box (a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape; in particular, a rectangle) at all times.
-- They can optionally have a hit box, representing an attack.
-- Finally, Elements are dynamic. Their dynamics depend on their current state.
-- @type Element

--- Gets the folder from where the Element may load parameters.
-- @see Element:loadSpritesFromParams, Element:loadStatesFromParams
-- @return The Element's folder path.
function Element:getFolder()
	return self.folder
end

--- Sets the folder from where the Element may load parameters.
-- @see Element:loadSpritesFromParams, Element:loadStatesFromParams
-- @param path The folder path to assign.
function Element:setFolder(path)
	self.folder = path
end


-----------------------------------------------------------------
--- Positioning, dynamics
-- @section loldrawing

--- Moves the Element by a certain amount, in pixels.
-- The same displacement is applied Element's collision box.
-- @param displacement The displacement to be applied, as a hump vector, in pixels.
function Element:move(displacement)
	if self.currentHitBox then
		self.currentHitBox:move(displacement:unpack())
	end

	self.currentCollisionBox:move(displacement:unpack())
	self.currentState:move(displacement)
end

--- Moves the Element to a given location, in pixels.
-- The Element's collision box is moved so that the Element's
-- new position lies at the bottom-center of the collision box.
-- @param newPosition The target position, as a hump vector, in pixels.
function Element:moveTo(newPosition)
	local x1, y1, x2, y2 = self.currentCollisionBox:bbox()

	self.currentCollisionBox:moveTo(newPosition.x, newPosition.y - (y2 - y1)/2)

	if self.currentHitBox then
		self.currentHitBox:moveTo((self.currentHitBox.offset + newPosition - vector(0, (y2 - y1)/2)):unpack())
	end

	self.currentState:moveTo(newPosition)
end

--- Sets the Element's starting position, in pixels. The Element is NOT moved to this position;
-- instead, it will be moved when @{Element:start} is called.
-- @param startingPosition The starting position, as a vector, in pixels.
function Element:setStartingPosition(startingPosition)
	self.startingPosition = startingPosition:clone()
end

--- Turns the element around.
function Element:turn()
	self.currentState:turn()
end

--- Returns the Element's current position, in pixels.
-- @return The Element's position, as a vector.
function Element:getPosition()
	return self.currentState.dynamics.position
end

--- Returns the Element's position from the last frame, in pixels.
-- @return The Element's position from the last frame, as a vector.
function Element:getLastPosition()
	return self.currentState.dynamics.oldPosition
end

--- Returns the Element's velocity, in pixels/second.
-- @return The Element's position from the last frame, as a vector.
function Element:getVelocity()
	return self.currentState.dynamics.velocity
end

--- Returns the Element's facing. 
-- @return The Element's facing. A facing > 0 indicates right; < 0 indicates left.
function Element:getFacing()
	return self.currentState.facing
end

--- Returns the center of the Element's collision box, in pixels.
-- @return The center's position, as a vector.
function Element:center()
	return vector(self.currentCollisionBox:center())
end

function Element:update(dt)
	StateMachine.update(self, dt)
	self.drawTimer = (self.drawTimer + 60 * dt) % 60

end

-----------------------------------------------------------------
-- Drawing
-- @section drawing

--- Sets the Element's sprite data for it to be drawn.
-- @param sprites The sprite sheet image, as loaded by love.graphics.newImage.
-- Sprites in the sheet must be arranged in a grid where every cell must have the same size.
-- @param spriteSize The size of a sprite's cell in the sheet, as a hump vector, in pixels.
-- @param offset The sprites' offset, as a vector, in pixels. 
function Element:setSpriteData(sprites, spriteSize, offset)
	self.spriteSize = spriteSize:clone()
	self.sprites = love.graphics.newImage(sprites)
	self.sprites:setFilter('nearest', 'nearest')
	self.spritesGrid = anim8.newGrid(self.spriteSize.x,
                                         self.spriteSize.y,
                                         self.sprites:getWidth(),
                                         self.sprites:getHeight())

	if offset then
		self.spriteOffset = offset:clone()
	else
		self.spriteOffset = vector(0,0)
	end
end

--- Draws the Element's current animation. If globals.DEBUG is set to <i>true</i>, 
-- The collision box is drawn over the Element's sprite.
function Element:draw()

	if self.hittable or math.floor(self.drawTimer) % 4 ~= 0 then
		if self.currentState.draw then
			self.currentState:draw()
		end	
	end
end

-----------------------------------------------------------------
-- State handling
-- @section state

--- Starts the Element.
-- In particular, sets the initial state, the initial collision box, and moves the Element 
-- to its initial position.
-- @see Element:setStartingPosition
function Element:start()
	StateMachine.start(self)

	if self.currentState.collisionBox then
		self:setCollisionBox(self.currentState.collisionBox)
	else
		self:setCollisionBox(self.defaultCollisionBox)
	end

	self.hittable = true

	if self.currentState.hitBox then
		self:setHitBox(self.currentState.hitBox)
	else
		self:setHitBox(self.defaultHitBox)
	end

	self.currentState.dynamics.oldPosition = self.startingPosition:clone()
	self:moveTo(self.startingPosition)

end

--- Checks for conditions and executes any possible state change.
-- If two or more transitions are possible, the one with higher priority
-- is taken (or the one that was added first, if there is more than one transition with the
--	same priority).
-- Element conditions can use an additional parameter: the collision flags.
-- @see Element:changeToState
function Element:checkStateChange()
	local currentState = self.currentState
	for _ , transition in ipairs(currentState.transitions) do
		if transition.condition(currentState, self.collisionFlags) then
			self:changeToState(self.states[transition.targetState])
			return
		end
	end
end

--- Executes a transition to a specified state.
-- The current state's onExitTo and the target state's onEnterFrom
-- are executed, if found. The Element's collision box is adjusted if the next
-- state has a different box from the current one.
-- @param nextState The target state.
function Element:changeToState(nextState)
	local previousState = self.currentState

	StateMachine.changeToState(self, nextState)

	if self.currentState.collisionBox or
	 (previousState.collisionBox and (previousState.collisionBox ~= self.defaultCollisionBox)) then
		self:setCollisionBox(self.currentState.collisionBox or self.defaultCollisionBox)
		local x1, y1, x2, y2 = self.currentCollisionBox:bbox()
		self.size = vector(x2 - x1, y2 - y1)
	end

end

--- Adds a state to the Element. 
-- A state can only belong to a single machine at a time: it should not belong 
-- to another state machine when this method is called. 
-- Call @{Element:removeState} on the other machine first.
-- If the new state has a collision box, its information is added to the Element's
-- collider.
-- @param state The state to be added.
function Element:addState(state)

	StateMachine.addState(self, state)

	if state.collisionBox then
		self.activeCollider:addShape(state.collisionBox)
		self.activeCollider:setGhost(state.collisionBox)
		self.tileCollider:addElement(state.collisionBox)
	end

	if state.hitBox then
		self.activeCollider:addShape(state.hitBox)
		self.activeCollider:setGhost(state.hitBox)
		self.tileCollider:addElement(state.hitBox)
	end
end


--- Removes a state from the machine, leaving it with no owner.
-- If the state had a collision box, it will be removed from the colliders.
-- Therefore, it is NOT recommended to use the same collision box in different
-- Elements: use copies instead.
-- @param stateName The name of the state to be removed. If there is no state 
-- with such name in the machine, nothing is done.
function Element:removeState(stateName)
	if self.states[stateName] then
		if self.states[stateName].collisionBox then
			self.activeCollider:remove(self.states[stateName].collisionBox)
			self.tileCollider:remove(self.states[stateName].collisionBox)
		end

		if self.states[stateName].hitBox then
			self.activeCollider:remove(self.states[stateName].hitBox)
			self.tileCollider:remove(self.states[stateName].hitBox)
		end
	end

	StateMachine.removeState(self, stateName)

end

-----------------------------------------------------------------
-- Collisions
-- @section collision

--- Sets the colliders for this Element, adding every collision box
-- (the default collision box and the states' collision boxes, if any) to them.
-- @param tileCollider The tileCollider to set.
-- @param activeCollider The activeCollider to set.
function Element:setColliders(tileCollider, activeCollider)

	-- If we had colliders, we remove ourselves from them.
	if self.activeCollider then
		self.activeCollider:remove(self.currentCollisionBox)
		for _, state in pairs(self.states) do
			if state.collisionBox then
				self.activeCollider:remove(state.collisionBox)
			end

			if state.hitBox then
				self.activeCollider:remove(state.hitBox)
			end
		end
	end

	if self.tileCollider then
		self.tileCollider:remove(self.currentCollisionBox)
		for _, state in pairs(self.states) do
			if state.collisionBox then
				self.tileCollider:remove(state.collisionBox)
			end

			if state.collisionBox then
				self.tileCollider:remove(state.hitBox)
			end
		end
	end

	-- We assign the colliders...
	self.tileCollider = tileCollider
	self.activeCollider = activeCollider

	-- We add the default box...
    self.activeCollider:addShape(self.defaultCollisionBox)
    
    -- TODO: When should an element be passive?
    if false then 
    	self.activeCollider:setPassive(self.defaultCollisionBox)
    end

	self.tileCollider:addElement(self.defaultCollisionBox)

	if self.currentCollisionBox ~= self.defaultCollisionBox then
		self.activeCollider:setGhost(self.defaultCollisionBox)
		self.defaultCollisionBox.active = false
	end


	-- And we add the states' boxes.
	for _, state in pairs(self.states) do
		if state.collisionBox then
			self.activeCollider:addShape(state.collisionBox)
			self.activeCollider:setPassive(state.collisionBox)
			self.tileCollider:addElement(state.collisionBox)
			state.collisionBox.active = true

			if self.currentCollisionBox ~= state.collisionBox then
				self.activeCollider:setGhost(state.collisionBox)
				state.collisionBox.active = false
			end	
		end

		if state.hitBox then
			self.activeCollider:addShape(state.hitBox)
			self.tileCollider:addElement(state.hitBox)
			state.collisionBox.active = true

			if self.currentHitBox ~= state.hitBox then
				self.activeCollider:setGhost(state.hitBox)
				state.hitBox.active = false
			end
		end
	end

end

--- Moves the Element into a colliding box.
-- The movement is performed in the axis with the smallest distance to the target 
-- box. Useful for room transitions, for example.
-- @param box The collision box to move the Element into.
function Element:moveIntoCollidingBox(box)
	local collisionBox = self:getCollisionBox()
	local collides, dx, dy = collisionBox:collidesWith(box)

	if not collides then
		return
	end

	local elementCenter = self:center()
	local boxCenter = vector(box:center())

	local displacement, direction
	if math.abs(dx) > math.abs(dy) then

		if elementCenter.x < boxCenter.x then
			direction = 1
		else 
			direction = -1
		end

		displacement = vector((self.size.x - math.abs(dx)) + 1, 0)
	else

		if elementCenter.y < boxCenter.y then
			direction = 1
		else 
			direction = -1
		end

		displacement = vector(0, (self.size.y - math.abs(dy)) + 1)
	end

	self:move(displacement * direction)

end


--- Resets the Element's collision flags. 
function Element:resetCollisionFlags()
	self.collisionFlags = {
		canMoveLeft = true,
		canMoveRight = true,
		canMoveUp = true,
		canMoveDown = true,
		specialEvents = {}
	}

	self.pendingCollisions = {}
end

--- Called when colliding with a tile from the stage's collision layer. 
-- Essentially, adds the collision event to the pendingCollisions field.
-- This function should not be overriden; if you want to implement your own collision
-- resolution for tiles, override @{Element:resolveTileCollisions}.
-- @param dt The time slice for the collision frame.
-- @param tileElement A sample tile that can be used to recreate the collision (should be removed).
-- @param tile The tile Element with which the Element is colliding.
-- @param position The position of the colliding tile, measured in tiles, as a hump vector.
-- @see Element:resolveTileCollisions, Element:resetCollisionFlags
function Element:onTileCollide(dt, tileElement, tile, position)

	if tile.properties.solid or tile.properties.oneWayPlatform or tile.properties.ladder then
		
		local collisionEvent = { position = position:clone(), tile = tile }

		collisionEvent.area = GeometryUtils.getCollisionArea(tileElement, self:getCollisionBox())

		table.insert(self.pendingCollisions, collisionEvent)

	end
end

--- Resolves collisions with tiles.
-- Iterates over the registered collision events and resolves them appropriately.
-- This function can be overriden to implement custom tile collision resolution.
-- @param sampleTile A tile of the appropriate size that can be moved around to simulate 
-- the collisions.
-- @param tileSize A vector that contains the size of the stage's tiles, in pixels.
-- @see Element:onTileCollide, Element:resetCollisionFlags
function Element:resolveTileCollisions(sampleTile, tileSize)

	table.sort(self.pendingCollisions, function(a, b)
											return a.area > b.area
										end)
	local collides, dx, dy
	local highestLadderEvent

	for idx, event in pairs(self.pendingCollisions) do
	-- FIXME - this should be improved

		sampleTile:moveTo((event.position:permul(tileSize) + tileSize/2.0):unpack())

		collides, dx, dy = self.currentCollisionBox:collidesWith(sampleTile)

		if collides then

			if event.tile.properties.ladder then
				if (not highestLadderEvent) or highestLadderEvent.position.y > event.position.y then
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

			if event.tile.properties.solid then 

				self:move(vector(dx, dy))
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

				local centerX, centerY = self.currentCollisionBox:center()

				if sampleTile:intersectsRay(centerX, centerY, 0, 200) then
					self.collisionFlags.standingOnSolid = true
				end

			elseif event.tile.properties.oneWayPlatform then
				
				local verticalDisplacement = event.position.y * tileSize.y - self:getPosition().y
				
				if event.position.y * tileSize.y >= self:getLastPosition().y then
					self:move(vector(0, verticalDisplacement))
					self.collisionFlags.canMoveDown = false

					local centerX, centerY = self.currentCollisionBox:center()

					if sampleTile:intersectsRay(centerX, centerY, 0, 200) then
						self.collisionFlags.standingOnSolid = true
					end
				end
			end
			
			
		end
	end
				
	if highestLadderEvent and highestLadderEvent.position.y * tileSize.y >= self:getLastPosition().y then
		self:moveTo(vector(self:getPosition().x, highestLadderEvent.position.y * tileSize.y))
		self.collisionFlags.canMoveDown = false
		self.collisionFlags.specialEvents.standingOnLadder = self.collisionFlags.specialEvents.ladder
		self.collisionFlags.specialEvents.ladder = nil
	end

end

--- Called when colliding with an active Element in the world (interactive element, enemy, etc).
-- Currently calls getHitBy on the other Element if this Element damages on contact.
-- @param dt The time slice for the collision frame.
-- @param box This Element's colliding box.
-- @param otherElement The Element that is colliding with this one.
function Element:onDynamicCollide(dt, box, otherElement)
	if otherElement == self then
		return
	end

	if self.hitBox == box then
		otherElement.collisionFlags["hit"] = true
	end

	if self.currentCollisionBox == box and 
		self.currentState.dynamics.damagesOnContact then
		otherElement:getHitBy(self)
	end
end

--- Called when damaged by another element. Life reduction, transformations and death should 
-- be dealt with in this method.
-- @param otherElement The Element hitting this one.
-- @see ElementState:getHitBy
function Element:getHitBy(otherElement)
	if not self.hittable then
		return
	end

	self.currentState:getHitBy(otherElement)

	self.collisionFlags["hit"] = true
end

--- Sets the current collision box for the Element.
-- @param collisionBox The collision box to set, a 
-- <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (in particular, a rectangle).
-- It must have been added to this Element's collider
-- (for example, by belonging to a state and having called @{Element:addState})
-- and must not be active.
-- @see Element:getCollisionBox
function Element:setCollisionBox(collisionBox)
	if self.currentCollisionBox then
		self.currentCollisionBox.active = false
		self.activeCollider:setGhost(self.currentCollisionBox)
	end
	
	local x1, y1, x2, y2 = collisionBox:bbox()
	
	self.size = vector(x2 - x1, y2 - y1)

	collisionBox:moveTo((self.currentState.dynamics.position - vector(0, self.size.y/2)):unpack())
	self.currentCollisionBox = collisionBox
	self.currentCollisionBox.parent = self
	self.currentCollisionBox.active = true
	self.activeCollider:setSolid(self.currentCollisionBox)

end

--- Sets the current hit box for the Element.
-- @param hitBox The hit box to set, a 
-- <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (in particular, a rectangle).
-- It must have been added to this Element's collider
-- (for example, by belonging to a state and having called @{Element:addState})
-- and must not be currently active.
function Element:setHitBox(hitBox)

	if self.currentHitBox then
		self.currentHitBox.active = false
		self.activeCollider:setGhost(self.currentHitBox)
	end

	if hitBox then
	
		hitBox:moveTo((self.currentState.dynamics.position + hitBox.offset):unpack())
		hitBox.parent = self
		hitBox.active = true
		self.activeCollider:setSolid(hitBox)
	end

	self.currentHitBox = hitBox
end


--- Returns the Element's current collision box.
-- @return The current collision box, as a 
-- <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (in particular, a rectangle).
-- @see Element:setCollisionBox
function Element:getCollisionBox()
	return self.currentCollisionBox
end


--- Disables the Element's collisions against tiles.
-- @see Element:enableTileCollisions
function Element:disableTileCollisions()
	if self.currentCollisionBox then
		self.currentCollisionBox.active = false
	end
end

--- Enables the Element's collisions against tiles.
-- @see Element:disableTileCollisions
function Element:enableTileCollisions()
	if self.currentCollisionBox then
		self.currentCollisionBox.active = true
	end
end

--- Returns the Element's default collision box.
-- @return The default collision box, as a 
-- <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (in particular, a rectangle).
function Element:getDefaultCollisionBox(collisionBox)
	return self.defaultCollisionBox
end

-----------------------------------------------------------------
-- Loading from parameters
-- @section loadfromparams

--- Returns the Element's default state class (a <a href="http://vrld.github.com/hump/#hump.class"> hump class</a>).
-- This method is used when building an Element from a file, to determine the class used when no state class is specified.
-- For an Element, it's ElementState; override this method if you want to create a character with a custom base state.
-- @return The hump class to be used in the construction of this Element's states when no class is specified.
function Element:getDefaultStateClass()
	return ElementState
end


--- Loads sprite info (sprite sheet and sprite size) from a parameter table.
-- See the parameter specification (TODO!) for details of building an Element from a set of parameters.
-- @param parameters The parameter table.
-- @see Element:loadStatesFromParams, Element:addSingleStateFromParams
function Element:loadSpritesFromParams(parameters)

	--==================================
	-- Sprite Data
	--==================================

	assert(parameters.sprites,"No sprite info supplied")
	assert(parameters.sprites.sheet, "No spritesheet info supplied" )

	local folder = parameters.sprites.folder or self:getFolder()

	local sprites = folder .. "/" .. string.gsub(parameters.sprites.sheet, '[^%a%d-_/.]', '')

	assert(love.filesystem.isFile(sprites), "Spritesheet \'".. sprites .."\' supplied is not a file")	

	assert(parameters.sprites.spriteSize and vector.isvector(parameters.sprites.spriteSize),
		"No sprite size supplied")

	self:setSpriteData(sprites, parameters.sprites.spriteSize, parameters.sprites.spriteOffset)

end

--- Creates and adds states from a parameter table.
-- See the parameter specification (TODO!) for details of building an Element from a set of parameters.
-- @param parameters The parameter table.
-- @see Element:addSingleStateFromParams, Element:loadSpritesFromParams
function Element:loadStatesFromParams(parameters)

	--==================================
	-- States
	--==================================

	assert(parameters.states and type(parameters.states) == "table",
		 "\'states\' parameter must not be empty.")

	local states = parameters.states
	local folder = states.folder or self:getFolder()

	--==================================
	-- Creating the States
	--==================================
	for stateName, stateParams in pairs(states) do
		self:addSingleStateFromParams(stateName, stateParams, folder)
	end

	assert(parameters.initialState and type(parameters.initialState) == "string" and self.states[parameters.initialState],
		"Must specify a valid initial state")

    if (parameters.transitions) then
        self:addTransitionsFromParams(parameters.transitions)
    end

	self:setInitialState(parameters.initialState)
	
end

--- Creates and adds a single state from a parameter table.
-- See the parameter specification (TODO!) for details of building an Element from a set of parameters.
-- @param stateName The name to give to the new state.
-- @param stateParams The parameter table.
-- @param folder (Optional) the specific folder to load the state from. If omitted, the Element's folder is used.
-- @see Element:loadStatesFromParams, Element:loadSpritesFromParams
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
											frames,
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

	newState = CustomState(stateName, animation, dynamics)

	self:addState(newState)

	if stateParams.flags then
		for _, flag in ipairs(stateParams.flags) do
			assert(type(flag) == "string", "Flag name must be a string, got \'".. tostring(flag) .."\'")
			self.states[stateName]:addFlag(flag)
		end
	end
end

--- Creates and adds transition from a parameter table.
-- See the parameter specification (TODO!) for details of building an Element from a set of parameters.
-- @param parameters The parameter table.
function Element:addTransitionsFromParams(transitions)
	for _, transition in ipairs(transitions) do
		assert(transition.from, "Transition origin not specified in parameters.")
		assert(transition.condition, "Transition condition not specified in parameters.")
		assert(transition.to, "Transition target not specified in parameters.")
		
		if type(transition.from) == "string" then
			self.states[transition.from]:addTransition(transition.condition, transition.to)
		elseif type(transition.from) == "table" then
			for _, fromState in ipairs(transition.from) do
				self.states[fromState]:addTransition(transition.condition, transition.to)
			end
		end
	end
end

function Element:destroySelf()

	self.tileCollider:remove(self.defaultCollisionBox)
	self.activeCollider:remove(self.defaultCollisionBox)
	for name, state in pairs(self.states) do
		state.owner = nil

		if state.collisionBox then
			state.collisionBox.parent = nil
			self.tileCollider:remove(state.collisionBox)
			self.activeCollider:remove(state.collisionBox)
		end

		if state.hitBox then
			state.hitBox.parent = nil
			self.tileCollider:remove(state.hitBox)
			self.activeCollider:remove(state.hitBox)
		end
	end

	StateMachine.destroySelf(self)
end

return Element