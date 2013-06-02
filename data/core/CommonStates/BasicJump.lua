local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local PlayerState = require 'data.core.Player.PlayerState'

local BasicJump = Class {
	name = "BasicJump",
	__includes = PlayerState
}

function BasicJump:init(name, animationData, dynamics)
	PlayerState.init(self, name, animationData, dynamics)
end

function BasicJump:onEnterFrom(previousState)
	PlayerState.onEnterFrom(self, previousState)

	self.dynamics.velocity.y = self.dynamics.jumpVelocity
end

return BasicJump