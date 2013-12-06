local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local State = require 'data.core.Component.State'

local Jump = Class {
	name = "Jump",
	__includes = State
}

function Jump:onEnterFrom(previousState)
	self.owner.physics.velocity.y = self.dynamics.jumpVelocity
	
end

function Jump:getHitBy(otherElement)
	State.getHitBy(self, otherElement)
	self:turn()
end

function Jump:lateUpdate(dt)
	if (self.owner.physics.velocity.x > 0 and (not self.owner.collision.collisionFlags.canMoveRight)) or
		(self.owner.physics.velocity.x < 0 and (not self.owner.collision.collisionFlags.canMoveLeft)) then
		self.owner:turn()
		self.owner.physics.velocity.x = -self.owner.physics.velocity.x 
	end
end

return Jump