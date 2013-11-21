local vector = require 'lib.hump.vector'

local params = {
	
	includeBasicStates = true,

	size = vector(10, 12),

	sprites = {
		sheet = "Sprites.png",
		spriteSize = vector(16, 16),
		spriteOffset = vector(0, 0)
	},

	animations = {
		jump = { 
			mode = 'once',
			frames = '2,2',
			defaultDelay = 1/60 
		},

		stand = {
			mode = 'once',
			frames = '1,1',
			defaultDelay = 0.2
		},

		climb = {
			mode = 'loop',
			frames = '1-2,3',
			defaultDelay = 10/60.0,
		},

		walk = {
			mode = 'loop',
			frames = '1-2,1',
			defaultDelay = 4/60 
		},

		skid = {
			mode = 'once',
			frames = '1,2',
			flippedH = true,
			defaultDelay = 4/60
		}
	},

	basicStates = {
		jump = {
			dynamics = "States/jump.dyn",
			animation = "jump",
			class = "States/Jump.lua",
		},

		stand = {
			dynamics = "States/stand.dyn",
			animation = "stand"
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
			animation = "jump",
			class = "States/Fall.lua"
		},

		hit = {
			dynamics = "States/hit.dyn",
			animation = "jump"
		}
	},	

	states = {

		skid = {
			dynamics = "States/skid.dyn",
			animation = "skid",
			class = "States/Skid.lua"
		}
	},

	transitions = {

		{
			from = "walk",
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

			from = "skid",
			to = "walk",
			condition =
				function(currentState, collisionFlags)
					return (not currentState.owner.control["right"]) and (not currentState.owner.control["left"])
				end

		},

		{

			from = "skid",
			to = "fall",
			condition =
				function(currentState, collisionFlags)
					return collisionFlags.canMoveDown
				end

		},

		{

			from = "skid",
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

			from = "fall",
			to = "walk",
			condition =
				function(currentState, collisionFlags)
					return currentState.owner.physics.velocity.x ~= 0 and not collisionFlags.canMoveDown
				end

		}

	},

	initialState = "stand"
}

return params