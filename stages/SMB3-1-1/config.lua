local vector = require 'lib.hump.vector'
--local enemiesFile = require 'stages.SMB3-1-1.enemies'
local stageParameters ={
	
	map = "SMB3-1-1.tmx",

	startingPosition = vector(3, 25),

	--{ stageElements = {}}

	additionalParameters = {},

--	[[defaultCameraMode = { mode = "snapToPlatform",
--								  snapSpeed = 360,
--								  tension = vector(8, 0)} 
--								  ]]

	--[[defaultCameraMode = { mode = "lock",
									verticalLock = 26,
									tension = vector(8, 0)}
]]

	
	--enemies = enemiesFile
	defaultCameraMode = { mode = "folllowPlayer",
									tension = vector(8, 0)},

	elementTypes = love.filesystem.load('stages/SMB3-1-1/enemies/EnemyTypes.lua')(),

	elementLocations = { 
						{ name = "Goomba", position = vector(256, 400), facing = -1 }
						
						}

}

return stageParameters