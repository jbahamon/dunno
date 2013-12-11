local vector = require 'lib.hump.vector'

local params = {

	collision = {
		size = vector(16, 20),
	},

	animation = {
		sprites = {
			sheet = "Sprites.png",
			spriteSize = vector(33, 34)
		},

		animations = {
			pogo = {
				mode = "once",
				frames = "1-2,5",
				defaultDelay = 0.05
			},

			pogoFall = {
				mode = "once",
				frames = "2,5",
				defaultDelay = 0.05
			},

			jump = { 
				mode = 'once',
				frames = '1,4',
				defaultDelay = 0.2 
			},

			crouch = {
				mode = "once",
				frames = "1,3",
				defaultDelay = 0.2
			},

			stand = { 
				mode = 'once',
				frames = '1,1',
				defaultDelay = 0.1
			},

			walk = { 
				mode = 'loop',
				frames = '1-4,2',
				defaultDelay = 0.2 
			},

			hit = {
				mode = "loop",
				frames = {"1,7", "2,1"},
				defaultDelay = 1/60.0
			},

			climb = {
				mode = "loop",
				frames = "1-2,13",
				defaultDelay = 8/60.0
			},
		},
	},

	stateMachine = {

		states = {

			pogoJump = {
				dynamics = "States/PogoJump.dyn",
				class = "States/Jump.lua",
	        	flags = {"air"},
	        	animation = "pogo"

			},

			pogoFall = {
				dynamics = "States/PogoFall.dyn",
				animation = "pogoFall",
				flags = {"air"},
			},

			crouch = {
				dynamics = "States/Crouch.dyn",
				animation = "crouch",
				size = vector(16, 10),
				flags = {"grounded"},
			},

		},	

		basicStates = {

			stand = {
					dynamics = "States/Stand.dyn",
					animation = "stand"
				},

			walk = {
				dynamics = "States/Walk.dyn",
				animation = "walk"
			},

			fall = {
				dynamics = "States/Fall.dyn",
				animation = "jump"
			},

			jump = {
				dynamics = "States/Jump.dyn",
				animation = "jump",
				omitTransitions = true,
				class = "States/Jump.lua",
		    	flags = {"air"},
			},

			climb = {
				dynamics = "States/Climb.dyn",
				animation = "climb"
			},

			hit = {
				dynamics = "States/Hit.dyn",
				animation = "hit"
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
			                currentState.owner.physics.velocity.x = 0
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
						return currentState.owner.physics.stateTime > currentState.dynamics.jumpTime
					end
			},

			{	
				from		= { "pogoJump", "pogoFall" },
				to 			= "fall",
				condition 	=
		    	    function (currentState, collisionFlags) 
			            if not currentState.owner.control["attack"] then
			            	if currentState.name == "pogoJump" then
			                	currentState.owner.physics.velocity.y = 0
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
			                currentState.owner:move(vector(ladder.position.x - currentState.owner.transform.position.x, 0))
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
		        			currentState.owner.physics.velocity.y = 0
		        			return true
		        		else
		        			return (currentState.owner.physics.stateTime > currentState.dynamics.jumpTime)
		        		end
		        	end
		    }

		},
		
		initialState = "stand"
	},

	postBuild = 
		function (player)
			player.stateMachine.states["pogoJump"]:setHoldControl("attack")
			player.stateMachine.states["jump"]:setHoldControl("jump")
		end,

	
}

return params