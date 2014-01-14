local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

--Hopping
local Hop = Class {
	name = "Hop",
	__includes = State,
}

function Hop:init(...)
	State.init(self, ...)
	self.hopCount = 0
end

function Hop:onEnterFrom(previousState)
	
	if (previousState ~= self) then
		self.hopCount = 0
	else
		self.hopCount = self.hopCount + 1
	end

	self.owner.physics.velocity.y = self.dynamics.jumpVelocity
	
end

function Hop:lateUpdate(dt)
	if (self.owner.physics.velocity.x > 0 and (not self.owner.collision.collisionFlags.canMoveRight)) or
		(self.owner.physics.velocity.x < 0 and (not self.owner.collision.collisionFlags.canMoveLeft)) then
		self.owner:turn()
		self.owner.physics.velocity.x = -self.owner.physics.velocity.x 
	end
end

return Hop