local vector = require 'lib.hump.vector'

print("Holi")
local params = {
	
	includeBasicStates = true,

	size = { 
		width =  16,
		height = 20 
	},

	sprites = {
		sheet = "Sprites.png",
		spriteSizeX = 66,
		spriteSizeY = 68
	},

	states = {

		stand = {
			dynamics = "States/Stand.dyn",
			animation = { 
				mode = 'once',
				frames = '1,1',
				defaultDelay = 0.1
			},

			transitions = {
				{ 	condition = 
						function (currentState, collisionFlags)
				            local ladder = collisionFlags.specialEvents.ladder
				            if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
				                currentState.owner.move(ladder.position.x - currentState.dynamics.position.x, 0)
				                return true
				            else
				                return false
				            end
				        end,
			    	targetState = "climb" },

			    { 	condition = 
			    	    function (currentState, collisionFlags)
                	        local ladder = collisionFlags.specialEvents.standingOnLadder
				            if ladder and currentState.owner.control["down"] then
				                currentState.owner:move(ladder.position.x - currentState.dynamics.position.x, 
			                                            ladder.position.y - currentState.dynamics.position.y)
				                return true
				            else
				                return false
				            end
				        end,
			        targetState = "climb" },

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

			transitions = {
			 	{ 	condition = 
			        	function(currentState, collisionFlags) 
			            	return currentState.owner.control["attack"]
			        	end,
			        targetState = "pogoFall" },

				{ 	condition = 
			    	    function (currentState, collisionFlags)
				            local ladder = collisionFlags.specialEvents.ladder
				            if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
				                currentState.owner:move(ladder.position.x - currentState.dynamics.position.x, 0)
				                return true
				            else
				                return false
				            end
				        end,
			        targetState = "climb" }
			}
		},

		jump = {
			dynamics = "States/Jump.dyn",

			animation = { 
				mode = 'once',
				frames = '1,4',
				defaultDelay = 0.2 
			},

			class = "States/Jump.lua",

			transitions = {
				{	condition =
			    	    function (currentState, collisionFlags)
				            local ladder = collisionFlags.specialEvents.ladder
				            if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
				                currentState.owner:move(ladder.position.x - currentState.dynamics.position.x, 0)
				                return true
				            else
				                return false
				            end
				        end,
        			targetState = "climb" },
			 	{ 	condition = 
			        	function(currentState, collisionFlags) 
			            	return (not currentState.owner.control["jump"]) or (currentState.jumpTimer > currentState.dynamics.jumpTime)
			        	end,
			        targetState = "fall" },

				{ 	condition = 
			        	function(currentState, collisionFlags) 
				            return not collisionFlags.canMoveDown
				        end,
			        targetState = "stand" },

			    {	condition =
			    	    function (currentState, collisionFlags)
            				return currentState.owner.control["attack"] and not collisionFlags.canMoveDown 
        				end,
        			targetState = "pogoJump" },

			    {	condition =
			    	    function (currentState, collisionFlags)
            				return currentState.owner.control["attack"] and collisionFlags.canMoveDown 
        				end,
        			targetState = "pogoFall" }
        		
        	}
		},

		pogoJump = {
			dynamics = "States/PogoJump.dyn",
			animation = {
				mode = "once",
				frames = "1-2,5",
				defaultDelay = 0.05
			},

			class = "States/Jump.lua",

			transitions = {
 				{	condition =
			    	    function (currentState, collisionFlags)
            				return currentState.owner.control["attack"] and not collisionFlags.canMoveDown 
        				end,
        			targetState = "pogoJump" },
        		{	condition =
			    	    function (currentState, collisionFlags)
							return currentState.jumpTimer > currentState.dynamics.jumpTime
        				end,
        			targetState = "pogoFall" },
        		{	condition =
			    	     function (currentState, collisionFlags) 
				            if not currentState.owner.control["attack"] then
				                currentState.dynamics.velocity.y = 0
				                return true
				            else 
				                return false
				            end
				        end,
        			targetState = "fall" },
        		{	condition =
			    	    function (currentState, collisionFlags)
				            local ladder = collisionFlags.specialEvents.ladder
				            if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
				                currentState.owner:move(ladder.position.x - currentState.dynamics.position.x, 0)
				                return true
				            else
				                return false
				            end
				        end,
        			targetState = "climb" },
			}

		},

		pogoFall = {
			dynamics = "States/PogoFall.dyn",
			animation = {
				mode = "once",
				frames = "1,6",
				defaultDelay = 0.2
			},
			
			transitions = {
 				{	condition =
			    	    function (currentState, collisionFlags)
            				return not currentState.owner.control["attack"]
        				end,
        			targetState = "fall" },
        		{	condition =
			    	    function (currentState, collisionFlags)
							return currentState.owner.control["attack"] and not collisionFlags.canMoveDown 
        				end,
        			targetState = "pogoJump" },
        		{	condition =
			    	     function (currentState, collisionFlags) 
					          return (not currentState.owner.control["attack"]) and (not collisionFlags.canMoveDown)
				        end,
        			targetState = "stand" },
        		{	condition =
			    	    function (currentState, collisionFlags)
				            local ladder = collisionFlags.specialEvents.ladder
				            if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
				                currentState.owner:move(ladder.position.x - currentState.dynamics.position.x, 0)
				                return true
				            else
				                return false
				            end
				        end,
        			targetState = "climb" },
			}

		},

		crouch = {
			dynamics = "States/Crouch.dyn",
			animation = {
				mode = "once",
				frames = "1,3",
				defaultDelay = 0.2
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
				frames = "1-2,13",
				defaultDelay = 8/60.0
			}
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