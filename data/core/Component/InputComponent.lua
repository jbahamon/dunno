--- A game InputComponent implementation.
-- @class module
-- @name data.core.InputComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'

local Component = require 'data.core.Component'

--- Builds a new InputComponent with a collision box and no states.
-- @class function
-- @name InputComponent
-- @param bindings The key bindings to set, as a table.  See <a href="http://love2d.org/wiki/TLbind">TLbind's documentation</a> for details (under bind.keys).

local InputComponent = Class {
    name = 'InputComponent',
    __includes = Component
}

function InputComponent:init(bindings)
    Component.init(self)
    bindings = bindings or {
        w="up", a="left", s="down", d="right", [" "]="jump", lctrl="attack", escape="menu",
        up="up", left="left", down="down", right="right", z="jump", rctrl="attack", x="attack"
    }

    self.binds, self.control = love.filesystem.load("lib/TLBind.lua")()
    self.binds.keys = bindings
    self.hasControl = true
    
end    


-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Adds this component to a GameObject. This method registers
-- the update method with the container GameObject.
-- @param container The GameObject this component is being added to.
function InputComponent:addTo(container)
    Component.addTo(self, container)
    container:register("update", self)
    container.input = self
    container.control = self.control
end

--- Sets the player's bindings.
-- @param bindings The bindings to set, as a table.  See <a href="http://love2d.org/wiki/TLbind">TLbind's documentation</a> for details (under bind.keys).
function InputComponent:setControls(bindings) 
    self.binds.keys = bindings
end
-----------------------------------------------------------------
-- State handling
-- @section state

--- Updates the Component.
-- @param dt The time interval to apply to the Component.
function InputComponent:update(dt)
    self.binds:update()
     if self.hasControl then
        if (self.control["left"] and not self.control["right"]
                and self.container.transform.facing > 0)  or 
           (self.control["right"] and not self.control["left"]
                and self.container.transform.facing < 0) then
            self.container:turn()
        end
    end

    local acceleration = vector(0, 0)

    if self.hasControl then
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
    end

    if acceleration.x ~= 0 or acceleration.y ~= 0 then
        self.container.physics:addForce("input", acceleration, 0)
    end
end

function InputComponent:setControl(control)
    self.hasControl = control
end

return InputComponent