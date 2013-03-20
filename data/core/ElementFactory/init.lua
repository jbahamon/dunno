--- ElementFactory implementation.
-- @class module
-- @name data.core.ElementFactory

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'

local Element = require 'data.core.Element'

--- Builds a new ElementFactory.
-- @class function
-- @name ElementFactory
-- @param parameters The parameters to use in the building of elements. It must include a sprite field,
-- with sheet, spriteSizeX and spriteSizeY as fields. The sheet must be an image loaded with love.graphics.newImage.-- 
-- @param tileCollider The TileCollider to assign to every Element created by this ElementFactory.
-- @param tileCollider The TileCollider to assign to every Element created by this ElementFactory.
-- @param folder The base folder to load files (sprites, classes, etc) for building the Elements from.
-- @return The newly created ElementFactory.

local ElementFactory = Class {
	name = 'ElementFactory',

	init = 
		function (self, parameters, tileCollider, activeCollider, folder)

			self.parameters = parameters

			self.tileCollider = tileCollider
			self.activeCollider = activeCollider
			self.folder = folder

			assert(parameters.sprites,"No sprite info supplied")
			assert(parameters.sprites.sheet, "No spritesheet info supplied" )

			local folder = parameters.sprites.folder or folder or ""

			local sprites = folder .. "/" .. string.gsub(parameters.sprites.sheet, '[^%a%d-_/.]', '')

			assert(love.filesystem.isFile(sprites), "Spritesheet \'".. sprites .."\' supplied is not a file")	

			assert(parameters.sprites.spriteSizeX and parameters.sprites.spriteSizeY,
				"No sprite size supplied")

			self.sprites = love.graphics.newImage(sprites)
			self.sprites:setFilter('nearest', 'nearest')

			self.spriteSizeX = parameters.sprites.spriteSizeX
			self.spriteSizeY = parameters.sprites.spriteSizeY

			self.spriteOffset = parameters.sprites.spriteOffset

			self.spritesGrid = anim8.newGrid(self.spriteSizeX,
                                         self.spriteSizeY,
                                         self.sprites:getWidth(),
                                         self.sprites:getHeight())

		end
}

--- An object that can generate copies of an object without reloading every resource.
-- In particular, sprite data and the parameters are not loaded multiple times.
-- Useful for respawning enemies or other elements (e.g. bullets).
-- @type ElementFactory

--- Creates a new instance of the ElementFactory's Element.
-- @return The newly created Element.
function ElementFactory:create()
	local newElement = Element.loadBasicFromParams(self.parameters, self.folder)

	newElement:setColliders(self.tileCollider, self.activeCollider)

	newElement.spriteSizeX = self.spriteSizeX
	newElement.spriteSizeY = self.spriteSizeY

	newElement.sprites = self.sprites
	newElement.spritesGrid = self.spritesGrid

	newElement.spriteOffset = self.spriteOffset

	newElement:loadStatesFromParams(self.parameters)

	return newElement

end


--- Creates a new instance of the ElementFactory's Element at the specified position
-- and facing the specified direction.
-- @param position The position, in pixels, where to put the new Element.
-- @param facing The direction the Element should be facing. A value of facing greater
-- than zero indicates facing right; a value smaller than zero indicates facing left.
-- @return The newly created Element.
function ElementFactory:createAt(position, facing)
	local newElement = self:create()
	newElement:setStartingPosition(position.x,
									position.y)

	if facing < 0 then
		newElement:getInitialState():turn()
	end

	return newElement
end

return ElementFactory