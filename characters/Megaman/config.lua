local vector = require 'lib.hump.vector'

local params = {
	
	includeBasicStates = true,

	size = vector(16, 20),

	sprites = {
		sheet = "Sprites.png",
		spriteSize = vector(31, 32),
		spriteOffset = vector(0, 0)
	},

	animations = {
		jump = { 
			mode = "loop",
			frames = "1,3",
			defaultDelay = 0.2
		},

		stand = {
			mode = "loop",
			frames = "1-2,1",
			defaultDelay = 0.2,
			delays = {2, 0.2}
		},

		climb = {
			mode = "loop",
			frames = "1-2,5",
			defaultDelay = 10/60.0
		},

		walk = {
			mode = "loop",
			frames = "1-4,2",
			defaultDelay = 0.2
		},

		hit = {
			mode = "loop",
			frames = "1-2,6",
			defaultDelay = 2/60.0
		}
	},

	basicStates = {
		jump = {
			dynamics = "States/jump.dyn",
			class = "States/Jump.lua",
			animation = "jump",
			transitions = {
			 	{ 	condition = 
			        	function(currentState, collisionFlags) 
			            	return currentState.owner.physics.velocity.y >= currentState.dynamics.jumpClipVelocity
			        	end,
			        targetState = "fall" }
			}
		},

		stand = {
			animation = "stand",
			dynamics = "States/stand.dyn",
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
			animation = "hit"
		}
	},	

	initialState = "stand"
}

return params