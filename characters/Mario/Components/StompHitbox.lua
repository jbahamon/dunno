local Class = require 'lib.hump.class'

local HitboxComponent = require 'data.core.Component.HitboxComponent'

local StompHitbox = Class {
    name = 'StompHitbox',
    __includes = HitboxComponent
}

function StompHitbox:onDynamicCollide(dt, dx, dy, otherComponent)
    if otherComponent.container == self.container then return end
    local otherYVelocity = 0

    if otherComponent.container.physics then
        otherYVelocity = otherComponent.container.physics.velocity.y
    end

    if (self.container.physics.velocity.y - otherYVelocity) > 0 then
        HitboxComponent.onDynamicCollide(self, dt, dx, dy, otherComponent)
    end
end


function StompHitbox:onHit()
    HitboxComponent.onHit(self)
    self.container.collision.collisionFlags.stomped = true
end

return StompHitbox