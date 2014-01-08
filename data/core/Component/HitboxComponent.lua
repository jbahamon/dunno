--- A Component that represents an element's collision box.
-- @classmod data.core.Component.HitboxComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local BaseComponent = require 'data.core.Component.BaseComponent'

local GeometryUtils = require 'lib.GeometryUtils'
local shapes = require 'lib.HardonCollider.shapes'

local HitboxComponent = Class {
    name = 'HitboxComponent',
    __includes = BaseComponent
}

-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Builds a new HitboxComponent.
-- @class function
-- @name HitboxComponent.__call
-- @tparam vector defaultSize The size of the HitboxComponent's default collision box, in pixels.
-- @treturn HitboxComponent The newly created HitboxComponent.

function HitboxComponent:init(parameters)
    BaseComponent.init(self)

    self.defaultSize = parameters.defaultSize or vector(1,1)
    self.defaultOffset = parameters.defaultOffset or vector(0, 0)
    self:setCollisionBox(self.defaultSize)

end    

--- Adds this component to a GameObject. This method registers
-- the move, moveTo, draw, changeToState, destroySelf and getHitBy methods
-- with the container GameObject. The HitboxComponent will be added as the collision field of
-- the GameObject.
-- @tparam @{data.core.GameObject} container The GameObject this component is being added to.
function HitboxComponent:addTo(container)
    BaseComponent.addTo(self, container)

    container:register("start", self)
    container:register("move", self)
    container:register("moveTo", self)
    container:register("draw", self)
    container:register("changeToState", self)
    container:register("destroySelf", self)
    self.offset = self.defaultOffset
    self.size = self.defaultSize
    
end

function HitboxComponent:start()
    self:setCollider(self.container.world:getActiveCollider())
end

--- Allows this object to be garbage-collected
function HitboxComponent:destroySelf()
    self.activeCollider:remove(self.box)
end


-----------------------------------------------------------------
--- Positioning, dynamics
-- @section dynamics

--- Moves the HitboxComponent by a certain amount, in pixels.
-- @tparam vector displacement The displacement to be applied in pixels.
function HitboxComponent:move(displacement)
    if self.active then
        self.box:move(displacement:unpack())
    end
end

--- Moves the HitboxComponent to a given location, in pixels.
-- The HitboxComponent's collision box is moved so that the HitboxComponent's
-- new position lies at the bottom-center of the collision box.
-- @tparam vector newPosition The target position in pixels.
function HitboxComponent:moveTo(newPosition)
    if self.active then
        local targetPosition = newPosition + self.offset
        self.box:moveTo(targetPosition:unpack())
    end

end

--- Returns the center of the HitboxComponent's collision box, in pixels.
-- @treturn vector The center's position.
function HitboxComponent:center()
    return vector(self.box:center())
end

-----------------------------------------------------------------
-- Drawing
-- @section drawing

--- If globals.DEBUG is set to <i>true</i>, this method draws the HitboxComponent's current collision box.
function HitboxComponent:draw()
    if not globals.DEBUG then return end
    local x, y = self.box:center()
    love.graphics.setColor(255, 48, 0, 255)
    love.graphics.rectangle("line", x - self.size.x/2, y - self.size.y/2, self.size.x, self.size.y)
    love.graphics.setColor(255, 255, 255, 255)
end

-----------------------------------------------------------------
-- State handling
-- @section state

--- Called when the container GameObject changes state.
-- This method changes the component's collision box to the target state's 
-- collision box if it differs from the current one.
-- @tparam @{data.core.Component.State} nextState The target state.
function HitboxComponent:changeToState(nextState)
    if nextState.hitbox and vector.isvector(nextState.hitbox) then
        if not self.active then
            self:enable()
        end

        if (self.size.x ~= nextState.hitbox.x or
             self.size.y ~= nextState.hitbox.y) then
            self:setCollisionBox(nextState.hitbox)
        end        
    end

    if (not nextState.hitbox) and self.active then
       self:disable()
    end

    self.offset = nextState.hitBoxOffset or self.defaultOffset
    

end


-----------------------------------------------------------------
-- Collision handling
-- @section collision

--- Sets the colliders for this HitboxComponent, adding the current collision box to them. 
-- If the Component already had colliders, it is removed from them.
-- @tparam @{lib.TileCollider} tileCollider The tileCollider to set.
-- @tparam HardonCollider activeCollider The activeCollider to set.
function HitboxComponent:setCollider(activeCollider)
    -- If we had colliders, we remove ourselves from them.
    if self.activeCollider and self.box then
        self.activeCollider:remove(self.box)
    end

    -- We assign the colliders...
    self.activeCollider = activeCollider

    if self.box then
        self.activeCollider:addShape(self.box)
    end
end

--- Called when colliding with an active HitboxComponent in the world (interactive HitboxComponent, enemy, etc).
-- Currently calls getHitBy onthe other HitboxComponent's container if this HitboxComponent damages on contact.
-- Each 
-- @tparam vector displacement The separating vector between
-- @tparam number dt The time slice for the collision frame.
-- @tparam @{data.core.Component.HitboxComponent} HitboxisionComponent The HitboxComponent that is colliding with this one.
function HitboxComponent:onDynamicCollide(dt, dx, dy, otherComponent)
    if self.active then
        otherComponent.container:getHitBy(self.parent)
    end
end


--- Sets the current collision box for the HitboxComponent.
-- @tparam vector newSize The size of the new box in pixels.
-- @tparam vector newOffset The new offset to apply to the box, in pixels.
function HitboxComponent:setCollisionBox(newSize, newOffset)

    if self.box then
        self.activeCollider:remove(self.box)
    end

    self.size = newSize

    local collisionBox = shapes.newPolygonShape(
        - math.floor(self.size.x/2), 0,
          math.ceil(self.size.x/2), 0,
          math.ceil(self.size.x/2), - self.size.y,
        - math.floor(self.size.x/2), - self.size.y)

    if self.container then
        collisionBox:moveTo((self.container.transform.position + self.offset):unpack())
    end

    if self.activeCollider then
        self.activeCollider:addShape(collisionBox)
    end

    self.box = collisionBox
    self.box.parent = self
    self.box.active = true
end

--- Disables the HitboxComponent's collisions against other objects.
-- @see HitboxComponent:disable
function HitboxComponent:enable()

    -- By default, the shape is solid, so it would throw an
    -- error by setting it as solid again. We use the fact
    -- that nil != false to avoid this.
    if self.active == false then
        self.activeCollider:setSolid(self.box)
    end

    self.active = true
    self:moveTo(self.container.transform.position)
    

end

--- Disables the HitboxComponent's collisions against other objects.
-- @see HitboxComponent:enable
function HitboxComponent:disable()
    self.activeCollider:setGhost(self.box)
    self.active = false
end

return HitboxComponent