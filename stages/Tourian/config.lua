local vector = require 'lib.hump.vector'

local stageParameters ={
	
	map = "Tourian.tmx",

	startingPosition = vector(39.5, 21),

	additionalParameters = {},

	defaultCameraMode = { mode = "followPlayer",
							tension = vector(0, 16)},

	rooms = 
		{
			{ 	topLeft = vector(32, 14),
				bottomRight = vector(47, 73) },

			{ 	topLeft = vector(48, 59),
				bottomRight = vector(143, 73) },

			{ 	topLeft = vector(144, 59),
				bottomRight = vector(159, 133) },

			{ 	topLeft = vector(64, 119),
				bottomRight = vector(143, 133) },

			{ 	topLeft = vector(16, 119),
				bottomRight = vector(63, 133) },

			{ 	topLeft = vector(0, 0),
				bottomRight = vector(15, 133) },
		},

	roomTransitionMode = "scrolling", 

}

return stageParameters