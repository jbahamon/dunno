--- State machine implementation.
-- @class module
-- @name data.core.Stage

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local shapes = require 'lib.HardonCollider.shapes'
local GeometryUtils = require 'lib.GeometryUtils'
local GameObjectFactory = require 'data.core.GameObjectFactory'

--- Builds a new empty Stage, given the stage's map file.
-- @class function
-- @name Stage
-- @param mapPath The path to the map file.
-- @return The newly created Stage.
local Stage = Class {
	name = 'Stage'
}

function Stage:init(mapPath) 
	self.loader = require 'lib.AdvTileLoader.Loader'
	
	self.elementFactories = {}
	self.elementLocations = {}
	self.elementTypes = {}
	self.activeElements = {}

	self:setMap(mapPath)
	self.rooms = {}
	self.defaultRoom = "_defaultRoom"

	self.tension = vector(0,0)

end

--- Class that represents the stage (platforms, static elements, etc) where the elements live and interact.
-- Also includes some camera settings.
-- @type Stage

--- Centers the map's view in a given position.
-- This means the stage's drar method will center itself in the given coordinates.
-- @param newPosition The new center, as a vector, in pixels.
function Stage:moveTo(newPosition)
	self.map.viewX = newPosition.x
	self.map.viewY = newPosition.y
end


-----------------------------------------------------------------
-- Size and Position
-- @section size

--- Retrieves the Stage's camera tension setting.
-- @return A vector containing the stage's camera tension. 
function Stage:getTension()
	return self.tension
end

--- Sets the Stage's base folder for loading sprites and other files.
-- @param path The Stage's base path.
function Stage:setFolder(path)
	self.folder = path
end

--- Returns the Stage's base folder for loading sprites and other files.
-- @return The Stage's base path.
function Stage:getFolder()
	return self.folder
end

--- Sets the Stage's starting position.
-- @param position The new starting position for the Stage, as a vector, in tile coordinates.
function Stage:setStartingPosition(position)
	self.startingPosition = position:clone()
end

--- Returns the Stage's starting position.
-- @return The Stage's starting position, as a vector, in tile coordinates.
function Stage:getStartingPosition()
	return self.startingPosition
end

--- Returns the Stage's starting position, in pixel coordinates.
-- @return The starting position for the Stage, as a vector, in pixels.
function Stage:getPixelStartingPosition()
	return self.startingPosition:permul(self.tileSize) + self.tileSize
end

--- Returns the camera's starting center for the stage..
-- @return The camera's starting position for the Stage, as a vector, in pixels.
function Stage:getPixelStartingFocus()
	if self.startingFocus then
		return self.startingFocus:permul(self.tileSize) + self.tileSize
	else
		return self:getPixelStartingPosition()
	end
end

--- Returns the Stage's size.
-- @return The Stage's size, as a vector, in pixels.
function Stage:getPixelSize()
	return vector(self.map.width, self.map.height):permul(self.tileSize)
end

--- Returns the Stage's tile size.
-- @return The Stage's tile size, as a vector, in pixels.
function Stage:getTileSize()
	return self.tileSize
end

-----------------------------------------------------------------
-- Room Handling
-- @section room

--- Adds a new room to the Stage. Do not reuse the parameter table passed to this function.
-- A room includes a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> shape (a rectangle, as room.box) that represents the room and a tags dictionary.
-- @param roomParams The room's parameters. It must include the room's top left and bottom right 
-- tile coordinates as topLeft and bottomRight fields. Any other field will be preserved.
function Stage:addRoom(roomParams)
	local topLeft =  roomParams.topLeft:permul(self.tileSize)
	local bottomRight =  (roomParams.bottomRight + vector(1,1)):permul(self.tileSize)


	roomParams.box = shapes.newPolygonShape( topLeft.x, topLeft.y,
									 	 bottomRight.x, topLeft.y,
										 bottomRight.x, bottomRight.y,
										 topLeft.x, bottomRight.y)

	-- FIXME: Why do we do this?
	roomParams.topLeft = nil
	roomParams.bottomRight = nil

	table.insert(self.rooms, roomParams)
end


--- Returns the Stage's current room.
-- @return The Stage's current room.
function Stage:getRoom()
	return self.currentRoom
end

--- Returns the Stage's room at a specified point, in pixels.
-- @return The Stage's room containing the point, or the Stage's default room.
function Stage:getRoomAt(position)
	local x, y = position:unpack()
	for _, room in ipairs(self.rooms) do
		if room.box:contains(x, y) then
			return room
		end
	end

	return self.defaultRoom
end

--- Returns the Stage's rooms that collide with a given Element.
-- @param element The Element to test for collisions.
-- @return An array containing the rooms that the Element is touching. 
function Stage:getCollidingRooms(element)
	local playerBox = element.collision.box
	local collidingRooms = {}

	for _, room in ipairs(self.rooms) do
		if room.box:collidesWith(playerBox) then
			room.collisionArea = GeometryUtils.getCollisionArea(playerBox, room.box)			

			if room.collisionArea > 0 then
				table.insert(collidingRooms, room)
			end
		end
	end

	return collidingRooms
end

--- Checks if a given element is going from one room to another. 
-- If so, selects the one most probable for transition (based on contact area)
-- and returns a room change parameter table, including two fields: previousRoom and nextRoom.
-- @return The Stage's current room.
function Stage:checkRoomChange(element)
	if #self.rooms == 0 then
		return false
	end

	local x1, y1, x2, y2 = element.collision.box:bbox()

	if self.currentRoom.box:contains(x1, y1) and self.currentRoom.box:contains(x2, y1) and
		self.currentRoom.box:contains(x1, y2) and self.currentRoom.box:contains(x2, y2) then
		return false
	end

	local collidingRooms = self:getCollidingRooms(element)

	table.sort(collidingRooms, function(a, b)
											return a.collisionArea > b.collisionArea
										end)


	local previousRoom = self.currentRoom
	
	for _, room in ipairs(collidingRooms) do
		if room ~= previousRoom and not (room.tags and room.tags.hidden) then
			return {previousRoom = previousRoom, nextRoom = room}
		end	
	end
