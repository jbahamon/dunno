local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local Jump = Class {
	name = "MegamanJump",
	__includes = State
}


function Jump:lateUpdate(dt)
	
	if self.owner.physics.velocity.y < self.dynamics.jumpReleaseVelocity and
		not self.owner.control["jump"] then
		self.owner.physics.velocity.y = self.dynamics.jumpClipVelocity
	end

end

function Jump:onEnterFrom(otherState)
    self.owner.physics.velocity.y = self.dynamics.jumpVelocity
end

return Jump