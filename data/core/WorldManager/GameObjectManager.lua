--- GameObjectManager implementation.
-- @class module
-- @name data.core.GameObjectManager

local Class = require 'lib.hump.class'

local Loader = globals.Loader

local ActiveCollider = require 'lib.HardonCollider'
local TileCollider = require 'lib.TileCollider'

local vector = require 'lib.hump.vector'

local Timer = globals.Timer


--- Builds a new, empty GameObjectManager
-- @class function
-- @name GameObjectManager
-- @return The newly created GameObjectManager
local GameObjectManager = Class {
    name = "GameObjectManager"
}

function GameObjectManager:init(world)
    self.world = world
    self.managedObjects = {}
    self.updatableObjects = {}
    self.lateUpdatableObjects = {}
    self.players = {}
end

--- Class that handles interactions between the Stage, the Player(s) and 
-- other Elements. It uses an instance of @{CameraManager} to handle the camera.
-- @type GameObjectManager

-----------------------------------------------------------------
-- World building
-- @section building

--- Starts the GameObjectManager and all of its elements (player, enemies, etc)
function GameObjectManager:start(stage)

    local startingPosition = stage:getPixelStartingPosition()
    -- Stage startup
    self.tileCollider = TileCollider(stage)
    self.activeCollider = ActiveCollider(100, self.onDynamicCollide)

    for _, managedObject in ipairs(self.managedObjects) do
        if managedObject.collision then
            managedObject.collision:setColliders(self.tileCollider, self.activeCollider)
        end

        managedObject:start()

    end

    for _, player in ipairs(self.players) do
        player:moveTo(startingPosition)
    end
end

--- Adds a GameObject to the GameObjectManager.
-- @param playerName The name of the player's folder
function GameObjectManager:addObject(newObject)
    
    table.insert(self.managedObjects, newObject)
    if newObject.update then
        table.insert(self.updatableObjects, newObject)
    end

    if newObject.lateUpdate then
        table.insert(self.lateUpdatableObjects, newObject)
    end
end

--- Adds a Player GameObject to the GameObjectManager. 
-- Do not call @{GameObjectManager:addObject} on a player object if you use this.
-- @param playerName The name of the player's folder
function GameObjectManager:addPlayer(newPlayer)
    self:addObject(newPlayer)
    table.insert(self.players, newPlayer)
end

-----------------------------------------------------------------
-- Drawing and updating
-- @section draw

--- Updates all of the GameObjects managed by the GameObjectManager, as well as the colliders
-- and the camera.
-- @param dt The time slice for the update.
function GameObjectManager:update(dt)
    for _, gameObject in ipairs(self.updatableObjects) do
        gameObject:update(dt)
    end
    
    -- Collisions between a dynamic object and
    -- a static object (ie an interactive tile)
    -- are handled by our own module
    self.tileCollider:update(dt)
    
    -- Collisions between dynamic objects are
    -- handled by HardonCollider
    self.activeCollider:update(dt)
    
    -- Now the late updates
    for _, gameObject in ipairs(self.lateUpdatableObjects) do
        gameObject:lateUpdate(dt)
    end

end

function GameObjectManager:refreshObjectSpawning(topLeft, bottomRight) 
    
    for i, obj in ipairs(self.managedObjects) do

        if self.managedObjects.elementType ~= "Player" then
            local offscreen = (obj.collision and (not GeometryUtils.isBoxInRange(obj.collision.box, topLeft -  vector(32, 32), bottomRight +  vector(32, 32))))
                or not GeometryUtils.isPointInRange(obj.transform.position, topLeft -  vector(32, 32), bottomRight +  vector(32, 32))

            if offscreen then
                
                if elem.elementLocation.onExitScreen then
                    elem.elementLocation.onExitScreen(elem)
                end
                
                elem:destroySelf()
                table.remove(self.managedObjects, i)
            end
        end
    end

    for _, elementLocation in ipairs(self.elementLocations) do
                
        if elementLocation.enabled then

            if (not elementLocation.onScreen) and 
                GeometryUtils.isBoxInRange(elementLocation.shape, topLeft, bottomRight) then
                self:elementLocationOnScreen(elementLocation)

            end

            if elementLocation.onScreen and 
                (not GeometryUtils.isBoxInRange(elementLocation.shape, topLeft, bottomRight)) then

                self:elementLocationOffScreen(elementLocation)

            end
        end
    end
end

-----------------------------------------------------------------
-- Effects
-- @section effects

--- Pauses the game. While the game is paused, nothing moves by itself: 
-- no update functions are called.
-- @param time (Optional) The time for which the game will be paused, in seconds. If omitted, 
-- the game will be paused until @{GameObjectManager:unPauseGame} is called.
function GameObjectManager:pauseGame(time)
    self.paused = true
    if time then 
        self.pauseTimer = Timer.add(time, function() self.paused = false end )
    end

end

--- Unpauses the game. Update functions will start being called again after this function is called.
function GameObjectManager:unPauseGame()
    self.paused = false
    if self.pauseTimer then
        Timer.cancel(self.pauseTimer)
        self.pauseTimer = nil
    end
end

--- Called when two active elements collide. 
-- If the collision needs to be resolved in a particular order, this should be the 
-- place to decide it. For now there is no guarantee on which of the two objects is the first to
-- resolve the collision.
-- @param dt The time slice for the frame when the collision is detected
-- @param shapeA The first colliding shape, as a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape.
-- @param shapeB The second colliding shape, as a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape.
function GameObjectManager.onDynamicCollide(dt, shapeA, shapeB)
    if shapeA.parent and shapeB.parent then
        shapeA.parent:onDynamicCollide(dt, shapeB.parent)
        shapeB.parent:onDynamicCollide(dt, shapeA.parent)
    end
end

function GameObjectManager:destroySelf()
    for _, object in ipairs(self.managedObjects) do
        object.world = nil
        object:destroySelf()
    end

    self.managedObjects = nil

    self.activeCollider = nil
    self.tileCollider = nil
end

return GameObjectManager