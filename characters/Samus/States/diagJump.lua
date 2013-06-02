local Class = require 'lib.hump.class'
local BasicJump = require 'data.core.CommonStates.BasicJump'

local DiagJump = Class {
	name = "DiagJump",
	__includes = BasicJump
		
}

function DiagJump:init(name, dynamics, animation)
	BasicJump.init(self, name, dynamics, animation)
end

function DiagJump:applyPostForceEffects(dt)
	BasicJump.applyPostForceEffects(self, dt)

	if self.dynamics.velocity.y < self.dynamics.jumpReleaseVelocity and
		not self.owner.control["jump"] then
		self.dynamics.velocity.y = self.dynamics.jumpClipVelocity
	end

	if self.permafacing ~= self.facing then
		self:turn()
	end
end

function DiagJump:onEnterFrom(otherState)
	BasicJump.onEnterFrom(self, otherState)

	self.permafacing = self.facing

end

return DiagJump