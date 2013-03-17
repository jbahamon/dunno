local vector = require 'lib.hump.vector'

local stageParameters ={
	
	map = "TomahawkMan.tmx",

	rooms = {
				{ 	topLeft = vector(1, 17),
					bottomRight = vector(48, 31) },

				{ 	topLeft = vector(33,32),
					bottomRight = vector(48, 46) },

				{ 	topLeft = vector(33,47),
					bottomRight = vector(48, 61) },

				{ 	topLeft = vector(49, 47),
					bottomRight = vector(64, 61) },

				{ 	topLeft = vector(65, 47),
					bottomRight = vector(112, 61) },

				{ 	topLeft = vector(97, 32),
					bottomRight = vector(112, 46) },

				{ 	topLeft = vector(97, 17),
					bottomRight = vector(144, 31) },

				{ 	topLeft = vector(145, 17),
					bottomRight = vector(160, 31) },

				{ 	topLeft = vector(97, 2),
					bottomRight = vector(160, 16) },

				{ 	topLeft = vector(145, 32),
					bottomRight = vector(160, 46) },

				{ 	topLeft = vector(145, 47),
					bottomRight = vector(160, 61) },

				{ 	topLeft = vector(161, 47),
					bottomRight = vector(176, 61) },

				{ 	topLeft = vector(177, 47),
					bottomRight = vector(208, 61) },

				{ 	topLeft = vector(193, 32),
					bottomRight = vector(208, 46) },

				{ 	topLeft = vector(177, 32),
					bottomRight = vector(192, 46),
					hidden = true },

				{ 	topLeft = vector(193, 17),
					bottomRight = vector(224, 31) },

				{ 	topLeft = vector(225, 17),
					bottomRight = vector(240, 31) },

				{ 	topLeft = vector(241, 17),
					bottomRight = vector(256, 31) },

				{ 	topLeft = vector(209, 32),
					bottomRight = vector(224, 46) },

				{ 	topLeft = vector(225, 32),
					bottomRight = vector(240, 46) },

				{ 	topLeft = vector(241, 32),
					bottomRight = vector(256, 46) }

		},

	roomTransitionMode = "fading", 

	--startingPosition = vector(198, 51),
	startingPosition = vector(124, 21),

	--{ stageElements = {}}

	additionalParameters = {},

	defaultCameraMode = { mode = "followPlayer",
						  tension = vector(8, 0)}

	--defaultCameraMode = { mode = "snap",
	--						vertical = {}, horizontal = {} }

}

return stageParameters