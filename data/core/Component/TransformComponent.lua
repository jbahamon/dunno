--- A game TransformComponent implementation.
-- @class module
-- @name data.core.TransformComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'

local Component = require 'data.core.Component'

--- Builds a new TransformComponent with a collision box and no states.
-- @class function
-- @name TransformComponent
-- @param position The starting position for the TransformComponent, as 
-- a vector.
-- @param facing The starting facing for the TransformComponent. A 
-- facing value greater than zero means facing right; lesser than zero 
-- means facing left.
-- @return The newly created TransformComponent.

local TransformComponent = Class {
    name = 'TransformComponent',
    __includes = Component
}

function TransformComponent:init(position, facing)
    Component.init(self)
    self.position = position or vector(0,0)
    self.facing = facing or 1
end    

-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Adds this component to a GameObject. This method registers
-- the move, moveTo, turn and changeToState methods with the container
-- GameObject.
-- @param container The GameObject this component is being added to.
function TransformComponent:addTo(container)
    Component.addTo(self, container)

    container:register("move", self)
    container:register("moveTo", self)
    container:register("turn", self)
    container.transform = self
end

-----------------------------------------------------------------
-- Positioning and dynamics
-- @section position

--- Moves the component by a certain amount, in pixels. 
-- @param displacement The displacement to be applied, as a hump vector, in pixels.
function TransformComponent:move(displacement)
    self.lastPosition = self.position
    self.position = self.position + displacement
end

--- Moves the component to a certain position, in pixels. 
-- @param position The target position, as a hump vector.
function TransformComponent:moveTo(position)
    self.lastPosition = self.position
    self.position = position:clone()
end

--- Flips the component horizontally.
function TransformComponent:turn()
    self.facing = -self.facing
end

return TransformComponent