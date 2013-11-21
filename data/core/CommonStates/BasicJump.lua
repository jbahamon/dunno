local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local State = require 'data.core.Component.State'

local BasicJump = Class {
	name = "BasicJump",
	__includes = State
}

function BasicJump:init(name)
	State.init(self, name)
end

function BasicJump:onEnterFrom(previousState)
	self.owner.physics.velocity.y = self.dynamics.jumpVelocity
end

return BasicJump