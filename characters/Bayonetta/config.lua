local vector = require 'lib.hump.vector'

local params = {
	
	includeBasicStates = true,

	size = vector(16, 20),

	sprites = {
		sheet = "Sprites.png",
		spriteSize = vector(60, 55),
		spriteOffset = vector(0, 0)
	},

	animations = {
		jump = {
			mode = 'loop',
			frames = '1-2, 4',
			defaultDelay = 4/30.0 
		},

		stand ={ 
			mode = 'loop',
			frames = '1-4,1',
			defaultDelay = 3/30.0
		},

		walk = { 
			mode = 'loop',
			frames = {'1,2', '3,2', '1,3', '3,3'},
			defaultDelay = 4/30.0
		},

		fall = { 
			mode = 'loop',
			frames = '3-4,4',
			defaultDelay = 0.2 
		},

		hit = { 
			mode = 'once',
			frames = '1,4',
			defaultDelay = 0.2 
		}
	},

	basicStates = {
		jump = {
			dynamics = "States/jump.dyn",
			animation = "jump",
			class = "States/Jump.lua"
		},

		stand = {
			dynamics = "States/stand.dyn",
			animation = "stand"
		},

		climb = {
			dynamics = "States/Climb.dyn",
			animation = "jump"
		},

		walk = {
			dynamics = "States/walk.dyn",
			animation = "walk"
		},

		fall = {
			dynamics = "States/fall.dyn",
			animation = "fall"
		},

		hit = {
			dynamics = "States/hit.dyn",
			animation = "hit"
		}
	},	

	states = {},

	initialState = "stand"
}

return params