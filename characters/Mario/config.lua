local vector = require 'lib.hump.vector'

local params = {
	
	includeBasicStates = true,

	size = vector(10, 12),

	sprites = {
		sheet = "Sprites.png",
		spriteSize = vector(16, 16),
		spriteOffset = vector(0, 0)
	},

	animations = {
		jump = { 
			mode = 'once',
			frames = '2,2',
			defaultDelay = 1/60 
		},

		stand = {
			mode = 'once',
			frames = '1,1',
			defaultDelay = 0.2
		},

		climb = {
			mode = 'loop',
			frames = '1-2,3',
			defaultDelay = 10/60.0,
		},

		walk = {
			mode = 'loop',
			frames = '1-2,1',
			defaultDelay = 4/60 
		}
	},

	basicStates = {
		jump = {
			dynamics = "States/jump.dyn",
			animation = "jump",
			class = "States/Jump.lua",
		},

		stand = {
			dynamics = "States/stand.dyn",
			animation = "stand"
		},

		climb = {
			dynamics = "States/Climb.dyn",
			animation = "climb"
		},

		walk = {
			dynamics = "States/walk.dyn",
			animation = "walk"
		},

		fall = {
			dynamics = "States/fall.dyn",
			animation = "jump"
		},

		hit = {
			dynamics = "States/hit.dyn",
			animation = "jump"
		}
	},	

	states = {},

	initialState = "stand"
}

return params