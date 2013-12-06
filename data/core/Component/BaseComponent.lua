--- The base class for all BaseComponents of a GameObject. 
-- A Component represents a distinct functionality and/or characteristic of a GameObject. 
-- See other classes of the Component module for examples.
-- @classmod data.core.Component.BaseComponent

local Class = require 'lib.hump.class'

local BaseComponent = Class {
	name = "BaseComponent"
}

--- Builds a BaseComponent.
-- @class function
-- @name BaseComponent.__call
-- @treturn BaseComponent The newly created BaseComponent

function BaseComponent:init()
end

--- Adds this BaseComponent to a GameObject. When defining your own Basecomponents,
--  you should register the Basecomponent's methods with the container 
--  object in this method. Remember calling the BaseComponent's (or the 
-- corresponding superclass) addTo method if you do this!
-- @tparam @{data.core.GameObject} container The GameObject this Basecomponent will be added to.
function BaseComponent:addTo(container)
    assert(container, "Cannot add BaseComponent to nil object")
    self.container = container
end

return BaseComponent