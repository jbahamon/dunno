local Class = require 'lib.hump.class'
local BasicJump = require 'data.core.CommonStates.BasicJump'

local Jump = Class {
	name = "Jump",
	__includes = BasicJump,
}

function Jump:onEnterFrom(otherState)
    BasicJump.onEnterFrom(self, otherState)
    if math.abs(self.owner.physics.velocity.x) > self.dynamics.velocityThreshold.x then
        self.dynamics.maxVelocity = self.dynamics.maxVelocityBig
    else
        self.dynamics.maxVelocity = self.dynamics.maxVelocitySmall
    end
end


function Jump:lateUpdate(dt)
	
	if self.owner.physics.velocity.y < self.dynamics.jumpReleaseVelocity and
		not self.owner.control["jump"] then
		self.owner.physics.velocity.y = self.dynamics.jumpClipVelocity
	end

end

return Jump