local Class = require 'lib.hump.class'
local PlayerState = require 'data.core.Player.PlayerState'
local Timer = globals.Timer

local Hit = Class {
	name = "Hit",

	__includes = PlayerState,

	function(self, name, animation, dynamics)
		PlayerState.init(self, name, animation, dynamics)
		self.hasControl = false
	end
}


function Hit:onEnterFrom(otherState)
	PlayerState.onEnterFrom(self, otherState)
	self.owner.hittable = false
	Timer.add(
		self.dynamics.invincibleTime,
		function()
			self.owner.hittable = true
		end
		)

	self.owner.collisionFlags = {}
	self.dynamics.velocity = self.dynamics.startVelocity
	self.dynamics.velocity.x = self.dynamics.velocity.x * self.facing

	self.dynamics.hitTimer = 0
	self.hasControl = false


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
	PlayerState.update(self, dt)
	self.dynamics.hitTimer = self.dynamics.hitTimer + dt
	if self.dynamics.hitTimer > self.dynamics.hitTime then
		self.hasControl = true
	end

end

return Hit