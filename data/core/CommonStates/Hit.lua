local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'
local Timer = globals.Timer

local Hit = Class {
	name = "Hit",

	__includes = State
}

function Hit:init(name)
	State.init(self, name)
end


function Hit:onEnterFrom(otherState)
	State.onEnterFrom(self, otherState)
	self.owner.collision.hittable = false

	Timer.add(
		self.dynamics.invincibleTime,
		function()
			self.owner.collision.hittable = true
		end
		)

	self.owner.collision:clearCollisionFlags()
	self.owner.physics.velocity = self.dynamics.startVelocity:clone()
	self.owner.physics.velocity.x = self.owner.physics.velocity.x * self.owner.transform.facing

	self.hitTimer = 0
	self.owner.input.hasControl = false


	if otherState.flags["grounded"] then
		self:addFlag("grounded")
		self:removeFlag("air")
	end

	if otherState.flags["air"] then
		self:addFlag("air")
		self:removeFlag("grounded")
	end
end

function Hit:update(dt)
	self.hitTimer = self.hitTimer + dt
	if self.hitTimer > self.hitTime then
		self.owner.input.hasControl = true
	end

end

return Hit