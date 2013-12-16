local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local FloatDown = Class {
	name = "FloatDown",
	__includes = State,
}

function FloatDown:lateUpdate(dt)
	self.owner.physics.velocity.y = math.min(self.owner.physics.velocity.y, self.dynamics.maxFallVelocity)
end

return FloatDown