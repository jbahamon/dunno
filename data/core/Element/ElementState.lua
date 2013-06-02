--- Element state implementation.
-- @class module
-- @name data.core.Element.ElementState

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local shapes = require 'lib.HardonCollider.shapes'

local State = require 'data.core.StateMachine.State'

--- Builds a new ElementState.
-- @class function
-- @name ElementState
-- @param name The state's name.
-- @param dynamics The dynamic parameters for the state.
-- @param animation The state's animation, as created with <a href="https://github.com/kikito/anim8/">anim8</a>.
-- @return The newly created State.

local ElementState = Class {
	name = "ElementState",
	__includes = State
}

function ElementState:init(name, animation, dynamics)
	State.init(self, name)
	self.dynamics = {}
	self.dynamics.velocity = vector(0, 0)
	self.dynamics.position = vector(0, 0)
	self.nextState = nil
	self.facing = 1
	self.animation = animation
	self.transitions = {}
	self.stateTime = 0

	self.dynamics.size = nil

	-- Velocities
	self.dynamics.maxVelocity = vector(0, 0)

	-- Accelerations    
	self.dynamics.friction = vector(0, 0)
	self.dynamics.noInputFriction = vector(0, math.huge)
	self.dynamics.defaultAcceleration = vector(0, 0)
	self.dynamics.inputAcceleration = vector(0, math.huge)
	self.dynamics.gravity = vector(0, 0)

	if dynamics then
		self:addDynamics(dynamics)
	end
	
	if self.dynamics.hitBox and self.dynamics.hitBox.size then
		self.hitBox = shapes.newPolygonShape(
					    	- math.floor(self.dynamics.hitBox.size.x/2), 0,
					    	  math.ceil(self.dynamics.hitBox.size.x/2), 0,
					    	  math.ceil(self.dynamics.hitBox.size.x/2), - self.dynamics.hitBox.size.y,
					    	- math.floor(self.dynamics.hitBox.size.x/2), - self.dynamics.hitBox.size.y)

		self.hitBox.offset = self.dynamics.hitBox.offset or vector(0,0)
	end

	if self.dynamics.size then
		self.collisionBox = shapes.newPolygonShape(
					    	- math.floor(self.dynamics.size.x/2), 0,
					    	  math.ceil(self.dynamics.size.x/2), 0,
					    	  math.ceil(self.dynamics.size.x/2), - self.dynamics.size.y,
					    	- math.floor(self.dynamics.size.x/2), - self.dynamics.size.y)
	end
end

---An Element's state implementation. Extends @{data.core.StateMachine.State|State}.
-- Has animation data and dynamics, in addition to normal State properties.
-- @type ElementState

--- Draws the ElementState's animation at the ElementState's position.
-- The image is aligned so that the ElementState's position lies at the bottom-center of the sprite.
function ElementState:draw()
	self.animation:draw(self.owner.sprites,
	                    self.dynamics.position.x - self.owner.spriteSize.x/2 + self.owner.spriteOffset.x,
                       	self.dynamics.position.y - self.owner.spriteSize.y + self.owner.spriteOffset.y,
                       	0, 1, 1)
end

--- Updates the ElementState.
-- Movement is done here.
-- @param dt The current frame's time slice, in seconds.
function ElementState:update(dt)

	self.stateTime = self.stateTime + dt

	self.animation.flippedH = self.facing < 0
	-- Animation
	self.animation:update(dt)

	-- Process Dynamics
	self:stepDynamics(dt, self:getCurrentAcceleration(dt))
end

-----------------------------------------------------------------
-- Positioning and dynamics
-- @section position

--- Moves the Element by a certain amount, in pixels. Called by @{data.core.Element.Element:move|Element:move}.
-- The ElementState's collision box, if any, is not moved.
-- @param displacement The displacement to be applied, as a hump vector, in pixels.
function ElementState:move(displacement)
	self.dynamics.oldPosition = self.dynamics.position
	self.dynamics.position = self.dynamics.position + displacement
end

--- Moves the Element to a certain position, in pixels. Called by @{data.core.Element.Element:moveTo|Element:moveTo}.
-- The ElementState's collision box, if any, is not moved.
-- @param position The target position, as a hump vector.
function ElementState:moveTo(position)
	self.dynamics.oldPosition = self.dynamics.position
	self.dynamics.position = position:clone()
end

