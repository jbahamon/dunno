local vector = require 'lib.hump.vector'

local stageParameters ={
	
	map = "SMB3-1-1.tmx",

	startingPosition = vector(102, 9),

	--{ stageElements = {}}

	additionalParameters = {},

	defaultCameraMode = { mode = "snapToPlatform",
						  snapSpeed = 360,
						  --verticalLock = 26,
						  --speed = 
						  tension = vector(8, 0)}

	--defaultCameraMode = { mode = "snap",
	--						vertical = {}, horizontal = {} }

}

return stageParameters