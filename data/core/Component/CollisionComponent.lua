--- A game CollisionComponent implementation.
-- @class module
-- @name data.core.CollisionComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local Component = require 'data.core.Component'

local GeometryUtils = require 'lib.GeometryUtils'
local shapes = require 'lib.HardonCollider.shapes'


--- Builds a new CollisionComponent with a collision box and no states.
-- @class function
-- @name CollisionComponent
-- @param defaultSize The size of the CollisionComponent's default collision box, as a vector, in pixels.
-- @return The newly created CollisionComponent.

local CollisionComponent = Class {
    name = 'CollisionComponent'
}

function CollisionComponent:init(defaultSize)
    Component.init(self)

    self.defaultSize = defaultSize
    self:setCollisionBox(self.defaultSize)

    -- Collision flags
    self.collisionFlags = { canMoveLeft = true,
                            canMoveRight = true,
                            canMoveUp = true,
                            canMoveDown = true,
                            specialEvents = {}}

    self.pendingCollisions = {}
end    
-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Adds this component to a GameObject. This method registers
-- the move, moveTo, start, draw, changeToState and destroySelf methods
-- with the container GameObject.
-- @param container The GameObject this component is being added to.
function CollisionComponent:addTo(container)
    Component.addTo(self, container)

    container:register("move", self)
    container:register("moveTo", self)
    container:register("draw", self)
    container:register("changeToState", self)
    container:register("destroySelf", self)
    container.collision = self
end

--- Allows this object to be garbage-collected
function CollisionComponent:destroySelf()
    self.tileCollider:remove(self.box)
    self.activeCollider:remove(self.box)
end


-----------------------------------------------------------------
--- Positioning, dynamics
-- @section dynamics

--- Moves the CollisionComponent by a certain amount, in pixels.
-- @param displacement The displacement to be applied, as a hump vector, in pixels.
function CollisionComponent:move(displacement)
    self.box:move(displacement:unpack())
end

--- Moves the CollisionComponent to a given location, in pixels.
-- The CollisionComponent's collision box is moved so that the CollisionComponent's
-- new position lies at the bottom-center of the collision box.
-- @param newPosition The target position, as a hump vector, in pixels.
function CollisionComponent:moveTo(newPosition)
    self.box:moveTo(newPosition.x, newPosition.y - (self.size.y)/2)
end

--- Returns the center of the CollisionComponent's collision box, in pixels.
-- @return The center's position, as a vector.
function CollisionComponent:center()
    return vector(self.box:center())
end

-----------------------------------------------------------------
-- Drawing
-- @section drawing

--- If globals.DEBUG is set to <i>true</i>, the CollisionComponent's collision box is drawn.
function CollisionComponent:draw()
    if not globals.DEBUG then return end
    local x, y = self.box:center()
    love.graphics.setColor(0, 48, 255, 255)
    love.graphics.rectangle("line", x - self.size.x/2, y - self.size.y/2, self.size.x, self.size.y)
    love.graphics.setColor(255, 255, 255, 255)
end

-----------------------------------------------------------------
-- State handling
-- @section state

--- Called when the container GameObject changes state.
-- This method changes the component's collision box to the target state's collision box.
-- @param nextState The target state.
function CollisionComponent:changeToState(nextState)

    if nextState.size and
        (self.size.x ~= nextState.size.x or
         self.size.y ~= nextState.size.y) then
        
        self:setCollisionBox(nextState.size)

    end

    if (not nextState.size) and 
       (self.size.x ~= self.defaultSize.x or
        self.size.y ~= self.defaultSize.y) then

       self:setCollisionBox(self.defaultSize)

    end

end


-----------------------------------------------------------------
-- Collision handling
-- @section collision

--- Sets the colliders for this CollisionComponent, adding the current collision box to them.
-- @param tileCollider The tileCollider to set.
-- @param activeCollider The activeCollider to set.
function CollisionComponent:setColliders(tileCollider, activeCollider)
    -- If we had colliders, we remove ourselves from them.
    if self.activeCollider then
        self.activeCollider:remove(self.box)
    end

    if self.tileCollider then
        self.tileCollider:remove(self.box)
    end

    -- We assign the colliders...
    self.tileCollider = tileCollider
    self.activeCollider = activeCollider

    self.activeCollider:addShape(self.box)
    self.tileCollider:addShape(self.box)
