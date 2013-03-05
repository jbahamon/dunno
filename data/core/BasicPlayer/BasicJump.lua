local Class = require 'lib.Hump.class'
local vector = require 'lib.Hump.vector'
local ElementState = require 'data.core.ActiveElement.ElementState'

local BasicJump = Class {
	name = "BasicJump",
	inherits = ElementState,
	function(self, name, dynamics, control, animationData)
		ElementState.construct(self, name, dynamics, control, animationData)
	end
}

function BasicJump:enterFrom(previousState, element)
	ElementState.enterFrom(self, previousState)

	self.dynamics.velocity.y = self.dynamics.jumpVelocity
end

return BasicJump