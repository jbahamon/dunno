local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local DiagFall = Class {
	name = "DiagFall",
	__includes = State
		
}

function DiagFall:lateUpdate(dt)

	if self.permafacing ~= self.owner.transform.facing then
		self.owner:turn()
	end
end

function DiagFall:onEnterFrom(otherState)
	self.permafacing = self.owner.transform.facing
end

return DiagFall