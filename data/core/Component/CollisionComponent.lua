--- A Component that represents an element's collision box.
-- @classmod data.core.Component.CollisionComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local BaseComponent = require 'data.core.Component.BaseComponent'

local GeometryUtils = require 'lib.GeometryUtils'
local shapes = require 'lib.HardonCollider.shapes'

local CollisionComponent = Class {
    name = 'CollisionComponent',
    __includes = BaseComponent
}

-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Builds a new CollisionComponent.
-- @class function
-- @name CollisionComponent.__call
-- @tparam vector defaultSize The size of the CollisionComponent's default collision box, in pixels.
-- @treturn CollisionComponent The newly created CollisionComponent.

function CollisionComponent:init(defaultSize)
    BaseComponent.init(self)

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


function CollisionComponent:setHitDef(hitDef)
    if self.hitDef then
        self.hitDef.source = nil
    end

    self.hitDef = hitDef
    hitDef.source = self
end

--- Adds this component to a GameObject. This method registers
-- the move, moveTo, draw, changeToState, destroySelf and getHitBy methods
-- with the container GameObject. The CollisionComponent will be added as the collision field of
-- the GameObject.
-- @tparam @{data.core.GameObject} container The GameObject this component is being added to.
function CollisionComponent:addTo(container)
    BaseComponent.addTo(self, container)

    container:register("move", self)
    container:register("moveTo", self)
    container:register("draw", self)
    container:register("changeToState", self)
    container:register("destroySelf", self)
    container.collision = self
    self.box.hitsObjects = true
    self.box.hitsTiles = true
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
-- @tparam vector displacement The displacement to be applied in pixels.
function CollisionComponent:move(displacement)
    self.box:move(displacement:unpack())
end

--- Moves the CollisionComponent to a given location, in pixels.
-- The CollisionComponent's collision box is moved so that the CollisionComponent's
-- new position lies at the bottom-center of the collision box.
-- @tparam vector newPosition The target position in pixels.
function CollisionComponent:moveTo(newPosition)
    self.box:moveTo(newPosition.x, newPosition.y - (self.size.y)/2)
end

--- Returns the center of the CollisionComponent's collision box, in pixels.
-- @treturn vector The center's position.
function CollisionComponent:center()
    return vector(self.box:center())
end

-----------------------------------------------------------------
-- Drawing
-- @section drawing

--- If globals.DEBUG is set to <i>true</i>, this method draws the CollisionComponent's current collision box.
function CollisionComponent:draw()
    if not globals.DEBUG or not (self.box.hitsObjects or self.box.hitsTiles) then return end
    local x, y = self.box:center()
    love.graphics.setColor(0, 48, 255, 255)
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
-- If the Component already had colliders, it is removed from them.
-- @tparam @{lib.TileCollider} tileCollider The tileCollider to set.
-- @tparam HardonCollider activeCollider The activeCollider to set.
function CollisionComponent:setColliders(tileCollider, activeCollider)
    -- If we had colliders, we remove ourselves from them.
    if self.activeCollider and self.box then
        self.activeCollider:remove(self.box)
    end

    if self.tileCollider and self.box then
        self.tileCollider:remove(self.box)
    end

    -- We assign the colliders...
    self.tileCollider = tileCollider
    self.activeCollider = activeCollider

    if self.box then
        self.activeCollider:addShape(self.box)
        self.tileCollider:addShape(self.box)
    end
end

--- Calculates the displacement needed to move the CollisionComponent into a colliding box.
-- The movement is performed in the axis with the smallest distance to the target 
-- box. Useful for room transitions, for example.
-- @tparam Shape box The collision box to move the CollisionComponent into.
-- @treturn number The needed displacement that should be applied.
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
-- Essentially, it adds the collision event to the pendingCollisions field.
-- This function should not be overriden; if you want to implement your own collision
-- resolution for tiles, override @{CollisionComponent:resolveTileCollisions}.
-- @tparam number dt The time slice for the collision frame.
-- @tparam Tile tileCollisionComponent A sample tile that can be used to recreate the collision (should be removed).
-- @tparam Tile tile The tile CollisionComponent with which the CollisionComponent is colliding.
-- @tparam vector position The position of the colliding tile, measured in tiles.
-- @see CollisionComponent:resolveTileCollisions, CollisionComponent:resetCollisionFlags
function CollisionComponent:onTileCollide(dt, tileCollisionComponent, tile, position)

    local collisionEvent = { position = position:clone(), tile = tile }

    collisionEvent.area = GeometryUtils.getCollisionArea(tileCollisionComponent, self.box)

    table.insert(self.pendingCollisions, collisionEvent)
end

