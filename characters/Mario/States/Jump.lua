local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local Jump = Class {
	name = "Jump",
	__includes = State
}

function Jump:update(dt)
	
	if self.owner.control["jump"] and self.owner.physics.velocity.y < self.dynamics.gravityCondition then
		self.dynamics.gravity = self.dynamics.lowGravity
	else
		self.dynamics.gravity = self.dynamics.highGravity
	end

	-- Some ternary operator magic. We check if the player is pressing in the direction
	-- of motion or against it. This actually affects the applied acceleration in SMB3.
	local motionDirection = (self.owner.physics.velocity.x > 0 ) and 1 or -1
		
	-- A trick to see where the player is pointing. If the player is pointing in 
	-- both directions, it is calculated as 0 (no direction)
	local inputDirection =  (self.owner.control["right"]) and 1 or 0
	inputDirection = inputDirection + ((self.owner.control["left"]) and -1 or 0)

	self.dynamics.inputAcceleration = (motionDirection * inputDirection > 0) and
		self.dynamics.forwardsInputAcceleration	or
		self.dynamics.backwardsInputAcceleration

	if inputDirection * self.owner.transform.facing < 0 then
		self.owner:turn()
	end

end

function Jump:onEnterFrom(otherState)
	-- More ternary operator simulation to set some values.
	self.dynamics.gravity = (self.owner.control["jump"] and 
		self.owner.physics.velocity.y < self.dynamics.gravityCondition) and
		self.dynamics.lowGravity or
		self.dynamics.highGravity
	
	self.dynamics.maxVelocity.x = (math.abs(self.owner.physics.velocity.x) > self.dynamics.horizontalCondition) and
		self.dynamics.horizontalMaxVelocities[2] or
		self.dynamics.horizontalMaxVelocities[1]
	
	if otherState.name == "fall" then
		self.owner.physics.velocity.y = self.dynamics.stompJumpVelocity
		return
	end

	if math.abs(self.owner.physics.velocity.x) < self.dynamics.jumpVelocityConditions[1] then

		self.owner.physics.velocity.y = self.dynamics.jumpYVelocities[1]

	elseif math.abs(self.owner.physics.velocity.x) < self.dynamics.jumpVelocityConditions[2] then

		self.owner.physics.velocity.y = self.dynamics.jumpYVelocities[2]

	elseif math.abs(self.owner.physics.velocity.x) < self.dynamics.jumpVelocityConditions[3] then		

		self.owner.physics.velocity.y = self.dynamics.jumpYVelocities[3]

	else
		self.owner.physics.velocity.y = self.dynamics.jumpYVelocities[4]
	end

end

return Jump