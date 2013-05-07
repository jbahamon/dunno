local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local ElementState = require 'data.core.Element.ElementState'

local Hop = Class {
	name = "Hop",
	__includes = ElementState,

	init =
		function(self, name, animationData, dynamics)
			ElementState.init(self, name, animationData, dynamics)
			self.hopCount = 0
		end
}

function Hop:onEnterFrom(previousState)
	ElementState.onEnterFrom(self, previousState)

	if (previousState ~= self) then
		self.hopCount = 0
	else
		self.hopCount = self.hopCount + 1
	end

	self.dynamics.velocity.y = self.dynamics.jumpVelocity
	
end

function Hop:getHitBy(otherElement)
	ElementState.getHitBy(self, otherElement)
	self:turn()
end

function Hop:getCurrentAcceleration(dt)
	if (self.dynamics.velocity.x > 0 and (not self.owner.collisionFlags.canMoveRight)) or
		(self.dynamics.velocity.x < 0 and (not self.owner.collisionFlags.canMoveLeft)) then
		self:turn()
	end

	return ElementState.getCurrentAcceleration(self, dt)
end

return Hop