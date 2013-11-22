--- GameObjectFactory implementation.
-- @class module
-- @name data.core.GameObjectFactory
local Loader = globals.Loader

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'
local shapes = require 'lib.HardonCollider.shapes'
local GameObject = require 'data.core.GameObject'

local TransformComponent = require 'data.core.Component.TransformComponent'
local CollisionComponent = require 'data.core.Component.CollisionComponent'
local AnimationComponent = require 'data.core.Component.AnimationComponent'
local StateMachineComponent = require 'data.core.Component.StateMachineComponent'
local InputComponent = require 'data.core.Component.InputComponent'
local PhysicsComponent = require 'data.core.Component.PhysicsComponent'


--- Builds a new GameObjectFactory.
-- @class function
-- @name GameObjectFactory
-- @param parameters The parameters to use in the building of GameObjects. It must include a sprite field,
-- with sheet, spriteSizeX and spriteSizeY as fields. The sheet must be an image loaded with love.graphics.newImage.-- 
-- @param tileCollider The TileCollider to assign to every GameObject created by this GameObjectFactory.
-- @param tileCollider The TileCollider to assign to every GameObject created by this GameObjectFactory.
-- @param folder The base folder to load files (sprites, classes, etc) for building the GameObjects from.
-- @return The newly created GameObjectFactory.

local GameObjectFactory = Class {
	name = 'GameObjectFactory'
}


function GameObjectFactory:init(parameters, tileCollider, activeCollider, folder)

	self.parameters = parameters

	self.tileCollider = tileCollider
	self.activeCollider = activeCollider
	self.folder = folder

    if parameters.size then
	   assert(vector.isvector(parameters.size), "GameObject factory size must be a vector.")
       self.shape = shapes.newPolygonShape(
        - math.floor(parameters.size.x/2), 0,
          math.ceil(parameters.size.x/2), 0,
          math.ceil(parameters.size.x/2), - parameters.size.y,
        - math.floor(parameters.size.x/2), - parameters.size.y)
    end

    if self.parameters.states then
        assert(self.parameters.initialState and type(self.parameters.initialState) == "string", "Must specify a valid initial state")
    end


    if self.parameters.sprites and self.parameters.animations then
        assert(self.parameters.sprites.sheet and 
               self.parameters.sprites.spriteSize, "sheet and spriteSize must be defined for new GameObject " .. parameters.name)

        assert(vector.isvector(parameters.sprites.spriteSize),
            "Sprite size must be a vector")


        local folder = parameters.sprites.folder or folder or ""

        local sprites = folder .. "/" .. string.gsub(parameters.sprites.sheet, '[^%a%d-_/.]', '')

        assert(love.filesystem.isFile(sprites), "Spritesheet \'".. sprites .."\' supplied is not a file")   

        self.sprites = love.graphics.newImage(sprites)
        self.sprites:setFilter('nearest', 'nearest')

        self.spriteSize = parameters.sprites.spriteSize

        if parameters.sprites.spriteOffset then
            self.spriteOffset = parameters.sprites.spriteOffset
        else
            self.spriteOffset = vector(0,0)
        end

        self.spritesGrid = anim8.newGrid(self.spriteSize.x,
                             self.spriteSize.y,
                             self.sprites:getWidth(),
                             self.sprites:getHeight())
    end


end

--- An object that can generate copies of an object without reloading every resource.
-- In particular, sprite data and the parameters are not loaded multiple times.
-- Useful for respawning enemies or other GameObjects (e.g. bullets).
-- @type GameObjectFactory

--- Creates a new instance of the GameObjectFactory's GameObject.
-- @return The newly created GameObject.
function GameObjectFactory:create()

    local newGameObject = GameObject.new()
    newGameObject.folder = self.folder
    newGameObject.name = self.name


    newGameObject:addComponent(TransformComponent())
    newGameObject:addComponent(PhysicsComponent())

    if self.sprites and self.parameters.animations then

        newGameObject:addComponent(AnimationComponent(self.sprites, 
                                                    self.spriteSize, 
                                                    self.spriteOffset))

        for k, v in pairs(self.parameters.animations) do
            newGameObject.animation:addAnimation(k, v)
        end
    end    

    if self.parameters.size then
        newGameObject:addComponent(CollisionComponent(self.parameters.size))
        newGameObject.collision:setColliders(self.tileCollider, self.activeCollider)

        if self.parameters.elementType == "Enemy" then
            newGameObject.collision.damagesOnContact = true
        end
    end    
    
    if self.parameters.states then
        newGameObject:addComponent(StateMachineComponent())

        --FIXME: why is globals required here?
		globals.Loader.loadStates(newGameObject, self.parameters.states)

        if self.parameters.transitions then
		  globals.Loader.loadTransitions(newGameObject, self.parameters.transitions)
        end

		newGameObject.stateMachine.initialState = self.parameters.initialState

	end

	if self.parameters.postBuild then
        self.parameters.postBuild(newGameObject)
    end


    if self.parameters.onStart then
        newGameObject:setEventHandler("start", self.parameters.onStart)
    end

	return newGameObject

end


--- Creates a new instance of the GameObjectFactory's GameObject at the specified position
-- and facing the specified direction.
-- @param position The position, in pixels, where to put the new GameObject.
-- @param facing The direction the GameObject should be facing. A value of facing greater
-- than zero indicates facing right; a value smaller than zero indicates facing left.
-- @return The newly created GameObject.
function GameObjectFactory:createAt(position, facing)
	local newGameObject = self:create()

	newGameObject:moveTo(position)

	if facing < 0 then
		newGameObject:turn()
	end

	return newGameObject
end


return GameObjectFactory