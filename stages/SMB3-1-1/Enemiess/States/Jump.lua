local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local ElementState = require 'data.core.Element.ElementState'

local Jump = Class {
	name = "Jump",
	__includes = ElementState,

	init =
		function(self, name, animationData, dynamics)
			ElementState.init(self, name, animationData, dynamics)
		end
}

function Jump:onEnterFrom(previousState)
	ElementState.onEnterFrom(self, previousState)

	self.dynamics.velocity.y = self.dynamics.jumpVelocity
	
end

function Jump:getHitBy(otherElement)
	ElementState.getHitBy(self, otherElement)
	self:turn()
end

function Jump:getCurrentAcceleration(dt)
	if (self.dynamics.velocity.x > 0 and (not self.owner.collisionFlags.canMoveRight)) or
		(self.dynamics.velocity.x < 0 and (not self.owner.collisionFlags.canMoveLeft)) then
		self:turn()
	end

	return ElementState.getCurrentAcceleration(self, dt)
end

return Jump