local vector = require 'lib.hump.vector'

local params = {
	
	includeBasicStates = true,

	size = vector(16, 20),

	sprites = {
		sheet = "Sprites.png",
		spriteSize = vector(31, 32),
		spriteOffset = vector(0, 1)
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
			        targetState = "fall" },

				{ 	condition = 
			        	function(currentState, collisionFlags) 
				            return not collisionFlags.canMoveDown
				        end,
			        targetState = "stand" }
			}
		},

		stand = {
			dynamics = "States/stand.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-2,1',
				defaultDelay = 0.2, 
				delays = {2, 0.2} 
			}
		},

		climb = {
			dynamics = "States/stand.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-2,5',
				defaultDelay = 0.5,
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