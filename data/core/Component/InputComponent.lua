--- A Component that represents keyboard input for a GameObject.
-- @classmod data.core.Component.InputComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local BaseComponent = require 'data.core.Component.BaseComponent'

-----------------------------------------------------------------
--- Building and destroying
-- @section building


local function InputComponent()
end

local InputComponent = Class {
    name = 'InputComponent',
    __includes = BaseComponent
}

--- Builds a new InputComponent with the given bindings, or default ones.
-- The default bindings are as follows: WASD and arrows can be used as 
-- the direction buttons; Space and Z can be used as the jump button, and 
-- Right Control and X can be used as the special/attack button.
-- @class function
-- @name InputComponent.__call
-- @tparam table bindings The key bindings to set, as a table. 
-- @return InputComponent The newly created InputComponent.
-- See <a href="http://love2d.org/wiki/TLbind">TLbind's documentation</a> for details (under bind.keys).
function InputComponent:init(bindings)
    BaseComponent.init(self)
    bindings = bindings or {
        w="up", a="left", s="down", d="right", [" "]="jump", lctrl="attack", escape="menu",
        up="up", left="left", down="down", right="right", z="jump", rctrl="attack", x="attack"
    }

    self.binds, self.control = love.filesystem.load("lib/TLBind.lua")()
    self.binds.keys = bindings
    self.hasControl = true
    
end    

--- Adds this component to a GameObject. This method registers
-- the update method with the container GameObject. The InputComponent will 
-- be added as the input field of the GameObject.
-- @tparam @{data.core.GameObject} container The GameObject this component is being added to.
function InputComponent:addTo(container)
    BaseComponent.addTo(self, container)
    container:register("update", self)
    container.input = self
    container.control = self.control
end

--- Sets the player's bindings.
-- @tparam table bindings The bindings to set, as a table.  See <a href="http://love2d.org/wiki/TLbind">TLbind's documentation</a> for details (under bind.keys).
function InputComponent:setBindings(bindings) 
    self.binds.keys = bindings
end
-----------------------------------------------------------------
-- State handling
-- @section state

--- Updates the InputComponent, applying control physics if necessary.
-- @tparam number dt The time interval to apply to the Component.
function InputComponent:update(dt)
    self.binds:update()
    if self.container.physics and self.hasControl then
        if (self.control["left"] and not self.control["right"]
                and self.container.transform.facing > 0 and self.container.physics.velocity.x < 0)  or 
           (self.control["right"] and not self.control["left"]
                and self.container.transform.facing < 0 and self.container.physics.velocity.x > 0) then
            self.container:turn()
        end

        local acceleration = vector(0, 0)

        if self.control["up"] and not self.control["down"] then
            acceleration.y = acceleration.y - self.container.physics.parameters.inputAcceleration.y
        elseif self.control["down"] then
            acceleration.y = acceleration.y + self.container.physics.parameters.inputAcceleration.y
        end


        if self.control["left"] and not self.control["right"] then
            acceleration.x = acceleration.x - self.container.physics.parameters.inputAcceleration.x 
        elseif self.control["right"] then
            acceleration.x = acceleration.x + self.container.physics.parameters.inputAcceleration.x 
        end     

        if acceleration.x ~= 0 or acceleration.y ~= 0 then
            self.container.physics:addForce("input", acceleration, 0)
        end
    end
end

--- Sets the control flag for the Component. A value of false will disable input.
-- @tparam bool control The value for the control flag.
function InputComponent:setControl(control)
    self.hasControl = control
end

return InputComponent