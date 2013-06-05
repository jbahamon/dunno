local vector = require 'lib.hump.vector'

local params = {
	
	includeBasicStates = true,

	size = vector(16, 20),

	sprites = {
		sheet = "Sprites.png",
		spriteSize = vector(60, 55),
		spriteOffset = vector(0, 0)
	},

	basicStates = {
		jump = {
			dynamics = "States/jump.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-2, 4',
				defaultDelay = 4/30.0 
			},
			class = "States/Jump.lua"
		},

		stand = {
			vulnerable = true,
			dynamics = "States/stand.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-4,1',
				defaultDelay = 3/30.0
			}
		},

		climb = {
			dynamics = "States/Climb.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-2,4',
				defaultDelay = 4/30.0,
			}
		},

		walk = {
			dynamics = "States/walk.dyn",
			animation = { 
				mode = 'loop',
				frames = {'1,2', '3,2', '1,3', '3,3'},
				defaultDelay = 4/30.0
			}
		},

		fall = {
			dynamics = "States/fall.dyn",
			animation = { 
				mode = 'loop',
				frames = '3-4,4',
				defaultDelay = 0.2 
			}
		},

		hit = {
			dynamics = "States/hit.dyn",
			animation = { 
				mode = 'loop',
				frames = '1,1',
				defaultDelay = 2/30.0 
			}
		}
	},	

	states = {},

	initialState = "stand"
}

return params