local _NAME = (...)

local Class = require 'lib.hump.class'
local PlayerState = require 'data.core.Player.PlayerState'

local Climb = Class {
	name = "ScroogeClimb",

	__includes = PlayerState,

	function(self, name, dynamics, animation)
		PlayerState.init(self, name, dynamics, animation)		
	end
}


function Climb:update(dt)
	PlayerState.update(self, dt)
	if self.owner.control["up"] or self.owner.control["down"] then
		self.animation:resume()
	else 
		self.animation:pause()
	end
end

return Climb