end

--- Sets the Stage's current room.
-- @param room The room to set as the current room.
function Stage:setRoom(room)
	self.currentRoom = room
end

-----------------------------------------------------------------
-- Map, layers and tiles
-- @section map

--- Loads the Stage's map, given a path to its folder.
-- @param mapPath The Stage's map subfolder. The base folder is always "stages/".
function Stage:setMap(mapPath)
			
	self.map = self.loader.load(mapPath)
	self.map:setDrawRange(0,0, love.graphics.getWidth(), love.graphics.getHeight())
	self.tileSize = vector(self.map.tileWidth, self.map.tileHeight)
		
	self.elementLocations = {}	
	if self.map.layers.elementLocations then
		for _, location in ipairs(self.map.layers.elementLocations.objects) do
			local newLocation = {}
			
			location.visible = false

			newLocation.name = location.type
			newLocation.position = vector(location.x + location.width/2, location.y + location.height)

			newLocation.facing = location.properties.facing or -1
			newLocation.enabled = true

			newLocation.shape = shapes.newPolygonShape(
				location.x, location.y,
				location.x + math.floor(location.width), location.y,
				location.x + math.floor(location.width), location.y + math.floor(location.height),
				location.x, location.y + math.floor(location.height))

			table.insert(self.elementLocations, newLocation)
		end
	end
end

--- Returns a given layer from the Stage's map, or nil if it doesn't exist.
-- @param layerName The layer's name.
-- @return The layer, as a 	<a href="https://github.com/Kadoba/Advanced-Tiled-Loader/wiki">Advanced-Tiled-Loader</a> layer.
function Stage:getLayer(layerName)
	return self.map(layerName)
end

--- Returns all tiles that touch a given rectangle.
-- @param layer The <a href="https://github.com/Kadoba/Advanced-Tiled-Loader/wiki">Advanced-Tiled-Liader</a> layer to check.
-- @param minX The horizontal coordinate of the upper left corner of the rectangle, in pixels.
-- @param minY The vertical coordinate of the upper left corner of the rectangle, in pixels.
-- @param width The width of the rectangle, in pixels.
-- @param height The height of the rectangle, in pixels.
-- @return An iterator that allows traversal over all tiles that touch the given rectangle by means of three variables: x, y and tile.
-- tile is the tile element that touches the rectangle; x and y indicate the tile's position, measured in tiles.
function Stage:getTilesAt(layer, minX, minY, width, height)
	return layer:rectangle(minX, minY, width, height)
end

--- Returns the Stage's element layer. Used to generate enemies and other stage elements.
-- @return The elements layer, as a <a href="https://github.com/Kadoba/Advanced-Tiled-Loader/wiki">Advanced-Tiled-Loader</a> ObjectLayer.
function Stage:getElementsLayer()
	return self:getLayer("elements")
end


--- Returns the Stage's collidable layer. Used for tile collisions.
-- @return The collidable layer, as a <a href="https://github.com/Kadoba/Advanced-Tiled-Loader/wiki">Advanced-Tiled-Loader</a> TileLayer.
function Stage:getCollidableLayer() 
	return self:getLayer("collision")
end

-----------------------------------------------------------------
-- Camera and drawing
-- @section draw

--- Returns the current camera mode for the Stage.
-- @return The current camera mode, as a string.
function Stage:getCameraMode()
	return self.currentRoom.cameraMode or self.defaultCameraMode
end

--- Returns the current bounds of the Stage, for camera purposes.
-- @return x1, y1, x2, y2 The current bounds, as defined by the top
-- left and bottom right of the Stage's visible area.
function Stage:getBounds()
	local minX, minY, maxX, maxY

	if self.currentRoom == self.defaultRoom then
		minX, minY = 0, 0
		maxX, maxY = self:getPixelSize():unpack()
	else
		minX, minY, maxX, maxY = self.currentRoom.box:bbox() 
	end

	return minX, minY, maxX - minX, maxY - minY
end

--- Draws the Stage.
function Stage:draw() 
	self.map:draw()

	for _, elem in ipairs(self.activeElements) do
		elem:draw()
	end

end


-----------------------------------------------------------------
-- Element spawning
-- @section elems

--- Initializes element spawning for the stage.

function Stage:start(tileCollider, activeCollider, topLeft, bottomRight)
	for _, elementType in ipairs(self.elementTypes) do
		self.elementFactories[elementType.name] = GameObjectFactory(elementType, tileCollider, activeCollider, self:getFolder())
	end

	self.map:setDrawRange( topLeft.x,
						   topLeft.y,
						   bottomRight.x, 
						   bottomRight.y)

end

--- Updates the stage. 
function Stage:update(dt)

end

--- Updates the stage. 
function Stage:lateUpdate(dt)

end

function Stage:refreshElementSpawning(topLeft, bottomRight) 


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

--respawns and lureable
-- a spawning point is a point that CAN eventually spawn more stuff
function Stage:elementLocationOnScreen(elementLocation)
	elementLocation.onScreen = true
	local newObject = self.elementFactories[elementLocation.name]:createAt(elementLocation.position, elementLocation.facing)

	newObject.elementLocation = elementLocation
	self.world:addObject(newObject)
	
	if newObject.start then
		newObject:start()
	end
	
	elementLocation.enabled = false
end

function Stage:elementLocationOffScreen(elementLocation)
	elementLocation.onScreen = false
end

return Stage
