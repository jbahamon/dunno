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

	if self.owner.physics.stateTime >= self.owner.physics.parameters.groundedTime then
		self:removeFlag("grounded")
		self:addFlag("air")
	end

	if self.owner.control[self.holdControl] and self.owner.physics.stateTime < self.owner.physics.parameters.jumpTime then
		self.owner.physics.velocity.y = self.owner.physics.parameters.jumpVelocity
	end

end

function Jump:onEnterFrom(previousState)
	BasicJump.onEnterFrom(self, previousState)

	self:removeFlag("air")
	self:addFlag("grounded")
end


function Jump:setHoldControl(control)
	self.holdControl = control
end


return Jump