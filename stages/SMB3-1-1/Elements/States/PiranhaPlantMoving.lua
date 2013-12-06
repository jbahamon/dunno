local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local State = require 'data.core.Component.State'

local PiranhaPlantMoving = Class {
	name = "PiranhaPlantMoving",
	__includes = State
}



function PiranhaPlantMoving:onEnterFrom(previousState)
	self.owner.physics.velocity = self.dynamics.defaultVelocity:clone()
end

return PiranhaPlantMoving