end

--- Calculates the displacement needed to move the CollisionComponent into a colliding box.
-- The movement is performed in the axis with the smallest distance to the target 
-- box. Useful for room transitions, for example.
-- @param box The collision box to move the CollisionComponent into.
-- @return The needed displacement that should be applied.
function CollisionComponent:movementIntoCollidingBox(box)
    local collides, dx, dy = self.box:collidesWith(box)

    if not collides then
        return
    end

    local ownCenter = self:center()
    local boxCenter = vector(box:center())

    local displacement, direction
    
    direction = 1

    if math.abs(dx) > math.abs(dy) then

        if ownCenter.x >= boxCenter.x then
            direction = -1 * direction
        end

        displacement = vector((self.size.x - math.abs(dx)) + 1, 0)
    else
        
        if ownCenter.y >= boxCenter.y then
            direction = -1 * direction
        end

        displacement = vector(0, (self.size.y - math.abs(dy)) + 1)
    end

    return (displacement * direction)

end


--- Resets the CollisionComponent's collision flags. 
function CollisionComponent:resetCollisionFlags()
    self.collisionFlags = {
        canMoveLeft = true,
        canMoveRight = true,
        canMoveUp = true,
        canMoveDown = true,
        specialEvents = {}
    }

    self.pendingCollisions = {}
end

--- Called when colliding with a tile from the stage's collision layer. 
-- Essentially, adds the collision event to the pendingCollisions field.
-- This function should not be overriden; if you want to implement your own collision
-- resolution for tiles, override @{CollisionComponent:resolveTileCollisions}.
-- @param dt The time slice for the collision frame.
-- @param tileCollisionComponent A sample tile that can be used to recreate the collision (should be removed).
-- @param tile The tile CollisionComponent with which the CollisionComponent is colliding.
-- @param position The position of the colliding tile, measured in tiles, as a hump vector.
-- @see CollisionComponent:resolveTileCollisions, CollisionComponent:resetCollisionFlags
function CollisionComponent:onTileCollide(dt, tileCollisionComponent, tile, position)

    if tile.properties.solid or tile.properties.oneWayPlatform or tile.properties.ladder then
        
        local collisionEvent = { position = position:clone(), tile = tile }

        collisionEvent.area = GeometryUtils.getCollisionArea(tileCollisionComponent, self.box)

        table.insert(self.pendingCollisions, collisionEvent)

    end
end

