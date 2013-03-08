local vector = require 'lib.hump.vector'

local params = {
	
	includeBasicStates = true,

	size = { 
		width =  16,
		height = 20 
	},

	sprites = {
		sheet = "goku.png",
		spriteSizeX = 93,
		spriteSizeY = 119
	},

	states = {

		stand = {
			dynamics = "States/Stand.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-4,1',
				defaultDelay = 0.1
			},

			transitions = {

			    { 	condition = 
			        	function (currentState, collisionFlags)
				            return currentState.owner.control["down"]
				        end,
			        targetState = "crouch" }


			}
		},

		walk = {
			dynamics = "States/Walk.dyn",
			animation = { 
				mode = 'loop',
				frames = '5-8,1',
				defaultDelay = 0.1 
			}
		},

		fall = {
			dynamics = "States/Fall.dyn",
			animation = { 
				mode = 'once',
				frames = '6,2',
				defaultDelay = 0.05 
			}
		},

		jump = {
			dynamics = "States/Jump.dyn",

			animation = { 
				mode = 'once',
				frames = '4-5,2',
				defaultDelay = 0.05
			},
		},

		crouch = {
			dynamics = "States/Crouch.dyn",
			animation = {
				mode = "once",
				frames = "7-8,2",
				defaultDelay = 0.05
			},


			transitions = {
				{	condition = 
						function (currentState, collisionFlags)
				            return (not currentState.owner.control["down"])
				        end,
        			targetState = "stand" },

				{	condition = 
						function (currentState, collisionFlags)
				            if collisionFlags.canMoveDown then
				                currentState.dynamics.velocity.x = 0
				                return true
				            else  
				                return false
				            end 
				        end,
        			targetState = "fall" },
				
			}
		},

		climb = {
			dynamics = "States/Climb.dyn",
			animation = {
				mode = "loop",
				frames = {"1,13", "10,12"},
				defaultDelay = 4/60.0
			},
		}

	},	
	

	initialState = "stand"
}

return params