local vector = require 'lib.hump.vector'

local params = {
	
	collision = {
		size = vector(13, 13),
	},

	animation = {	
		sprites = {
			sheet = "Sprites.png",
			spriteSize = vector(23, 23),
			spriteOffset = vector(0, 1)
		},

		animations = {
			jump = { 
				mode = "once",
				frames = "4,6",
				defaultDelay = 0.2
			},

			fall = { 
				mode = "once",
				frames = {"4,3", "4,1", "3,4", "3,1"},
				defaultDelay = 4/60,
			},

			stand = {
				mode = "loop",
				frames = { "5,1","4,4"},
				defaultDelay = 0.2,
				delays = {2, 2/60}
			},

			climb = {
				mode = "loop",
				frames = {"3,2", "5,3", "5,2", "5,3"},
				defaultDelay = 10/60.0
			},

			walk = {
				mode = "loop",
				frames = {"3,5", "5,4", "2,6", "5,4"},
				defaultDelay = 8/60.0,
				delays = {10/60.0, 8/60.0, 10/60.0, 8/60.0}
			},

			hit = {
				mode = "loop",
				frames = "4,1",
				defaultDelay = 2/60.0
			},

			crouch = {
				mode = "once",
				frames = "2,2",
				defaultDelay = 5/60.0
			}
		},
	},

	stateMachine = {
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
				animation = "fall"
			},

			hit = {
				dynamics = "States/hit.dyn",
				animation = "hit"
			}
		},

		states = {
			crouch = {
				dynamics = "States/Crouch.dyn",
				animation = "crouch",
				size = vector(13, 7),
				flags = {"grounded"},
			},
		},

		transitions = {

			{	
				from		= "crouch",
				to 			= "hit",
				condition 	= 
					function (currentState, collisionFlags)
			            return collisionFlags.hit 
			        end
			},

			{	
				from		= "crouch",
				to			= "stand",
				condition 	= 
					function (currentState, collisionFlags)
			            return (not currentState.owner.control["down"])
			        end
			},

			{	
				from		= "crouch",
				to			= "fall",
				condition 	= 
					function (currentState, collisionFlags)
			            if collisionFlags.canMoveDown then
			                currentState.owner.physics.velocity.x = 0
			                return true
			            else  
			                return false
			            end 
			        end
			},

			{ 	
				from		= "stand",
				to 			= "crouch",
				condition 	= 
		        	function (currentState, collisionFlags)
			            return currentState.owner.control["down"]
			        end
			},
		},	

		initialState = "stand"
	}
}

return params