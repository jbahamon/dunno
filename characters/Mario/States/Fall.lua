local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local Fall = Class {
	name = "Fall",
	__includes = State
}

function Fall:init(...)
	State.init(self, ...)
end

function Fall:update(dt)
	
	-- Some ternary operator magic. We check if the player is pressing in the direction
	-- of motion or against it. This actually affects the applied acceleration in SMB3.
	local motionDirection = (self.owner.physics.velocity.x > 0 ) and 1 or -1
		
	-- A trick to see where the player is pointing. If the player is pointing in 
	-- both directions, it is calculated as 0 (no direction)
	local inputDirection =  (self.owner.control["right"]) and 0 or 1 
	inputDirection = inputDirection + ((self.owner.control["left"]) and 0 or -1)

	self.dynamics.inputAcceleration = (motionDirection * inputDirection > 0) and
		self.dynamics.forwardsInputAcceleration	or
		self.dynamics.backwardsInputAcceleration

end

function Fall:onEnterFrom(otherState)

	-- More ternary operator simulation to set some values.
	
	if otherState.name == "jump" then
		self.dynamics.maxVelocity.x = otherState.dynamics.maxVelocity.x
	else	
		self.dynamics.maxVelocity.x = (math.abs(self.owner.physics.velocity.x) > self.dynamics.horizontalCondition) and
			self.dynamics.horizontalMaxVelocities[2] or
			self.dynamics.horizontalMaxVelocities[1]
	end

end

return Fall