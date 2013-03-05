local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local ElementState = Class {
	name = "ElementState",

	function(self, name, dynamics, control, animationData)
		self.name = name
		self.dynamics = dynamics
		self.dynamics.velocity = vector(0, 0)
		self.dynamics.position = vector(0, 0)
		self.nextState = nil
		self.control = control
		self.facing = 1
		self.animationData = animationData
		self.transitions = {}
	end
}

function ElementState:addTransition(condition, targetState, position)

	position = position or -1

	local transition = {condition = condition, targetState = targetState}

	if position < 0 then
		table.insert(self.transitions, transition)
	else
		table.insert(self.transitions, transition, position)
	end
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
	-- Facing

	if self.control and self.controls and 
			((self.facing > 0 and self.controls["left"]
							  and not self.controls["right"]) or
			 (self.facing < 0 and self.controls["right"]
			  				  and not self.controls["left"])) then
		self.facing = -self.facing
		self.animationData.animation:flipH()
	else

	end

	-- Animation
	self.animationData.animation:update(dt)

	-- Process Dynamics
	self:processDynamics(dt)
end

function ElementState:processDynamics(dt)

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
   	
end

function ElementState:applyPostForceEffects(dt)

	self:applyFriction(dt, self.dynamics.friction)

end

function ElementState:getCurrentAcceleration(dt)
	local acceleration = self.dynamics.defaultAcceleration + self.dynamics.gravity

	
	if self.control then

		if self.controls["up"] and not self.controls["down"] then
			acceleration.y = acceleration.y - self.dynamics.inputAcceleration.y
		elseif self.controls["down"] then
			acceleration.y = acceleration.y + self.dynamics.inputAcceleration.y
		end


		if self.controls["left"] and not self.controls["right"] then
			acceleration.x = acceleration.x - self.dynamics.inputAcceleration.x 
		elseif self.controls["right"] then
			acceleration.x = acceleration.x + self.dynamics.inputAcceleration.x 
		end

		if not (self.controls["left"] or self.controls["right"]) then
			self:applyFriction(dt, vector(self.dynamics.noInputFriction.x, 0))
		end

		if not (self.controls["up"] or self.controls["down"]) then
			self:applyFriction(dt, vector(0, self.dynamics.noInputFriction.y))
		end
		
	end

	return acceleration

end

function ElementState:enterFrom(previousState) 

	previousState.animationData.animation:pause()
	self.facing = previousState.facing

	self.animationData.animation.flippedH = self.facing < 0
	self.dynamics.velocity = previousState.dynamics.velocity
	self.dynamics.position = previousState.dynamics.position
	self.dynamics.oldPosition = previousState.dynamics.oldPosition
	self.animationData.animation:gotoFrame(1)
	self.animationData.animation:resume()

	self.nextState = nil
end	

function ElementState:draw()

	self.animationData.animation:draw(self.animationData.sprites,
		                    self.dynamics.position.x - self.animationData.spriteSize.x/4,
                           	self.dynamics.position.y - self.animationData.spriteSize.y/2,
                           	0, 0.5, 0.5)
end

function ElementState:checkStateChange(collisionFlags)
	for order, transition in ipairs(self.transitions) do
		if transition.condition(self, collisionFlags) then
			return transition.targetState
		end
	end

	return false
end

function ElementState:move(displacement)
	self.dynamics.position = self.dynamics.position + displacement
end

return ElementState