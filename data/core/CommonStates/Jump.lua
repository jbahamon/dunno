local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local PlayerState = require 'data.core.Player.PlayerState'

local Jump = Class {
	name = "Jump",
	__includes = PlayerState,

	init =
		function(self, name, dynamics, animationData)
			PlayerState.init(self, name, dynamics, animationData)
		end
}

function Jump:onEnterFrom(previousState)
	PlayerState.onEnterFrom(self, previousState)

	self.dynamics.velocity.y = self.dynamics.jumpVelocity
end

return Jump