local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local MorphBall = Class {
	name = "MorphBall",
	__includes = State
}

function MorphBall:lateUpdate(dt)

	if (not self.owner.collision.collisionFlags.canMoveDown) and self.owner.physics.velocity.y > 0 then
		self.owner.physics.velocity.y = 0
		self:removeFlag("air")
		self:addFlag("grounded")
	else
		self:removeFlag("grounded")
		self:addFlag("air")
	end


end

function MorphBall:onEnterFrom(otherState)
	self.owner.physics.velocity.y = self.dynamics.startVelocity
end

return MorphBall