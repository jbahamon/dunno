local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local ElementState = require 'data.core.Element.ElementState'

local Jump = Class {
	name = "Jump",
	__includes = ElementState,

	init =
		function(self, name, animationData, dynamics)
			ElementState.init(self, name, animationData, dynamics)
		end
}

function Jump:onEnterFrom(previousState)
	ElementState.onEnterFrom(self, previousState)

	self.dynamics.velocity.y = self.dynamics.jumpVelocity
	print("boing")
end

return Jump