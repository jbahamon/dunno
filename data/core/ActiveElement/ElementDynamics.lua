local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local ElementDynamics = Class {
	name = "ElementDynamics",

	function(self, parent, params)
		
		-- Constants:
        self.originalFrameRate = 60
        self.scale = self.originalFrameRate

        -- Positions


        -- Velocities
        self.jumpVelocity = - 4.871 * self.scale
        self.maxFallingVelocity = 12 * self.scale

        self.maxWalkingVelocity = 1.375 * self.scale

        -- Accelerations    
        self.defaultFriction = math.huge * self.scale * self.scale
        self.walkingAcceleration = math.huge * self.scale * self.scale
        self.gravity = 0.25 * self.scale * self.scale

        -- Other Properties, Counters and Flags
        self.jumpReleaseVelocity = 2.121 * self.scale
        self.jumpClipVelocity = 1 * self.scale
        self.airFalling = false
        self.control = true

        -- External fields
        self.activeFrictionCoefficient = 0
        self.passiveFrictionCoefficient = 1		

	    self.velocity = vector(0,0)
	    self.acceleration = vector(0,0)
    end
}

function ElementDynamics:update(dt, newAcceleration)
	 self.acceleration = self.acceleration + vector(0, self.gravity)

    self.oldPosition = self.position

    self.position = self.position + self.velocity * (dt / 2.0)

    self.velocity = self.velocity + self.acceleration * dt

    self.velocity.y = math.min(self.maxFallingVelocity, self.velocity.y)

    self.position = self.position + self.velocity * (dt / 2.0)

    self.parent:move(dx, dy)
    self.collisionBox:moveTo(self.position.x,
                             self.position.y - self.collisionBox.height/2)

end
