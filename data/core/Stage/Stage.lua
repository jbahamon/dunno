local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local Stage = Class {
	name = 'Stage',

	init = 
		function (self) 

			self.loader = require 'lib.AdvTileLoader.Loader'
			self.loader.path = 'stages/'
			--self.map = self.loader.load('SMB3-1-1.tmx')
			self.map = self.loader.load('TomahawkMan/TomahawkMan.tmx')
			self.map:setDrawRange(0,0,love.graphics.getWidth(), love.graphics.getHeight())
			self.startingTile = vector(8, 20)

		end
}

function Stage:draw() 
	self.map:draw()
end

function Stage:getStartingPosition()
	return self.startingTile * self.map.tileWidth +
		vector(self.map.tileWidth, self.map.tileHeight )
end

function Stage:getPixelSize()
	return vector(self.map.width * self.map.tileWidth,
				  self.map.height * self.map.tileHeight)
end

function Stage:getTileSize()
	return vector(self.map.tileWidth, self.map.tileHeight)
end

function Stage:getTilesAt(layer, minX, minY, width, height)
	return layer:rectangle(minX, minY, width, height)
end

function Stage:getCollidableLayer() 
	return self.map("ground")
end

function Stage:moveTo(x, y)
	self.map.viewX = x
	self.map.viewY = y
end

return Stage
