local vector = require 'lib.hump.vector'

local stageParameters ={
	
	map = "YoshisIsland3.tmx",

	startingPosition = vector(4, 22),

	--{ stageElements = {}}

	additionalParameters = {},

	defaultCameraMode = { mode = "snapToPlatform",
						  snapSpeed = 260,
						  tension = vector(8, 0)}

	--[[defaultCameraMode = { mode = "lock",
									verticalLock = 26,
									tension = vector(8, 0)}
]]

	--[[defaultCameraMode = { mode = "lock",
											verticalLock = 26,
											tension = vector(8, 0)}]]


	--[[defaultCameraMode = { mode = "folllowPlayer",
									tension = vector(8, 0)}
]]

}

return stageParameters