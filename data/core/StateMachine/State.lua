local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local ElementState = Class {
	name = "ElementState",

	init = 
		function(self, name)
			self.name = name
		end
}

function ElementState:addTransition(condition, targetState, position)

	position = position or -1

	local transition = {condition = condition, targetState = targetState}

	if position < 0 then
		table.insert(self.transitions, transition)
	else
		table.insert(self.transitions, transition, position)
	end
end

function ElementState:update(dt)
end

return ElementState