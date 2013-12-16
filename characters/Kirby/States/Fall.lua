local Class = require 'lib.hump.class'

local State = require 'data.core.Component.State'

local Fall = Class {
	name = "Fall",
	__includes = State,
}

function Fall:onEnterFrom(otherState)
	if otherState.name ~= "jump" then
		self.owner.animation:goToFrame(4)
	end
end

return Fall