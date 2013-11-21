local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local DiagJump = Class {
	name = "DiagJump",
	__includes = State
		
}

function DiagJump:lateUpdate(dt)

	if self.owner.physics.velocity.y < self.dynamics.jumpReleaseVelocity and
		not self.owner.control["jump"] then
		self.owner.physics.velocity.y = self.dynamics.jumpClipVelocity
	end

	if self.permafacing ~= self.owner.transform.facing then
		self:turn()
	end
end

function DiagJump:onEnterFrom(otherState)
	self.permafacing = self.owner.transform.facing
	self.owner.physics.velocity.y = self.dynamics.jumpVelocity
end

return DiagJump