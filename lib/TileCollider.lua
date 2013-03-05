local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local shapes = require 'lib.HardonCollider.shapes'


local TileCollider = Class {
	
	name = 'TileCollider',

	init = 
		function(self, stage)
			self.elements = {}
			self.stage = stage

			local tileSize = self.stage:getTileSize()
			
			self.sampleTile = shapes.newPolygonShape(0, 0,
													 0, tileSize.y,
													 tileSize.x, tileSize.y,
													 tileSize.x, 0)
		end
}

function TileCollider:addElement(element)
	for _, value in pairs(self.elements) do
	    if value == element then
	        return
	    end
	end

	table.insert(self.elements, element)
end

function TileCollider:remove(element)
	for pos, value in pairs(self.elements) do
	    if value == element then
	        table.remove(self.elements, pos)
	    end
	end
end	

function TileCollider:update(dt)

    local layer = self.stage:getCollidableLayer()
	local tileSize = self.stage:getTileSize()

	for idx, elem in pairs(self.elements) do
		if elem.active then
			elem.parent:resetCollisionFlags()

			elem.color = {255, 0, 255, 255}
			local x1,y1, x2,y2 = elem:bbox()
			

			local minTileX = math.floor(x1/tileSize.x)
			local minTileY = math.floor(y1/tileSize.y)
			
			local elemWidth = math.ceil(elem.width/tileSize.x)
			local elemHeight = math.ceil(elem.height/tileSize.x)

			for x, y, tile in self.stage:getTilesAt(layer,
													minTileX,
													minTileY,
													elemWidth,
													elemHeight) do

		        if tile and (tile.properties.solid or tile.properties.oneWayPlatform or tile.properties.ladder) then
		        	
		        	self.sampleTile:moveTo(x * tileSize.x + tileSize.x/2.0,
		        						   y * tileSize.y + tileSize.y/2.0)

		        	if self.sampleTile:collidesWith(elem) then
						elem.parent:onTileCollide(dt, self.sampleTile, tile, x, y)
						elem.color = { 255, 0, 0, 255 }
					end
		        end

			end

			-- To avoid collisions with cracks between tiles and other artifacts, 
			-- the previous loop only marks collision flags and enqueues collision 
			-- events. Collisions are resolved only after flags have been 
			-- correctly set.


			if table.getn(elem.parent.pendingCollisions) > 0 then
				elem.parent:resolveTileCollisions(self.sampleTile, tileSize)
			end
		end

	end

end

return TileCollider