--- Resolves collisions with tiles.
-- Iterates over the registered collision events and resolves them appropriately.
-- This function can be overriden to implement custom tile collision resolution, but be careful
-- to treat every tile type.
-- @tparam Tile sampleTile A tile of the appropriate size that can be moved around to simulate 
-- the collisions.
-- @tparam vector tileSize A vector that contains the size of the stage's tiles, in pixels.
-- @see CollisionComponent:onTileCollide, CollisionComponent:resetCollisionFlags
function CollisionComponent:resolveTileCollisions(sampleTile, tileSize)

    table.sort(self.pendingCollisions, function(a, b)
                                            return a.area > b.area
                                        end)
    local collides, dx, dy
    local highestLadderEvent

    local transform = self.container.transform

    for idx, event in pairs(self.pendingCollisions) do
    -- FIXME - this should be improved

        sampleTile:moveTo((event.position:permul(tileSize) + tileSize/2.0):unpack())

        collides, dx, dy = self.box:collidesWith(sampleTile)

        if collides then
            
            if event.tile.properties.deadly then
                self.collisionFlags.hit = true
            end    

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

                self:onSolidCollide(dx, dy)

                local centerX, centerY = self.box:center()

                if sampleTile:intersectsRay(centerX, centerY, 0, 200) then
                    self.collisionFlags.standingOnSolid = true
                end

            elseif event.tile.properties.oneWayPlatform then
                
                local verticalDisplacement = event.position.y * tileSize.y - transform.position.y
                
                if event.position.y * tileSize.y >= transform.lastPosition.y then
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
                
    if highestLadderEvent and highestLadderEvent.position.y * tileSize.y >= transform.lastPosition.y then
        self.container:moveTo(vector(transform.position.x, highestLadderEvent.position.y * tileSize.y))
        self.collisionFlags.canMoveDown = false
        self.collisionFlags.specialEvents.standingOnLadder = self.collisionFlags.specialEvents.ladder
        self.collisionFlags.specialEvents.ladder = nil
    end

end

function CollisionComponent:onSolidCollide(dx, dy)
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

            if self.container.physics then
                self.container.physics.velocity.y = math.max(self.container.physics.velocity.y, 0)
            end
        elseif dy < 0 then 
            self.collisionFlags.canMoveDown = false
        end
    end
end

--- Called when colliding with an active CollisionComponent in the world (interactive CollisionComponent, enemy, etc).
-- Currently calls getHitBy onthe other CollisionComponent's container if this CollisionComponent damages on contact.
-- Each 
-- @tparam vector displacement The separating vector between
-- @tparam number dt The time slice for the collision frame.
-- @tparam @{data.core.Component.CollisionComponent} otherCollisionComponent The CollisionComponent that is colliding with this one.
function CollisionComponent:onDynamicCollide(dt, dx, dy, otherCollisionComponent)
    if otherCollisionComponent.container == self.container then
        return
    end

    if self.hitDef then
        otherCollisionComponent.container.collision:getHitBy(self.hitDef)
    end

    if self.container.elementType == otherCollisionComponent.container.elementType and
        not (self.passesThroughAllies or otherCollisionComponent.passesThroughAllies) then
        self:onSolidCollide(dx, dy)
    end
end


--- Called when hit by something (read: something that does damage)-
-- Currently sets the hit flag in the collisionFlags field.
-- @tparam table hitDef The table that defines the hit.
function CollisionComponent:getHitBy(hitDef)

    if self.invincible then return "dodge" end

    if hitDef.target[self.container.elementType] then
        self.collisionFlags.hit = true
        return "hit"
    else
        return "dodge"
    end
end

--- Sets the current collision box for the CollisionComponent.
-- @tparam vector newSize The size of the new collision box in pixels.
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
    self.box.hitsTiles = true
end

--- Disables the CollisionComponent's collisions against tiles.
-- @see CollisionComponent:enableTileCollisions
function CollisionComponent:disableTileCollisions()
    self.box.hitsTiles = false
end

--- Enables the CollisionComponent's collisions against tiles.
-- @see CollisionComponent:disableTileCollisions
function CollisionComponent:enableTileCollisions()
    self.box.hitsTiles = true
end


--- Disables the CollisionComponent's collisions against objects.
-- @see CollisionComponent:enableDynamicCollisions
function CollisionComponent:disableDynamicCollisions()
    if self.box.hitsObjects then
        self.box.hitsObjects = false
        self.activeCollider:setGhost(self.box)
    end
end

--- Enables the CollisionComponent's collisions against objects.
-- @see CollisionComponent:disableDynamicCollisions
function CollisionComponent:enableDynamicCollisions()
    if not self.box.hitsObjects then
        self.box.hitsObjects = true
        self.activeCollider:setSolid(self.box)
    end
end

--- Enables all collisions for this CollisionComponent.
-- @see CollisionComponent:disable
function CollisionComponent:enable()
    self:enableDynamicCollisions()
    self:enableTileCollisions()
end


--- Disables all collisions for this CollisionComponent.
-- @see CollisionComponent:disable
function CollisionComponent:disable()
    self:disableDynamicCollisions()
    self:disableTileCollisions()
end

return CollisionComponent