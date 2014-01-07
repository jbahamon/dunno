--- A state that provides very basic jump physics.
local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local BasicJump = Class {
	name = "BasicJump",
	__includes = State
}

--- Gives the gameObject a vertical impulse as soon as it enters this state.
-- The dynamics file for this state must have a jumpVelocity field (a number).
-- @tparam @{data.core.Component.State|State} previousState The previous state.
function BasicJump:onEnterFrom(previousState)
	self.owner.physics.velocity.y = self.dynamics.jumpVelocity
end

return BasicJump