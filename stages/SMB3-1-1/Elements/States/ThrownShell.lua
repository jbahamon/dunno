local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local State = require 'data.core.Component.State'
local Walk = require 'stages.SMB3-1-1.Elements.States.Walk'

local ThrownShell = Class {
    name = "ThrownShell",
    __includes = Walk
}

function ThrownShell:onEnterFrom(previousState)
    self.hitDefBackup = previousState.hitDefBackup
    globals.Timer.add(
        4/60,
        function()
            self.owner.collision.hitDef = { 
                target = { 
                    Player = true, 
                    Neutral = true,
                    Enemy = true },
                hitType = "Weapon" }
        end
    )
end

function ThrownShell:onExitTo(nextState)
    self.owner.collision.hitDef = self.hitDefBackup
end

return ThrownShell 