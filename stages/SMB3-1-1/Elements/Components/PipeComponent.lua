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
    self.pipe = self:spawnObject()
    self.pipe:moveTo(self.container.transform.position + vector(0, 10))

end

function PipeComponent:destroySelf()
    if self.pipe then
        self.pipe:destroySelf()
    end
end

return PipeComponent