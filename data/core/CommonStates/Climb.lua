local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local Climb = Class {
	name = "climb",

	__includes = State
}

function Climb:init(name)
	State.init(self, name)	
end

function Climb:update(dt)
	if self.owner.input.control["up"] or self.owner.input.control["down"] then
		self.owner.animation:resume()
	else 
		self.owner.animation:pause()
	end
end

return Climb