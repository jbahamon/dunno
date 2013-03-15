local vector = require 'lib.hump.vector'

local stageParameters ={
	
	map = "SMB3-1-1.tmx",

	startingPosition = vector(102, 9),

	--{ stageElements = {}}

	additionalParameters = {},

	defaultCameraMode = { mode = "snapToPlatform",
						  snapSpeed = 360,
						  tension = vector(8, 0)}

	--[[defaultCameraMode = { mode = "lock",
									verticalLock = 26,
									tension = vector(8, 0)}
]]

	--[[defaultCameraMode = { mode = "lock",
									verticalLock = 26,
									tension = vector(8, 0)}
]]

	--[[defaultCameraMode = { mode = "folllowPlayer",
									tension = vector(8, 0)}
]]

}

return stageParameters