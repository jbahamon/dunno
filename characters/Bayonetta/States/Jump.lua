local Class = require 'lib.hump.class'
local BasicJump = require 'data.core.CommonStates.BasicJump'

local Jump = Class {
	name = "BayonettaJump",
	__includes = BasicJump
}


function Jump:init(name, dynamics, animation)
	BasicJump.init(self, name, dynamics, animation)
end

function Jump:applyPostForceEffects(dt)
	BasicJump.applyPostForceEffects(self, dt)

	if self.dynamics.velocity.y < self.dynamics.jumpReleaseVelocity and
		not self.owner.control["jump"] then
		self.dynamics.velocity.y = self.dynamics.jumpClipVelocity
	end

end

return Jump