--- Flips the Element horizontally, reversing its velocity.
-- Note that a positive horizontal velocity always means moving towards the right.
function ElementState:turn()
	self.facing = -self.facing
	self.dynamics.velocity.x = - self.dynamics.velocity.x
end

--- Applies the provided friction force to the Element.
-- A friction force is always dissipative: it will never cause 
-- the element to reverse its velocity.
-- @param dt The current frame's time slice, in seconds
-- @param frictionForce The friction to apply, as a vector, in acceleration units (pixels/seconds^2)
-- This means that every Element has the same mass, for the time being.
function ElementState:applyFriction(dt, frictionForce)
	local friction = frictionForce * dt

	if friction.x > math.abs(self.dynamics.velocity.x) then
		self.dynamics.velocity.x = 0 
	elseif self.dynamics.velocity.x > 0 then
  		self.dynamics.velocity.x = self.dynamics.velocity.x - friction.x
  	elseif self.dynamics.velocity.x < 0 then
  		self.dynamics.velocity.x = self.dynamics.velocity.x + friction.x
  	end
  
  	if friction.y > math.abs(self.dynamics.velocity.y) then
  		self.dynamics.velocity.y = 0
  	elseif self.dynamics.velocity.y > 0 then
  		self.dynamics.velocity.y = self.dynamics.velocity.y - friction.y
  	elseif self.dynamics.velocity.y < 0 then
  		self.dynamics.velocity.y = self.dynamics.velocity.y + friction.y
  	end

end

--- Applies an acceleration to the Element and moves it.
-- It calls @{ElementState:applyPostForceEffects} to apply those
-- effects that come into play after applying a force but
-- before moving the Element (such as friction).
-- This function should not be called alone: instead, it is called from
-- ElementState:update.
-- @param dt The current frame's time slice, in seconds.
-- @param acceleration The acceleration to be applied, as a vector, in pixels/seconds^2.
function ElementState:stepDynamics(dt, acceleration)

	self.displacement = self.dynamics.velocity * (dt / 2.0)
    
    self.dynamics.velocity = self.dynamics.velocity + acceleration * dt

    self.dynamics.velocity.x = 	math.min(self.dynamics.velocity.x, self.dynamics.maxVelocity.x)
    self.dynamics.velocity.y = 	math.min(self.dynamics.velocity.y, self.dynamics.maxVelocity.y)
	
    self.dynamics.velocity.x = 	math.max(self.dynamics.velocity.x, -self.dynamics.maxVelocity.x)
    self.dynamics.velocity.y = 	math.max(self.dynamics.velocity.y, -self.dynamics.maxVelocity.y)

	self:applyPostForceEffects(dt)

	self.displacement = self.displacement + self.dynamics.velocity * (dt / 2.0)

	self.owner:move(self.displacement)
   	
end

--- Applies those effects that come into play after applying a force but
-- before moving the Element (such as friction). The only default effect is applying friction.
-- @param dt The current frame's time slice, in seconds.
-- @see ElementState:applyFriction
function ElementState:applyPostForceEffects(dt)

	self:applyFriction(dt, self.dynamics.friction)

end


--- Returns the acceleration to be applied to the Element.
-- The default implementation returns the default acceleration values specified in the dynamics table.
-- @param dt The current frame's time slice, in seconds.
function ElementState:getCurrentAcceleration(dt)
	local acceleration = self.dynamics.defaultAcceleration:permul(vector(self.facing, 1)) + self.dynamics.gravity
	return acceleration
end

function ElementState:addDynamics(dynamics) 
	for k, v in pairs(dynamics) do
		self.dynamics[k] = v
	end
end

function ElementState:getHitBy(otherElement)
end

-----------------------------------------------------------------
--- Transition handling
-- @section transition

--- Initializes the ElementState with info (position, velocity, facing, etc) from the previous one.
-- It also starts the ElementState's animation from its first frame.
-- Automatically called from @{data.core.StateMachine.StateMachine:changeToState|StateMachine:changeToState}.
-- @param previousState The preceding state, from which to copy values.
function ElementState:onEnterFrom(previousState) 

	previousState.animation:pause()
	self.facing = previousState.facing
	self.stateTime = 0
	self.animation.flippedH = self.facing < 0
	self.dynamics.velocity = previousState.dynamics.velocity
	self.dynamics.position = previousState.dynamics.position
	self.dynamics.oldPosition = previousState.dynamics.oldPosition
	self.animation:gotoFrame(1)
	self.animation:resume()

end	

return ElementState