local Class = require 'lib.hump.class'
local BasicJump = require 'data.core.CommonStates.BasicJump'

local Jump = Class {
	name = "Jump",
	__includes = BasicJump,
}

function Jump:init(name, dynamics, animation)
	BasicJump.init(self, name, dynamics, animation)
end


function Jump:lateUpdate(dt)
	
	if self.owner.physics.velocity.y < self.dynamics.jumpReleaseVelocity and
		not self.owner.control["jump"] then
        print("wow")
		self.owner.physics.velocity.y = self.dynamics.jumpClipVelocity
	end

end

return Jump