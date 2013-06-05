local vector = require 'lib.hump.vector'

local params = {
	
	includeBasicStates = true,

	size = vector(16, 20),

	sprites = {
		sheet = "Sprites.png",
		spriteSize = vector(33, 34)
	},

	states = {

		pogoJump = {
			dynamics = "States/PogoJump.dyn",
			animation = {
				mode = "once",
				frames = "1-2,5",
				defaultDelay = 0.05
			},

			class = "States/Jump.lua",
        	flags = {"air"},

		},

		pogoFall = {
			dynamics = "States/PogoFall.dyn",
			animation = {
				mode = "once",
				frames = "1,6",
				defaultDelay = 0.2
			},

			flags = {"air"},
		},

		crouch = {
			dynamics = "States/Crouch.dyn",
			animation = {
				mode = "once",
				frames = "1,3",
				defaultDelay = 0.2
			},

			flags = {"grounded"},
		}

	},	

	basicStates = {

		stand = {
				dynamics = "States/Stand.dyn",
				animation = { 
					mode = 'once',
					frames = '1,1',
					defaultDelay = 0.1
				},
			},

		walk = {
			dynamics = "States/Walk.dyn",
			animation = { 
				mode = 'loop',
				frames = '1-4,2',
				defaultDelay = 0.2 
			}
		},

		fall = {
			dynamics = "States/Fall.dyn",
			animation = { 
				mode = 'once',
				frames = '1,4',
				defaultDelay = 0.2 
			},
		},

		jump = {
			dynamics = "States/Jump.dyn",

			animation = { 
				mode = 'once',
				frames = '1,4',
				defaultDelay = 0.2 
			},

			omitTransitions = true,

			class = "States/Jump.lua",
	    	flags = {"air"},
		},

		climb = {
			dynamics = "States/Climb.dyn",
			animation = {
				mode = "loop",
				frames = "1-2,13",
				defaultDelay = 8/60.0
			},
		},

		hit = {
			dynamics = "States/Hit.dyn",
			animation = {
				mode = "once",
				frames = "1,7",
				defaultDelay = 1/60.0
			}
		},

	},


	transitions = {

		{	
			from		= { "crouch", "pogoJump", "pogoFall" },
			to 			= "hit",
			condition 	= 
				function (currentState, collisionFlags)
		            return collisionFlags.hit 
		        end
		},

		{	
			from		= { "crouch" },
			to			= "stand",
			condition 	= 
				function (currentState, collisionFlags)
		            return (not currentState.owner.control["down"])
		        end
		},

		{	
			from		= { "crouch" },
			to			= "fall",
			condition 	= 
				function (currentState, collisionFlags)
		            if collisionFlags.canMoveDown then
		                currentState.dynamics.velocity.x = 0
		                return true
		            else  
		                return false
		            end 
		        end
		},

		{ 	
			from		= { "stand" },
			to 			= "crouch",
			condition 	= 
	        	function (currentState, collisionFlags)
		            return currentState.owner.control["down"]
		        end
		},

		{ 	
			from		= { "fall", "jump" },
			to 			= "pogoFall",
			condition 	= 
	        	function(currentState, collisionFlags) 
	            	return currentState.owner.control["attack"] and collisionFlags.canMoveDown 
	        	end
	    },

		{	
			from		= { "pogoJump" },
			to 			= "pogoFall",
			condition 	=
	    	    function (currentState, collisionFlags)
					return currentState.stateTime > currentState.dynamics.jumpTime
				end
		},

		{	
			from		= { "pogoJump", "pogoFall" },
			to 			= "fall",
			condition 	=
	    	    function (currentState, collisionFlags) 
		            if not currentState.owner.control["attack"] then
		            	if currentState.name == "pogoJump" then
		                	currentState.dynamics.velocity.y = 0
		                end
		                return true
		            else 
		                return false
		            end
		        end
		},

		{	
			from		= { "pogoJump", "pogoFall", "jump" },
			to 			= "pogoJump",
			condition 	=
	    	    function (currentState, collisionFlags)
					return currentState.owner.control["attack"] and not collisionFlags.canMoveDown 
				end
		},
	
		{	
			from		= { "pogoJump", "pogoFall" },
			to 			= "climb",
			condition =
	    	    function (currentState, collisionFlags)
		            local ladder = collisionFlags.specialEvents.ladder
		            if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
		                currentState.owner:move(vector(ladder.position.x - currentState.dynamics.position.x, 0))
		                return true
		            else
		                return false
		            end
		        end
		},

		{
			from		= { "pogoFall", "pogoJump", "jump" },
			to 			= "stand",
			condition =
	    	     function (currentState, collisionFlags) 
			          return (not currentState.owner.control["attack"]) and (not collisionFlags.canMoveDown)
		        end
		},


		{ 	
			from		= { "jump" },
			to 			= "fall",
			condition = 
	        	function(currentState, collisionFlags) 
	        		if (not currentState.owner.control["jump"]) then
	        			currentState.dynamics.velocity.y = 0
	        			return true
	        		else
	        			return (currentState.stateTime > currentState.dynamics.jumpTime)
	        		end
	        	end
	    }

	},

	postBuild = 
		function (player)
			player.states["pogoJump"]:setHoldControl("attack")
			player.states["jump"]:setHoldControl("jump")
		end,

	initialState = "stand"
}

return params