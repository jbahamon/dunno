local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local PlayerState = require 'data.core.Player.PlayerState'

local Jump = Class {
	name = "Jump",
	__includes = PlayerState,

	init =
		function(self, name, animationData, dynamics)
			PlayerState.init(self, name, animationData, dynamics)
		end
}

function Jump:onEnterFrom(previousState)
	PlayerState.onEnterFrom(self, previousState)

	self.dynamics.velocity.y = self.dynamics.jumpVelocity
end

return Jump