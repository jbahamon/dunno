-- @class module
-- @name data.core.Component

local Class = require 'lib.hump.class'

--- Builds a Component
-- @class function
-- @name Component
-- @return The newly created Component
local Component = Class {
	name = "Component"
}

function Component:init()
end

-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Adds this Component to a GameObject. When defining your own components,
--  you should register the component's methods with the container 
--  object in this method. Remember calling the Component's (or the 
-- corresponding superclass) addTo method if you do this!
-- @param container The GameObject
function Component:addTo(container)
    assert(container, "Cannot add Component to nil object")
    self.container = container
end

return Component