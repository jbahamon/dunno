local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local ElementState = require 'data.core.Element.ElementState'

local PiranhaPlantMoving = Class {
	name = "PiranhaPlantMoving",
	__includes = ElementState,

	init =
		function(self, name, animationData, dynamics)
			ElementState.init(self, name, animationData, dynamics)
		end
}

function PiranhaPlantMoving:onEnterFrom(previousState)
	ElementState.onEnterFrom(self, previousState)
	self.dynamics.velocity = self.dynamics.defaultVelocity:clone()
	
end

return PiranhaPlantMoving