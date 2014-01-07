--- A state that provides climbing.
local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local Climb = Class {
	name = "climb",

	__includes = State
}

--- Resumes the climbing animation only if the player is actually climbing (in other words, presing up or down)
-- @tparam number dt The amount of time elapsed since the last frame.
function Climb:update(dt)
	if self.owner.input.control["up"] or self.owner.input.control["down"] then
		self.owner.animation:resume()
	else 
		self.owner.animation:pause()
	end
end

return Climb