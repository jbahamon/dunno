local Class = require 'lib.hump.class'
local PlayerState = require 'data.core.Player.PlayerState'

local Jump = Class {
	name = "Jump",
	__includes = PlayerState
}

function Jump:init(name, dynamics, animation)
	PlayerState.init(self, name, dynamics, animation)
end

function Jump:getCurrentAcceleration(dt)
	
	if self.owner.control["jump"] and self.dynamics.velocity.y < self.dynamics.gravityCondition then
		self.dynamics.gravity = self.dynamics.lowGravity
	else
		self.dynamics.gravity = self.dynamics.highGravity
	end

	return PlayerState.getCurrentAcceleration(self, dt)

end

function Jump:onEnterFrom(otherState)
	PlayerState.onEnterFrom(self, otherState)

	if math.abs(self.dynamics.velocity.x) > self.dynamics.horizontalCondition then

		self.dynamics.maxVelocity.x = self.dynamics.horizontalMaxVelocities[2]
		
	else

		self.dynamics.maxVelocity.x = self.dynamics.horizontalMaxVelocities[1]

	end

	if math.abs(self.dynamics.velocity.x) < self.dynamics.jumpVelocityConditions[1] then

		self.dynamics.velocity.y = self.dynamics.jumpYVelocities[1]

	elseif math.abs(self.dynamics.velocity.x) < self.dynamics.jumpVelocityConditions[2] then

		self.dynamics.velocity.y = self.dynamics.jumpYVelocities[2]

	elseif math.abs(self.dynamics.velocity.x) < self.dynamics.jumpVelocityConditions[3] then		

		self.dynamics.velocity.y = self.dynamics.jumpYVelocities[3]

	else
		self.dynamics.velocity.y = self.dynamics.jumpYVelocities[4]
	end

end

return Jump