local vector = require 'lib.hump.vector'

local params = {
	
	includeBasicStates = true,

	size = { 
		width =  16,
		height = 20 
	},

	sprites = {
		sheet = "Sprites.png",
		spriteSizeX = 64,
		spriteSizeY = 64
	},

	states = {
		jump = {
			dynamics = "States/jump.dyn",
			animation = { 
				mode = 'once',
				frames = '2,3',
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
				frames = '2,1-2',
				defaultDelay = 0.1,
				delays = {2, 0.1} 
			}
		},

		walk = {
			dynamics = "States/walk.dyn",
			animation = { 
				mode = 'loop',
				frames = '1,1-4',
				defaultDelay = 0.2 
			}

		},

		fall = {
			dynamics = "States/fall.dyn",
			animation = { 
				mode = 'once',
				frames = '2,3',
				defaultDelay = 0.2 
			}
		}
	},	

	initialState = "stand"
}

return params