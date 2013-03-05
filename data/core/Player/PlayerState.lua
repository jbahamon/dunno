local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local ElementState = require 'data.core.Element.ElementState'

local PlayerState = Class {
	name = "PlayerState",

	__includes = ElementState,
	
	init =
		function(self, name, dynamics, animation)
			ElementState.init(self, name, dynamics, animation)
			self.hasControl = true
		end
}

function PlayerState:setControl(control)
	self.hasControl = control
end

function PlayerState:update(dt)
	self:handleInput()
	ElementState.update(self, dt)
end

function PlayerState:handleInput()
	if (self.owner.control["left"] and not self.owner.control["right"]
			and self.facing > 0)  or 
	   (self.owner.control["right"] and not self.owner.control["left"]
	   		and self.facing < 0) then
		self.facing = -self.facing
	end
	
end

function PlayerState:getCurrentAcceleration(dt)
	local acceleration = ElementState.getCurrentAcceleration(self, dt)
	
	if self.owner.control and self.hasControl then
		if self.owner.control["up"] and not self.owner.control["down"] then
			acceleration.y = acceleration.y - self.dynamics.inputAcceleration.y
		elseif self.owner.control["down"] then
			acceleration.y = acceleration.y + self.dynamics.inputAcceleration.y
		end


		if self.owner.control["left"] and not self.owner.control["right"] then
			acceleration.x = acceleration.x - self.dynamics.inputAcceleration.x 
		elseif self.owner.control["right"] then
			acceleration.x = acceleration.x + self.dynamics.inputAcceleration.x 
		end

		if not (self.owner.control["left"] or self.owner.control["right"]) then
			self:applyFriction(dt, vector(self.dynamics.noInputFriction.x, 0))
		end

		if not (self.owner.control["up"] or self.owner.control["down"]) then
			self:applyFriction(dt, vector(0, self.dynamics.noInputFriction.y))
		end
		
	end

	
	return acceleration

end

return PlayerState