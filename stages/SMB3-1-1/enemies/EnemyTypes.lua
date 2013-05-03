	local vector = require 'lib.hump.vector'

local enemyTypes = {

	{ 
		name = "RedKoopa",

		elementType = "Enemy",

		size = vector(14, 14),
		
		sprites = {
			sheet = "enemies/RedKoopa.png",
			spriteSize = vector(18, 27),
			spriteOffset = vector(0, 1)
		},

		states = {

			walking = {
				dynamics = "enemies/EnemyWalk.dyn",
				animation = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				},

				transitions = {

					{	condition = 
							function (currentState, collisionFlags)
								if collisionFlags.hit or
									(currentState.dynamics.velocity.x > 0 and (not collisionFlags.canMoveRight)) or
									(currentState.dynamics.velocity.x < 0 and (not collisionFlags.canMoveLeft)) then

									currentState:turn()
									collisionFlags.hit = false

									return true
								else
									return false
								end
							end,
						targetState = "walking" },

					{	condition = 
							function (currentState, collisionFlags)
								if (not collisionFlags.canMoveDown) and (not collisionFlags.standingOnSolid) then
									currentState.owner:moveTo(currentState.dynamics.oldPosition)
									currentState:turn()
									return true
								else
									return false
								end
							end,
						targetState = "walking" }
				}

			}
		},

		initialState = "walking"
	},

	{ 
		name = "GreenParaKoopa",

		elementType = "Enemy",

		size = vector(14, 14),
		
		sprites = {
			sheet = "enemies/GreenParaKoopa.png",
			spriteSize = vector(18, 28),
			spriteOffset = vector(0, 1)
		},

		states = {
			jumping = {
				class = "enemies/Jump.lua",
				dynamics = "enemies/EnemyJump.dyn",
				animation = {
					mode = "loop",
					frames = "1-4,1",
					defaultDelay = 4/60
				},

				transitions = {

					{	condition = 
							function (currentState, collisionFlags)
								return (not collisionFlags.canMoveDown) and currentState.dynamics.velocity.y > 0
							end,
						targetState = "jumping" 

					},

					{	condition = 
						function (currentState, collisionFlags)
							return collisionFlags.hit and false -- TODO: life
						end,
						targetState = "walking" }
				}
			},

			walking = {
				dynamics = "enemies/EnemyWalk.dyn",
				animation = {
					mode = "loop",
					frames = "5-6,1",
					defaultDelay = 8/60
				},

				transitions = {

					{	condition = 
							function (currentState, collisionFlags)
								if collisionFlags.hit or
									(currentState.dynamics.velocity.x > 0 and (not collisionFlags.canMoveRight)) or
									(currentState.dynamics.velocity.x < 0 and (not collisionFlags.canMoveLeft)) then

									currentState:turn()
									collisionFlags.hit = false
									return true
								else
									return false
								end
							end,
						targetState = "walking" }
				}

			}
		},

		initialState = "jumping"
	},

	{ 
		name = "GreenKoopa",

		elementType = "Enemy",

		size = vector(14, 14),
		
		sprites = {
			sheet = "enemies/GreenParaKoopa.png",
			spriteSize = vector(18, 28),
			spriteOffset = vector(0, 1)
		},

		states = {

			walking = {
				dynamics = "enemies/EnemyWalk.dyn",
				animation = {
					mode = "loop",
					frames = "5-6,1",
					defaultDelay = 8/60
				},

				transitions = {

					{	condition = 
							function (currentState, collisionFlags)
								if collisionFlags.hit or
									(currentState.dynamics.velocity.x > 0 and (not collisionFlags.canMoveRight)) or
									(currentState.dynamics.velocity.x < 0 and (not collisionFlags.canMoveLeft)) then

									currentState:turn()
									collisionFlags.hit = false
									return true
								else
									return false
								end
							end,
						targetState = "walking" }
				}

			}
		},

		initialState = "walking"
	},


	{ 
		name = "Goomba",

		elementType = "Enemy",

		size = vector(14, 14),
		
		sprites = {
			sheet = "enemies/Goomba.png",
			spriteSize = vector(16, 16),
			spriteOffset = vector(0, 1)
		},

		states = {

			walking = {
				dynamics = "enemies/EnemyWalk.dyn",
				animation = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				},

				transitions = {

					{	condition = 
							function (currentState, collisionFlags)
								if collisionFlags.hit or
									(currentState.dynamics.velocity.x > 0 and (not collisionFlags.canMoveRight)) or
									(currentState.dynamics.velocity.x < 0 and (not collisionFlags.canMoveLeft)) then
									currentState:turn()

									collisionFlags.hit = false
									return true
								else
									return false
								end
							end,
						targetState = "walking" }

				}

			}
		},

		initialState = "walking"
	}

}	

return enemyTypes