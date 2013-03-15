local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local shapes = require 'lib.HardonCollider.shapes'
local GeometryUtils = require 'lib.GeometryUtils'


--[[ TODO:
		- Floor tension
		- Scroll

]]

local Stage = Class {
	name = 'Stage',

	init = 
		function (self, mapPath) 
			self.loader = require 'lib.AdvTileLoader.Loader'
			self:setMap(mapPath)
			self.rooms = {}
			self.defaultRoom = "_defaultRoom"
		end
}

-----------------------------------------------------------------
-- Size and Position
-----------------------------------------------------------------
function Stage:getTension()
	return self.tension or vector(0,0)
end

-----------------------------------------------------------------
-- Size and Position
-----------------------------------------------------------------

function Stage:setStartingPosition(position)
	self.startingPosition = position
end

function Stage:getStartingPosition()
	return self.startingPosition
end

function Stage:getPixelStartingPosition()
	return self.startingPosition * self.map.tileWidth +
		vector(self.map.tileWidth, self.map.tileHeight )
end


function Stage:getPixelStartingFocus()
	if self.startingFocus then
		return self.startingFocus * self.map.tileWidth +
			vector(self.map.tileWidth, self.map.tileHeight )
	else
		return self:getPixelStartingPosition()
	end
end

function Stage:getPixelSize()
	return vector(self.map.width * self.map.tileWidth,
				  self.map.height * self.map.tileHeight)
end

function Stage:getTileSize()
	return vector(self.map.tileWidth, self.map.tileHeight)
end

-----------------------------------------------------------------
-- Room Handling
-----------------------------------------------------------------

function Stage:addRoom(roomParams)
	local topLeft =  roomParams.topLeft 
	local bottomRight =  roomParams.bottomRight + vector(1,1)

	roomParams.box = shapes.newPolygonShape( topLeft.x * self.map.tileWidth, topLeft.y * self.map.tileHeight,
									 	 bottomRight.x * self.map.tileWidth, topLeft.y * self.map.tileHeight,
										 bottomRight.x * self.map.tileWidth, bottomRight.y * self.map.tileHeight,
										 topLeft.x * self.map.tileWidth, bottomRight.y * self.map.tileHeight )

	roomParams.topLeft = nil
	roomParams.bottomRight = nil

	table.insert(self.rooms, roomParams)
end

function Stage:setRoom(position, dontMoveCamera)
	self.currentRoom = self:getRoom(position)

	if not dontMoveCamera then
		self.currentViewRoom = self.currentRoom
	end
end


function Stage:getRoom(position)

	if not position then return self.currentRoom end

	local x, y = position:unpack()
	for _, room in ipairs(self.rooms) do
		if room.box:contains(x, y) then
			return room
		end
	end

	return self.defaultRoom

end


function Stage:getCollidingRooms(player)
	local playerBox = player:getCollisionBox()
	local collidingRooms = {}

	for _, room in ipairs(self.rooms) do
		if room.box:collidesWith(playerBox) then
			room.collisionArea = GeometryUtils.getCollisionArea(player:getCollisionBox(), room.box)			

			if room.collisionArea > 0 then
				table.insert(collidingRooms, room)
			end
		end
	end

	return collidingRooms

end

function Stage:checkRoomChange(player)
	if #self.rooms == 0 then
		return false
	end

	local x1, y1, x2, y2 = player:getCollisionBox():bbox()

	if self.currentRoom.box:contains(x1, y1) and self.currentRoom.box:contains(x2, y1) and
		self.currentRoom.box:contains(x1, y2) and self.currentRoom.box:contains(x2, y2) then
		return false
	end

	local collidingRooms = self:getCollidingRooms(player)

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

function Stage:changeToRoom(room)
	self.currentRoom = room
end


-----------------------------------------------------------------
-- Drawing
-----------------------------------------------------------------

function Stage:getCameraMode()
	return self.currentRoom.cameraMode or self.defaultCameraMode
end

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

function Stage:draw() 
	self.map:draw()
end

-----------------------------------------------------------------
-- Map, layers and tiles116
-----------------------------------------------------------------

function Stage:setMap(mapPath)
			
			self.loader.path = 'stages/'
			--self.map = self.loader.load('SMB3-1-1.tmx')
			--self.map = self.loader.load('CastleKeep/CastleKeep.tmx')
			self.map = self.loader.load(mapPath)
			self.map:setDrawRange(0,0,love.graphics.getWidth(), love.graphics.getHeight())
			
end

function Stage:getLayer(layerName)
	return self.map(layerName)
end

function Stage:getTilesAt(layer, minX, minY, width, height)
	return layer:rectangle(minX, minY, width, height)
end

function Stage:getCollidableLayer() 
	return self.map("collision")
end

function Stage:moveTo(x, y)
	self.map.viewX = x
	self.map.viewY = y
end

---------------------------------------
-- Static functions
---------------------------------------
Stage.stageFolder = "stages/"

function Stage.loadFromFolder(folderName)

	local folder = Stage.stageFolder .. string.gsub(folderName, '[^%a%d-_/]', '')
	assert(love.filesystem.isFile(folder .. "/config.lua"), "Stage configuration file \'".. folder .. "/config.lua"   .."\' not found")
	local ok, stageFile = pcall(love.filesystem.load, folder .. "/config.lua")

	assert(ok, "Stage file has syntax errors: " .. tostring(stageFile))

	local parameters = stageFile()

	assert(type(parameters) == "table", "Stage configuration file must return a table")

	local mapPath = folderName .. "/" ..parameters.map
	local stage = Stage(mapPath, parameters)

	assert(parameters.startingPosition and vector.isvector(parameters.startingPosition), 
		"Missing parameter \'startingPosition\' or parameter is not a vector.")

	stage:setStartingPosition(parameters.startingPosition)

	if parameters.roomTransitionMode then
		assert(type(parameters.roomTransitionMode) == "string", "Room transition mode must be specified using a string")
		stage.roomTransitionMode = parameters.roomTransitionMode
	end

	if parameters.rooms then
		assert (type(parameters.rooms) == "table", "\'rooms\' parameter must be an array")
		for _, room in ipairs(parameters.rooms) do
			assert(room.topLeft and room.bottomRight and vector.isvector(room.topLeft) and vector.isvector(room.bottomRight), 
				"Room must specify top left and bottom right corners as vectors.")
			stage:addRoom(room)
		end
	end

	if parameters.defaultCameraMode then
		stage.defaultCameraMode = parameters.defaultCameraMode
	end
	
	return stage

end

return Stage
