--- A class for mass producing GameObjects without loading every resource each time.
-- In particular, both sprite data and the parameter file are loaded a single time.
-- Useful for respawning enemies or other GameObjects (e.g. bullets).
-- @classmod data.core.GameObjectFactory

local Loader = globals.Loader
local Class = require 'lib.hump.class'

local GameObjectFactory = Class {
	name = 'GameObjectFactory'
}

--- Builds a new GameObjectFactory.
-- @class function
-- @name GameObjectFactory._call
-- @tparam table parameters The parameters to use in the building of GameObjects. It must include a sprite field,
-- with sheet, spriteSizeX and spriteSizeY as fields. The sheet must be an image loaded with love.graphics.newImage.-- 
-- @tparam TileCollidertileCollider The TileCollider to assign to every GameObject created by this GameObjectFactory.
-- @tparam HardonCollider activeCollider The HardonCollider instance to assign to every GameObject created by this GameObjectFactory.
-- @tparam string folder The base folder to load files (sprites, classes, etc) for building the GameObjects from.
-- @treturn GameObjectFactory The newly created GameObjectFactory.

function GameObjectFactory:init(parameters, tileCollider, activeCollider, folder)

	self.parameters = parameters
    self.name = self.parameters.name .. "Factory"
	self.tileCollider = tileCollider
	self.activeCollider = activeCollider
	self.folder = folder

    -- Image preloading
    if parameters.animation and parameters.animation.sprites then

        assert(parameters.animation.sprites.sheet, "Sprite sheet must be specified (as animation.sprites.sheet)")   

        local folder = parameters.animation.sprites.folder or folder or ""
        local sprites = folder .. "/" .. string.gsub(parameters.animation.sprites.sheet, '[^%a%d-_/.]', '')

        assert(love.filesystem.isFile(sprites), "Spritesheet \'".. sprites .."\' supplied is not a file")   

        self.parameters.animation.sprites.sheet = love.graphics.newImage(sprites)
    end


end

--- Creates a new instance of the GameObjectFactory's GameObject.
-- @treturn GameObject The newly created GameObject.
function GameObjectFactory:create()

    local newGameObject = globals.Loader.loadObjectFromParameters(self.parameters, self.folder)

    newGameObject.folder = self.folder
    newGameObject.name = self.parameters.name
   
    if self.parameters.elementType == "Enemy" then
        newGameObject.collision.damagesOnContact = true
    end

    newGameObject.collision:setColliders(self.tileCollider, self.activeCollider)

	return newGameObject

end


--- Creates a new instance of the GameObjectFactory's GameObject at the specified position
-- and facing the specified direction.
-- @tparam vector position The position, in pixels, where to put the new GameObject.
-- @tparam number facing The direction the GameObject should be facing. A value of facing greater
-- than zero indicates facing right; a value smaller than zero indicates facing left.
-- @treturn GameObject The newly created GameObject.
function GameObjectFactory:createAt(position, facing)
	local newGameObject = self:create()

	newGameObject:moveTo(position)

	if facing < 0 then
		newGameObject:turn()
	end

	return newGameObject
end


return GameObjectFactory