--- Resolves collisions with tiles.
-- Iterates over the registered collision events and resolves them appropriately.
-- This function can be overriden to implement custom tile collision resolution.
-- @param sampleTile A tile of the appropriate size that can be moved around to simulate 
-- the collisions.
-- @param tileSize A vector that contains the size of the stage's tiles, in pixels.
-- @see CollisionComponent:onTileCollide, CollisionComponent:resetCollisionFlags
function CollisionComponent:resolveTileCollisions(sampleTile, tileSize)

    table.sort(self.pendingCollisions, function(a, b)
                                            return a.area > b.area
                                        end)
    local collides, dx, dy
    local highestLadderEvent

    for idx, event in pairs(self.pendingCollisions) do
    -- FIXME - this should be improved

        sampleTile:moveTo((event.position:permul(tileSize) + tileSize/2.0):unpack())

        collides, dx, dy = self.box:collidesWith(sampleTile)

        if collides then

            if event.tile.properties.ladder then
                if (not highestLadderEvent) or highestLadderEvent.position.y > event.position.y then
                    highestLadderEvent = event
                end
                
                local centerX, centerY = self.box:center()
                if sampleTile:intersectsRay(centerX, centerY, 0, -1) or
                    sampleTile:intersectsRay(centerX, centerY, 0, 1) then

                    if not self.collisionFlags.specialEvents.ladder then
                        self.collisionFlags.specialEvents.ladder = { position = vector(sampleTile:center()), CollisionComponent = self}
                    end
                end
            end    

            if event.tile.properties.solid then 

                self.container:move(vector(dx, dy))
                if math.abs(dx) > math.abs(dy) then
                    if dx > 0 then 
                        self.collisionFlags.canMoveLeft = false
                    elseif dx < 0 then
                        self.collisionFlags.canMoveRight = false
                    end
                else
                    if dy > 0 then 
                        self.collisionFlags.canMoveUp = false
                        self.container.physics.velocity.y = math.max(self.container.physics.velocity.y, 0)
                    elseif dy < 0 then 
                        self.collisionFlags.canMoveDown = false
                    end
                end

                local centerX, centerY = self.box:center()

                if sampleTile:intersectsRay(centerX, centerY, 0, 200) then
                    self.collisionFlags.standingOnSolid = true
                end

            elseif event.tile.properties.oneWayPlatform then
                
                local verticalDisplacement = event.position.y * tileSize.y - self.container.transform.position.y
                
                if event.position.y * tileSize.y >= self.container.transform.lastPosition.y then
                    self.container:move(vector(0, verticalDisplacement))
                    self.collisionFlags.canMoveDown = false

                    local centerX, centerY = self.box:center()

                    if sampleTile:intersectsRay(centerX, centerY, 0, 200) then
                        self.collisionFlags.standingOnSolid = true
                    end
                end
            end     
        end
    end
                
    if highestLadderEvent and highestLadderEvent.position.y * tileSize.y >= self.container.transform.lastPosition.y then
        self.container:moveTo(vector(self.container.transform.position.x, highestLadderEvent.position.y * tileSize.y))
        self.collisionFlags.canMoveDown = false
        self.collisionFlags.specialEvents.standingOnLadder = self.collisionFlags.specialEvents.ladder
        self.collisionFlags.specialEvents.ladder = nil
    end

end

--- Called when colliding with an active CollisionComponent in the world (interactive CollisionComponent, enemy, etc).
-- Currently calls getHitBy on the other CollisionComponent if this CollisionComponent damages on contact.
-- @param dt The time slice for the collision frame.
-- @param box This CollisionComponent's colliding box.
-- @param otherCollisionComponent The CollisionComponent that is colliding with this one.
function CollisionComponent:onDynamicCollide(dt, otherCollisionComponent)
    if otherCollisionComponent == self then
        return
    end

    if self.damagesOnContact then
        otherCollisionComponent:getHitBy(self.parent)
    end
end

function CollisionComponent:getHitBy(otherObject)
    if not self.invincible then
        self.collisionFlags.hit = true
        print("wow")
    end
end

--- Sets the current collision box for the CollisionComponent.
-- @param newSize The size of the new collision box.
-- @see CollisionComponent:getCollisionBox
function CollisionComponent:setCollisionBox(newSize)

    if self.box then
        self.activeCollider:remove(self.box)
        self.tileCollider:remove(self.box)
    end

    self.size = newSize

    local collisionBox = shapes.newPolygonShape(
        - math.floor(self.size.x/2), 0,
          math.ceil(self.size.x/2), 0,
          math.ceil(self.size.x/2), - self.size.y,
        - math.floor(self.size.x/2), - self.size.y)

    if self.container then
        collisionBox:moveTo((self.container.transform.position - vector(0, self.size.y/2)):unpack())
    end

    if self.activeCollider and self.tileCollider then
        self.activeCollider:addShape(collisionBox)
        self.tileCollider:addShape(collisionBox)
    end

    self.box = collisionBox
    self.box.parent = self
    self.box.active = true
end

--- Disables the CollisionComponent's collisions against tiles.
-- @see CollisionComponent:enableTileCollisions
function CollisionComponent:disableTileCollisions()
    self.box.active = false
end

--- Enables the CollisionComponent's collisions against tiles.
-- @see CollisionComponent:disableTileCollisions
function CollisionComponent:enableTileCollisions()
    self.box.active = true
end

return CollisionComponent