local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local BasicJump = require 'data.core.CommonStates.Jump'

local Jump = Class {
	name = "ScroogeJump",
	__includes = BasicJump,

	init = 
		function(self, name, dynamics, animation)
			BasicJump.init(self, name, dynamics, animation)
			self.jumpTimer = 0
			self.holdControl = "jump"
			self.groundedTimer = 0
		end
}

function Jump:update(dt)
	BasicJump.update(self, dt)
	self.jumpTimer = self.jumpTimer + dt
	self.groundedTimer = self.groundedTimer + dt

	if self.groundedTimer >= self.dynamics.groundedTime then
		self:removeFlag("grounded")
		self:addFlag("air")
	end

end

function Jump:onEnterFrom(previousState)
	BasicJump.onEnterFrom(self, previousState)
	self.jumpTimer = 0
	self.groundedTimer = 0

	self:removeFlag("air")
	self:addFlag("grounded")
end


function Jump:applyPostForceEffects(dt)
	BasicJump.applyPostForceEffects(self, dt)

	if self.owner.control[self.holdControl] and self.jumpTimer < self.dynamics.jumpTime then
		self.dynamics.velocity.y = self.dynamics.jumpVelocity
	end

end

function Jump:setHoldControl(control)
	self.holdControl = control
end


return Jump