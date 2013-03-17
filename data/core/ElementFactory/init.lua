local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'

local Element = require 'data.core.Element'


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


function ElementFactory:createAt(position, facing)
	local newElement = self:create()
	newElement:setStartingPosition(position.x * 16,
									position.y * 16)

	if facing < 0 then
		newElement:getInitialState():turn()
	end

	return newElement
end

return ElementFactory