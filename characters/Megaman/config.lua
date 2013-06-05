local vector = require 'lib.hump.vector'

local params = {
	
	includeBasicStates = true,

	size = vector(16, 20),

	sprites = {
		sheet = "Sprites.png",
		spriteSize = vector(31, 32),
		spriteOffset = vector(0, 0)
	},

	basicStates = {
		jump = {
			dynamics = "States/jump.dyn",
			animation = { 
				mode = 'once',
				frames = '1,3',
				defaultDelay = 0.2 
			},
			class = "States/Jump.lua",
			transitions = {
			 	{ 	condition = 
			        	function(currentState, collisionFlags) 
			            	return currentState.dynamics.velocity.y >= currentState.dynamics.jumpClipVelocity
			        	end,
			        targetState = "fall" }
			}
		},

		stand = {
			vulnerable = true,
			dynamics = "States/stand.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-2,1',
				defaultDelay = 0.2, 
				delays = {2, 0.2} 
			}
		},

		climb = {
			dynamics = "States/Climb.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-2,5',
				defaultDelay = 10/60.0,
			}
		},

		walk = {
			dynamics = "States/walk.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-4,2',
				defaultDelay = 0.2 
			}

		},

		fall = {
			dynamics = "States/fall.dyn",
			animation = { 
				mode = 'once',
				frames = '1,3',
				defaultDelay = 0.2 
			}
		},

		hit = {
			dynamics = "States/hit.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-2,6',
				defaultDelay = 2/60.0 
			}
		}
	},	

	states = {},

	initialState = "stand"
}

return params