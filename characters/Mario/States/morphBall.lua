	local Class = require 'lib.hump.class'
local PlayerState = require 'data.core.Player.PlayerState'

local MorphBall = Class {
	name = "MorphBall",
	__includes = PlayerState,

	init = 
		function(self, name, dynamics, animation)
			PlayerState.init(self, name, dynamics, animation)
		end
}


function MorphBall:applyPostForceEffects(dt)
	PlayerState.applyPostForceEffects(self, dt)

	if (not self.owner.collisionFlags.canMoveDown) and self.dynamics.velocity.y > 0 then
		self.dynamics.velocity.y = 0
		self:removeFlag("air")
		self:addFlag("grounded")
	else
		self:removeFlag("grounded")
		self:addFlag("air")
	end


end

function MorphBall:onEnterFrom(otherState)
	PlayerState.onEnterFrom(self, otherState)

	self.dynamics.velocity.y = self.dynamics.startVelocity

end

return MorphBall