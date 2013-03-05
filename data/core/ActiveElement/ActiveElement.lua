local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local GeometryUtils = require 'lib.GeometryUtils'
local shapes = require 'lib.HardonCollider.shapes'

local ElementStateMachine = require 'data.core.ActiveElement.ElementStateMachine'

local ActiveElement = Class {

	name = 'ActiveElement',

	function (self, position, width, height, tileCollider, activeCollider)

		self.tileCollider = tileCollider
		self.activeCollider = activeCollider

	    --self.headBox = collider:addRectangle(x + 1, y, 14, 4)
	    self.defaultCollisionBox = shapes.newPolygonShape(
	    	- math.floor(width/2), 0,
	    	math.ceil(width/2), 0,
	    	math.ceil(width/2), - height,
	    	- math.floor(width/2), - height)

	    self.activeCollider:addShape(self.defaultCollisionBox)
	    self.activeCollider:setGhost(self.defaultCollisionBox)

		self.tileCollider:addElement(self.defaultCollisionBox)
		self.defaultCollisionBox.active = false

	    self.defaultCollisionBox.width = width
	    self.defaultCollisionBox.height = height

		self.defaultCollisionBox.color = {255, 255, 255, 255}

	    -- Collision flags
	    self.collisionFlags = { canMoveLeft = true,
			    				canMoveRight = true,
			    				canMoveUp = true,
			    				canMoveDown = true,
			    				specialEvents = {}}

		self.pendingCollisions = {}

	end	

}

function ActiveElement:update(dt)
	-- Movement
	local displacement = self.stateMachine:update(dt)
	self:move(displacement)
end

function ActiveElement:move(displacement)
	self.stateMachine:move(displacement)
	self.currentCollisionBox:move(displacement:unpack())
end

function ActiveElement:getPosition()
	return self.stateMachine.currentState.dynamics.position
end

function ActiveElement:getLastPosition()
	return self.stateMachine.currentState.dynamics.oldPosition
end

function ActiveElement:getVelocity()
	return self.stateMachine.currentState.dynamics.velocity
end

function ActiveElement:draw()
	self.stateMachine:draw()
    if DEBUG then
        love.graphics.setColor(self.currentCollisionBox.color)
        self.currentCollisionBox:draw()
    end

end

function ActiveElement:checkStateChange()
	self.stateMachine:checkStateChange(self.collisionFlags)
end

function ActiveElement:onTileCollide(dt, tileElement, tile, x, y)

	if tile.properties.solid or tile.properties.oneWayPlatform or tile.properties.ladder then
		local x1,y1, x2,y2 = self.currentCollisionBox:bbox()

		local tileX1,tileY1, tileX2,tileY2 = tileElement:bbox()

		local collides, dx, dy = tileElement
		local collisionEvent = { x = x, y = y, tile = tile }

		collisionEvent.area = GeometryUtils.getCollisionArea(x1, y1, x2, y2, tileX1, tileY1, tileX2, tileY2)

		table.insert(self.pendingCollisions, collisionEvent)

	end

	-- Insert other collision types here. One-way platforms, ladders and
	-- slopes are the most relevant. Each one resolves and sets flags in
	-- their own way.

end

function ActiveElement:resetCollisionFlags()
	self.collisionFlags.canMoveLeft = true
	self.collisionFlags.canMoveRight = true
	self.collisionFlags.canMoveUp = true
	self.collisionFlags.canMoveDown = true

	self.collisionFlags.specialEvents = {}
end

function ActiveElement:resolveTileCollisions(sampleTile, tileSize)

	table.sort(self.pendingCollisions, function(a, b)
											return a.area > b.area
										end)
	local collides, dx, dy
	local highestLadderEvent

	for idx, event in pairs(self.pendingCollisions) do
	-- FIXME - this should be improved

		sampleTile:moveTo(event.x * tileSize.x + tileSize.x/2.0,
						  event.y * tileSize.y + tileSize.y/2.0)

		collides, dx, dy = self.currentCollisionBox:collidesWith(sampleTile)

		if collides then

			if event.tile.properties.solid then 
				self:move(vector(dx, dy))
				if math.abs(dx) > math.abs(dy) then
					if dx > 0 then 
						self.collisionFlags.canMoveLeft = false
					elseif dx < 0 then
						self.collisionFlags.canMoveRight = false
					end
				else
					if dy > 0 then 
						self.collisionFlags.canMoveUp = false
						self:getVelocity().y = math.max(self:getVelocity().y, 0)
					elseif dy < 0 then 
						self.collisionFlags.canMoveDown = false
					end
				end
			elseif event.tile.properties.oneWayPlatform then
				
				local verticalDisplacement = event.y * tileSize.y - self:getPosition().y
				
				if event.y * tileSize.y >= self:getLastPosition().y then
					self:move(vector(0, verticalDisplacement))
					self.collisionFlags.canMoveDown = false
				end
			elseif event.tile.properties.ladder then
				if (not highestLadderEvent) or highestLadderEvent.y > event.y then
					highestLadderEvent = event
				end

				local centerX, centerY = self.currentCollisionBox:center()
				if sampleTile:intersectsRay(centerX, centerY, 0, -1) or
					sampleTile:intersectsRay(centerX, centerY, 0, 1) then

					if not self.collisionFlags.specialEvents.ladder then
						self.collisionFlags.specialEvents.ladder = { position = vector(sampleTile:center()), element = self}
					end
				end
			end	
		end

	end

				
	if highestLadderEvent and highestLadderEvent.y * tileSize.y >= self:getLastPosition().y then
		self:move(vector(0, highestLadderEvent.y * tileSize.y - self:getPosition().y))
		self.collisionFlags.canMoveDown = false
		self.collisionFlags.specialEvents.standingOnLadder = self.collisionFlags.specialEvents.ladder
		self.collisionFlags.specialEvents.ladder = nil
	end

	self.pendingCollisions = {}

end

function ActiveElement:setCollisionBox(collisionBox)
	if self.currentCollisionBox then
		self.currentCollisionBox.active = false

		--this if should be removed
		if self.activeCollider then
			self.activeCollider:setGhost(self.currentCollisionBox)
		end

	end
	
	collisionBox:moveTo(self.stateMachine.currentState.dynamics.position.x,
					    self.stateMachine.currentState.dynamics.position.y - collisionBox.height/2)
	self.currentCollisionBox = collisionBox
	self.currentCollisionBox.parent = self
	self.currentCollisionBox.active = true

	--this if should be removed
	if self.activeCollider then
		self.activeCollider:setSolid(self.currentCollisionBox)
	end

end

function ActiveElement:disableTileCollisions()
	if self.currentCollisionBox then
		self.currentCollisionBox.active = false
	end
end


function ActiveElement:enableTileCollisions()
	if self.currentCollisionBox then
		self.currentCollisionBox.active = true
	end
end

function ActiveElement:getDefaultCollisionBox(collisionBox)
	return self.defaultCollisionBox
end

return ActiveElement