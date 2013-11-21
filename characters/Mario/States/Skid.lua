local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local Skid = Class {
	name = "Skid",
	__includes = State
}

function Skid:update(dt)
	
	-- Some ternary operator magic. We check if the player is pressing in the direction
	-- of motion or against it. This actually affects the applied acceleration in SMB3.
	local motionDirection = (self.owner.physics.velocity.x > 0 ) and 1 or -1
		
	-- A trick to see where the player is pointing. If the player is pointing in 
	-- both directions, it is calculated as 0 (no direction)
	local inputDirection =  (self.owner.control["right"]) and 0 or 1 
	inputDirection = inputDirection + ((self.owner.control["left"]) and 0 or -1)

	

end


return Skid