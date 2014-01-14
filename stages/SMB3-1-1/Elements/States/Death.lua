local Class = require 'lib.hump.class'
local State = require 'data.core.Component.State'

local Death = Class {
    name = "Death",
    __includes = State,
}

function Death:onEnterFrom(otherState)
    self.owner.collision:disable()
end

function Death:update(dt)
    if self.owner.physics.stateTime > self.dynamics.deathTime then
        self.owner.world:removeObject(self.owner)
    end
end

function Death:lateUpdate(dt)
    if (self.owner.physics.velocity.x > 0 and (not self.owner.collision.collisionFlags.canMoveRight)) or
        (self.owner.physics.velocity.x < 0 and (not self.owner.collision.collisionFlags.canMoveLeft)) then
        self.owner:turn()
        self.owner.physics.velocity.x = -self.owner.physics.velocity.x 
    end
end

return Death