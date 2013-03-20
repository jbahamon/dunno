--- Player state implementation.
-- @class module
-- @name data.core.Player.PlayerState

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local ElementState = require 'data.core.Element.ElementState'


--- Builds a new PlayerState.
-- @class function
-- @name PlayerState
-- @param name The state's name.
-- @param dynamics The dynamic parameters for the state.
-- @param animation The state's animation, as created with <a href="https://github.com/kikito/anim8/">anim8</a>.
-- @return The newly created State.

local PlayerState = Class {
	name = "PlayerState",

	__includes = ElementState,
	
	init =
		function(self, name, dynamics, animation)
			ElementState.init(self, name, dynamics, animation)
			self.hasControl = true
		end
}

---A Player's state implementation. Extends @{data.core.Element.ElementState|ElementState}.
-- Has input handling in addition to normal ElementState properties.
-- @type PlayerState

--- Sets the hasControl field of the state. If control is set to false, 
-- the state won't receive input from the player.
-- @param control The value to assign to the hasControl field.
function PlayerState:setControl(control)
	self.hasControl = control
end

--- Updates the PlayertState.
-- Input handling and movement are processed here.
-- @param dt The current frame's time slice, in seconds.
function PlayerState:update(dt)
	self:handleInput()
	ElementState.update(self, dt)
end

--- Applies any needed changes to the state due to user input.
-- Movement as dictated by input is not done here (see @{PlayerState:getCurrentAcceleration})
-- Input handling and movement is processed here.
-- Override this if you want special things to happen due to user input (e.g. shooting)
-- @param dt The current frame's time slice, in seconds.
function PlayerState:handleInput()
	if (self.owner.control["left"] and not self.owner.control["right"]
			and self.facing > 0)  or 
	   (self.owner.control["right"] and not self.owner.control["left"]
	   		and self.facing < 0) then
		self.facing = -self.facing
	end
	
end

--- Returns the acceleration to be applied to the Player.
-- Includes applying the default acceleration and additional acceleration based on user input.
-- Override this if you want to modify the way user input affects Player movement.
-- @param dt The current frame's time slice, in seconds.
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