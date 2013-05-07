local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local ElementState = require 'data.core.Element.ElementState'

local Walk = Class {
	name = "Walk",
	__includes = ElementState,

	init =
		function(self, name, animationData, dynamics)
			ElementState.init(self, name, animationData, dynamics)
		end
}

function Walk:getHitBy(otherElement)
	ElementState.getHitBy(self, otherElement)
	self:turn()
end

function Walk:getCurrentAcceleration(dt)
	if (self.dynamics.velocity.x > 0 and (not self.owner.collisionFlags.canMoveRight)) or
		(self.dynamics.velocity.x < 0 and (not self.owner.collisionFlags.canMoveLeft)) then
		self:turn()
	end

	return ElementState.getCurrentAcceleration(self, dt)
end

return Walk