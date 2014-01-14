--- A module that processes collisions between GameObjects and stage tiles.
-- @classmod lib.TileCollider

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local shapes = require 'lib.HardonCollider.shapes'


local TileCollider = Class {	
	name = 'TileCollider',
}

--- Builds a new TileCollider with no elements, based on a given Stage.
-- @class function
-- @name lib.TileCollider.__call
-- @tparam @{data.core.Stage} stage The Stage object that represents the collidable world.
-- @treturn @{lib.TileCollider} The newly created TileCollider.

function TileCollider:init(stage)

	self.elements = {}
	self.stage = stage

	local tileSize = self.stage:getTileSize()
	
	self.sampleTile = shapes.newPolygonShape(0, 0,
											 0, tileSize.y,
											 tileSize.x, tileSize.y,
											 tileSize.x, 0)
end


--- Adds an Element to the TileCollider. The TileCollider is NOT added in any way
-- to the Element. Nothing is done if the Element was already added to the TileCollider.
-- @tparam Shape element The HardonCollider shape to be added to the TileCollider.
function TileCollider:addShape(element)
	for _, value in pairs(self.elements) do
	    if value == element then
	        return
	    end
	end

	table.insert(self.elements, element)
end

--- Removes a shape from the TileCollider. The TileCollider is NOT removed in any way
-- from the Shape or other objects. Nothing is done if the Element was not previously added to the TileCollider.
-- @tparam Shape element The HardonCollider shape to be removed from the TileCollider.
function TileCollider:remove(element)
	for pos, value in pairs(self.elements) do
	    if value == element then
	        table.remove(self.elements, pos)
	    end
	end
end	

--- Updates and checks tile collisions for all elements.
-- @{data.core.Component.CollisionComponent}'s onTileCollide (or the appropriate override) is called for each element touching a
-- tile, for every tile it is colliding with.
-- @tparam number dt Time since the last update, in seconds.
function TileCollider:update(dt)

    local layer = self.stage:getCollidableLayer()
	local tileSize = self.stage:getTileSize()

	for idx, elem in pairs(self.elements) do
		if elem.hitsTiles then
			elem.parent:resetCollisionFlags()

			elem.color = {255, 0, 255, 255}
			local x1,y1, x2,y2 = elem:bbox()

			local minTileX = math.floor(x1/tileSize.x)
			local minTileY = math.floor(y1/tileSize.y)
			
			local elemWidth = math.ceil((x2 - x1)/tileSize.x)
			local elemHeight = math.ceil((y2 - y1)/tileSize.x)

			for x, y, tile in self.stage:getTilesAt(layer,
													minTileX,
													minTileY,
													elemWidth,
													elemHeight) do

		        if tile then
		        	
		        	self.sampleTile:moveTo(x * tileSize.x + tileSize.x/2.0,
		        						   y * tileSize.y + tileSize.y/2.0)

		        	if self.sampleTile:collidesWith(elem) then
						elem.parent:onTileCollide(dt, self.sampleTile, tile, vector(x, y))
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