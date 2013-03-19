local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local shapes = require 'lib.HardonCollider.shapes'

local State = require 'data.core.StateMachine.State'

local ElementState = Class {
	name = "ElementState",

	__includes = State,
	
	init =
		function(self, name, dynamics, animation)
			State.init(self, name)
			self.dynamics = dynamics
			self.dynamics.velocity = vector(0, 0)
			self.dynamics.position = vector(0, 0)
			self.nextState = nil
			self.facing = 1
			self.animation = animation
			self.transitions = {}
			if self.dynamics.width and self.dynamics.height then
				self.collisionBox = shapes.newPolygonShape(
							    	- math.floor(self.dynamics.width/2), 0,
							    	  math.ceil(self.dynamics.width/2), 0,
							    	  math.ceil(self.dynamics.width/2), - self.dynamics.height,
							    	- math.floor(self.dynamics.width/2), - self.dynamics.height)
			end
		end
}



function ElementState:turn()
	self.facing = -self.facing
	self.dynamics.velocity.x = - self.dynamics.velocity.x
end


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

function ElementState:update(dt)
	self.animation.flippedH = self.facing < 0
	-- Animation
	self.animation:update(dt)

	-- Process Dynamics
	self.dynamics.oldPosition = self.dynamics.position
	self:stepDynamics(dt, self:getCurrentAcceleration(dt))
end

function ElementState:stepDynamics(dt, acceleration)


	self.displacement = self.dynamics.velocity * (dt / 2.0)
    
    self.dynamics.velocity = self.dynamics.velocity + acceleration * dt

    self.dynamics.velocity.x = 	math.min(self.dynamics.velocity.x, self.dynamics.maxVelocity.x)
    self.dynamics.velocity.y = 	math.min(self.dynamics.velocity.y, self.dynamics.maxVelocity.y)
	
    self.dynamics.velocity.x = 	math.max(self.dynamics.velocity.x, -self.dynamics.maxVelocity.x)
    self.dynamics.velocity.y = 	math.max(self.dynamics.velocity.y, -self.dynamics.maxVelocity.y)

	self:applyPostForceEffects(dt)

	self.displacement = self.displacement + self.dynamics.velocity * (dt / 2.0)


	self.owner:move(self.displacement:unpack())
   	
end

function ElementState:applyPostForceEffects(dt)

	self:applyFriction(dt, self.dynamics.friction)

end

function ElementState:getCurrentAcceleration(dt)
	local acceleration = self.dynamics.defaultAcceleration:permul(vector(self.facing, 1)) + self.dynamics.gravity
	return acceleration

end

function ElementState:onEnterFrom(previousState) 

	previousState.animation:pause()
	self.facing = previousState.facing

	self.animation.flippedH = self.facing < 0
	self.dynamics.velocity = previousState.dynamics.velocity
	self.dynamics.position = previousState.dynamics.position
	self.dynamics.oldPosition = previousState.dynamics.oldPosition
	self.animation:gotoFrame(1)
	self.animation:resume()

end	

function ElementState:draw()
	self.animation:draw(self.owner.sprites,
	                    self.dynamics.position.x - self.owner.spriteSizeX/2 + self.owner.spriteOffset.x,
                       	self.dynamics.position.y - self.owner.spriteSizeY + self.owner.spriteOffset.y,
                       	0, 1, 1)
end

function ElementState:checkStateChange(collisionFlags)
	for order, transition in ipairs(self.transitions) do
		if transition.condition(self, collisionFlags) then
			return transition.targetState
		end
	end

	return false
end

function ElementState:move(dx, dy)
	self.dynamics.position = self.dynamics.position + vector(dx, dy)
end


function ElementState:moveTo(x, y)
	self.dynamics.position = vector(x, y)
end


return ElementState