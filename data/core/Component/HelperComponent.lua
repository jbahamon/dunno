--- A Component that represents an element's helper object (companion, special effects animations, etc).
-- @classmod data.core.Component.HelperComponent

local Class = require 'lib.hump.class'

local BaseComponent = require 'data.core.Component.BaseComponent'
local GameObjectFactory = require 'data.core.GameObjectFactory'

local HelperComponent = Class {
    name = 'HelperComponent',
    __includes = BaseComponent
}

-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Builds a new HelperComponent.
-- @class function
-- @name HelperComponent.__call
-- @tparam parameters table Parameters for the generated GameObject.
function HelperComponent:init(parameters)
    BaseComponent.init(self)
    self.parameters = parameters
end

function HelperComponent:addTo(container)
    BaseComponent.addTo(self, container)
    container:register("start", self)
end

function HelperComponent:start()
    self.factory = GameObjectFactory(
        self.parameters, 
        self.container.world.tileCollider, 
        self.container.world.activeCollider, 
        self.container.folder
    )
end


function HelperComponent:spawnObject()
    local newObject = self.factory:create()
    self.container.world:addObject(newObject)
    newObject:start()
    return newObject
end


return HelperComponent