local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local BasicJump = require 'data.core.CommonStates.BasicJump'

local Jump = Class {
	name = "Jump",
	__includes = BasicJump
}

function Jump:init(name, dynamics, animation)
	BasicJump.init(self, name, dynamics, animation)
	self.holdControl = "jump"
end

function Jump:update(dt)
	BasicJump.update(self, dt)

	if self.stateTime >= self.dynamics.groundedTime then
		self:removeFlag("grounded")
		self:addFlag("air")
	end

end

function Jump:onEnterFrom(previousState)
	BasicJump.onEnterFrom(self, previousState)

	self:removeFlag("air")
	self:addFlag("grounded")
end


function Jump:applyPostForceEffects(dt)
	BasicJump.applyPostForceEffects(self, dt)

	if self.owner.control[self.holdControl] and self.stateTime < self.dynamics.jumpTime then
		self.dynamics.velocity.y = self.dynamics.jumpVelocity
	end

end

function Jump:setHoldControl(control)
	self.holdControl = control
end


return Jump