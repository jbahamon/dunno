local vector = require 'lib.hump.vector'

local enemyTypes = {
	

	{ 
		name = "Goomba",

		size = vector(14, 14),
		
		sprites = {
			sheet = "enemies/Goomba.png",
			spriteSize = vector(16, 16),
			spriteOffset = vector(0, 1)
		},

		states = {

			walking = {
				dynamics = "enemies/GoombaWalk.dyn",
				animation = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				},

				transitions = {

					{	condition = 
							function (currentState, collisionFlags)
								if (currentState.dynamics.velocity.x > 0 and (not collisionFlags.canMoveRight)) or
									(currentState.dynamics.velocity.x < 0 and (not collisionFlags.canMoveLeft)) then
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
	}

}	

return enemyTypes