--- A Component that represents a Piranha Plant's pipe.

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local HelperComponent = require 'data.core.Component.HelperComponent'
local GameObjectFactory = require 'data.core.GameObjectFactory'

local PipeComponent = Class {
    name = 'PipeComponent',
    __includes = HelperComponent
}

function PipeComponent:start()
    HelperComponent.start(self)
    local pipe = self:spawnObject()
    pipe:moveTo(self.container.transform.position)

end

return PipeComponent