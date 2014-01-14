local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local State = require 'data.core.Component.State'

local Shell = Class {
    name = "Shell",
    __includes = State
}

function Shell:onEnterFrom(previousState)

    self.hitDefBackup = self.owner.collision.hitDef    
    self.owner.collision.hitDef = nil
    self.owner.physics.velocity.x = 0
    self.owner.collision.passesThroughAllies = true


    self.collideBackup = self.owner.collision.onDynamicCollide
    self.owner.collision.onDynamicCollide = self:makeOnDynamicCollide()

end

function Shell:onExitTo(nextState)
    if nextState.name ~= "thrownShell" then
        self.owner.collision.hitDef = self.hitDefBackup
        self.owner.collision.passesThroughAllies = false
    end

    self.owner.collision.onDynamicCollide = self.collideBackup
end

function Shell:makeOnDynamicCollide()

    return function(collisionComponent, dt, dx, dy, otherComponent)
        if otherComponent.container.elementType == "Player" then
            collisionComponent.collisionFlags.touchedFrom = 
                collisionComponent.container.transform.position.x - otherComponent.container.transform.position.x
        end
        self.collideBackup(collisionComponent, dt, dx, dy, otherComponent)
    end

end


return Shell 