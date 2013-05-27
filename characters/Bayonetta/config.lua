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
			        targetState = "stand" },
			     { 	condition = 
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
			}
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