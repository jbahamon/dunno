local vector = require 'lib.hump.vector'

local params = {
	
	includeBasicStates = true,

	size = vector(10, 12),

	sprites = {
		sheet = "Sprites.png",
		spriteSize = vector(16, 16),
		spriteOffset = vector(0, 0)
	},

	basicStates = {
		jump = {
			dynamics = "States/jump.dyn",
			animation = { 
				mode = 'once',
				frames = '2,2',
				defaultDelay = 1/60 
			},

			class = "States/Jump.lua",
			transitions = {
				{	condition =
			    	    function (currentState, collisionFlags)
				            local ladder = collisionFlags.specialEvents.ladder
				            if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
				                currentState.owner:move(vector(ladder.position.x - currentState.dynamics.position.x, 0))
				                return true
				            else
				                return false
				            end
				        end,
	    			targetState = "climb" },

				{ 	condition = 
			        	function(currentState, collisionFlags) 
				            return not collisionFlags.canMoveDown
				        end,
			        targetState = "stand" },

			}
		},

		stand = {
			vulnerable = true,
			dynamics = "States/stand.dyn",
			animation = { 
				mode = 'once',
				frames = '1,1',
				defaultDelay = 0.2
			}
		},

		climb = {
			dynamics = "States/Climb.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-2,3',
				defaultDelay = 10/60.0,
			}
		},

		walk = {
			dynamics = "States/walk.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-2,1',
				defaultDelay = 4/60 
			}

		},

		fall = {
			dynamics = "States/fall.dyn",
			animation = { 
				mode = 'once',
				frames = '2,2',
				defaultDelay = 0.2 
			}
		},

		hit = {
			dynamics = "States/hit.dyn",
			animation = { 
				mode = 'loop',
				frames = '2,2',
				defaultDelay = 2/60.0 
			}
		}
	},	

	states = {},

	initialState = "stand"
}

return params