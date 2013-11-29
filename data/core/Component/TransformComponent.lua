--- A Component that represents an element's position and orientation. Every GameObject has a TransformComponent.
-- @classmod data.core.Component.TransformComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'

local BaseComponent = require 'data.core.Component.BaseComponent'

local TransformComponent = Class {
    name = 'TransformComponent',
    __includes = BaseComponent
}

-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Builds a new TransformComponent.
-- @class function
-- @name TransformComponent.__call
-- @tparam[opt] vector position The starting position for the TransformComponent, as 
-- a vector. Optional (default is (0, 0))
-- @tparam number facing The starting facing for the TransformComponent. A 
-- facing value greater than zero means facing right; lesser than zero 
-- means facing left. Optional (default is facing right).
-- @treturn TransformComponent The newly created TransformComponent.

function TransformComponent:init(position, facing)
    BaseComponent.init(self)
    self.position = position or vector(0,0)
    self.facing = facing or 1
end    


--- Adds this component to a GameObject. This method registers
-- the move, moveTo, turn and changeToState methods with the container
-- GameObject. The TransformComponent will be added as the transform field of
-- the GameObject.
-- @tparam @{data.core.GameObject} container The GameObject this component is being added to.
function TransformComponent:addTo(container)
    BaseComponent.addTo(self, container)

    container:register("move", self)
    container:register("moveTo", self)
    container:register("turn", self)
    container.transform = self
end

-----------------------------------------------------------------
-- Positioning and dynamics
-- @section position

--- Moves the component by a certain amount, in pixels. 
-- @tparam vector displacement The displacement to be applied, in pixels.
function TransformComponent:move(displacement)
    self.lastPosition = self.position
    self.position = self.position + displacement
end

--- Moves the component to a certain position, in pixels. 
-- @tparam vector position The target position.
function TransformComponent:moveTo(position)
    self.lastPosition = self.position
    self.position = position:clone()
end

--- Flips the component horizontally.
function TransformComponent:turn()
    self.facing = -self.facing
end

return TransformComponent