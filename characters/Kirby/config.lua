
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
			floatUp = { 
				mode = "loop",
				frames = "2,4-5",
				defaultDelay = 4/60
			},

			floatDown = { 
				mode = "loop",
				frames = "2,4-5",
				defaultDelay = 10/60
			},

			inflateAir = {
				mode = "once",
				frames = {"4,5", "4,2", "3,6", "3,3"},
				defaultDelay = 6/60, 
			},

			deflateAir = {
				mode = "once",
				frames = {"3,3", "3,6", "4,2", "4,5"},
				defaultDelay = 6/60, 
			},

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
				defaultDelay = 10/60
			},

			walk = {
				mode = "loop",
				frames = {"3,5", "5,4", "2,6", "5,4"},
				defaultDelay = 8/60,
				delays = {10/60, 8/60, 10/60, 8/60}
			},

			run = {
				mode = "loop",
				frames = {"3,5", "5,4", "2,6", "5,4"},
				defaultDelay = 3.5/60
			},

			hit = {
				mode = "loop",
				frames = "4,1",
				defaultDelay = 2/60
			},

			crouch = {
				mode = "once",
				frames = "2,2",
				defaultDelay = 5/60
			},

			skid = {
				mode = "once",
				frames = "3,4",
				defaultDelay = 5/60.0
			},
		},
	},

	stateMachine = {
		basicStates = {
			jump = {
				dynamics = "States/jump.dyn",
				class = "States/Jump.lua",
				animation = "jump",
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
				animation = "fall",
				class = "States/Fall.lua"
			},

			hit = {
				dynamics = "States/hit.dyn",
				animation = "hit"
			}
		},

		states = {

			run = {
				dynamics = "States/run.dyn",
				animation = "run"
			},

			crouch = {
				dynamics = "States/Crouch.dyn",
				animation = "crouch",
				size = vector(13, 7),
				flags = {"grounded"},
			},

			inflate = {
				dynamics = "States/inflate.dyn",
				animation = "inflateAir",
				size = vector(16,16)
			},

			floatUp = {
				dynamics = "States/floatUp.dyn",
				animation = "floatUp",
				size = vector(20,20)
			},

			floatDown = {
				dynamics = "States/floatDown.dyn",
				animation = "floatDown",
				class = "States/FloatDown.lua",
				size = vector(20,20)
			},

			deflate = {
				dynamics = "States/deflate.dyn",
				animation = "deflateAir",
				class = "States/FloatDown.lua",
				size = vector(16,16)
			},

			skid = {
				dynamics = "States/skid.dyn",
				animation = "skid",
			}

		},

		transitions = {
			{
				from = {"walk", "run"},
				to = "skid",
				condition = 
					function(currentState, collisionFlags)
						return (currentState.owner.control["right"] and (not currentState.owner.control["left"])
							and currentState.owner.physics.velocity.x < 0 and currentState.owner.transform.facing < 0) or 
							(currentState.owner.control["left"] and (not currentState.owner.control["right"])
							and currentState.owner.physics.velocity.x > 0 and currentState.owner.transform.facing > 0)
					end
			},

			{
				from = "skid",
				to = "walk",
				condition =
					function(currentState, collisionFlags)
						return ((not currentState.owner.control["right"] or 
									currentState.owner.control["left"]) and 
								currentState.owner.transform.facing < 0) or
							((not currentState.owner.control["left"] or  
									currentState.owner.control["right"]) and 
								currentState.owner.transform.facing > 0)
					end
			},

			{
				from = {"skid", "run"}
				,
				to = "walk",
				condition =
					function(currentState, collisionFlags)
						return (not currentState.owner.control["right"]) and (not currentState.owner.control["left"])
					end
			},

			{
				from = {"skid", "run"},
				to = "fall",
				condition =
					function(currentState, collisionFlags)
						return collisionFlags.canMoveDown
					end
			},

			{	
				from		= "walk",
				to			= "run",
				condition 	= 
					function (currentState, collisionFlags)
			            return (currentState.owner.control.tap["right"] and (not currentState.owner.control["left"])
							and currentState.owner.physics.velocity.x > 0 and currentState.owner.transform.facing > 0) or 
							(currentState.owner.control.tap["left"] and (not currentState.owner.control["right"])
							and currentState.owner.physics.velocity.x < 0 and currentState.owner.transform.facing < 0)
			        end
			},
			{
				from = {"skid", "run"},
				to = "jump",
				condition =
					function(currentState, collisionFlags)
						return currentState.owner.control["jump"]
					end
			},

			{
				from = "skid",
				to = "stand",
				condition =
					function(currentState, collisionFlags)
						return currentState.owner.physics.velocity.x == 0
					end
			},

			{ 
				from 		= "jump",
				to 			= "fall",
			 	condition 	= 
		        	function(currentState, collisionFlags) 
		            	return currentState.owner.physics.velocity.y >= currentState.dynamics.jumpClipVelocity
		        	end,
			},

			{	
				from		= {"crouch", "inflate", "deflate", "floatUp", "floatDown", "run", "skid"},
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
				from		= { "walk", "stand", "jump", "fall"},
				to			= "inflate",
				condition 	= 
					function (currentState, collisionFlags)
			            return currentState.owner.control["up"]
			        end
			},

			{	
				from		= "fall",
				to			= "inflate",
				condition 	= 
					function (currentState, collisionFlags)
			            return currentState.owner.control.tap["jump"]
			        end
			},

			{	
				from		= "inflate",
				to			= "floatUp",
				condition 	= 
					function (currentState, collisionFlags)
			            return currentState.owner.animation:getStatus() == "finished"
			        end
			},

			{	
				from		= {"floatUp", "floatDown"},
				to			= "deflate",
				condition 	= 
					function (currentState, collisionFlags)
			            return currentState.owner.control["special"]
			        end
			},

			{	
				from		= "floatUp",
				to			= "floatDown",
				condition 	= 
					function (currentState, collisionFlags)
			            return not (currentState.owner.control["up"] or currentState.owner.control["jump"])
			        end
			},


			{	
				from		= "floatDown",
				to			= "floatUp",
				condition 	= 
					function (currentState, collisionFlags)
			            return currentState.owner.control["up"] or currentState.owner.control["jump"]
			        end
			},

			{	
				from		= "deflate",
				to			= "fall",
				condition 	= 
					function (currentState, collisionFlags)
			            return currentState.owner.animation:getStatus() == "finished"
			        end
			},

			{ 	
				from		= { "stand", "walk" },
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