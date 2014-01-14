local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local State = require 'data.core.Component.State'

local Walk = Class {
	name = "Walk",
	__includes = State
}

function Walk:lateUpdate(dt)
	if (self.owner.physics.velocity.x > 0 and (not self.owner.collision.collisionFlags.canMoveRight)) or
		(self.owner.physics.velocity.x < 0 and (not self.owner.collision.collisionFlags.canMoveLeft)) then
		self:turn()
	end

	if (not self.owner.collision.collisionFlags.canMoveDown) and (not self.owner.collision.collisionFlags.standingOnSolid) then
		self.owner:turn()
		self.owner.physics.velocity.x = -self.owner.physics.velocity.x 
	end

end

return Walk