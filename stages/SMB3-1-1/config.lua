local vector = require 'lib.hump.vector'
--local enemiesFile = require 'stages.SMB3-1-1.enemies'
local stageParameters ={
	
	map = "SMB3-1-1.tmx",

	startingPosition = vector(4, 26),

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
	defaultCameraMode = { mode = "followPlayer",
									tension = vector(8, 10)},

	rooms = 
		{
			{ 	topLeft = vector(1, 1),
				bottomRight = vector(176, 27) },
		},

	elementTypes = love.filesystem.load('stages/SMB3-1-1/enemies/EnemyTypes.lua')()

}

return stageParameters