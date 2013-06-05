	local vector = require 'lib.hump.vector'

local enemyTypes = {

	{ 
		name = "RedKoopa",

		elementType = "Enemy",

		size = vector(14, 14),
		
		sprites = {
			sheet = "Enemies/Sprites/RedKoopa.png",
			spriteSize = vector(18, 27),
			spriteOffset = vector(0, 1)
		},

		states = {

			walking = {
				class = "Enemies/States/RedKoopaWalk.lua",
				dynamics = "Enemies/Dynamics/EnemyWalk.dyn",
				animation = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				},
			}
		},

		initialState = "walking"
	},

	{ 
		name = "GreenParaKoopa",

		elementType = "Enemy",

		size = vector(14, 14),
		
		sprites = {
			sheet = "Enemies/Sprites/GreenParaKoopa.png",
			spriteSize = vector(18, 28),
			spriteOffset = vector(0, 1)
		},

		states = {
			jumping = {
				class = "Enemies/States/Jump.lua",
				dynamics = "Enemies/Dynamics/EnemyJump.dyn",
				animation = {
					mode = "loop",
					frames = "1-4,1",
					defaultDelay = 4/60
				},
			},

			walking = {
				dynamics = "Enemies/Dynamics/EnemyWalk.dyn",
				animation = {
					mode = "loop",
					frames = "5-6,1",
					defaultDelay = 8/60
				},

			}
		},

		transitions = {
			{	
				from		= { "jumping" },
				to 			= "jumping",
				condition = 
					function (currentState, collisionFlags)
						return (not collisionFlags.canMoveDown) and currentState.dynamics.velocity.y > 0
					end,
			},

			{	
				from		= { "jumping" },
				to 			= "walking",
				condition = 
					function (currentState, collisionFlags)
						return collisionFlags.hit and false -- TODO: life
					end
			}
		},

		initialState = "jumping"
	},

	{ 
		name = "RedParaGoomba",

		elementType = "Enemy",

		size = vector(14, 14),
		
		sprites = {
			sheet = "Enemies/Sprites/RedParaGoomba.png",
			spriteSize = vector(20, 24),
			spriteOffset = vector(0, 1)
		},

		states = {

			walkingWithWings = {
				dynamics = "Enemies/Dynamics/EnemyWalk.dyn",
				animation = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				},
			},

			walking = {
				dynamics = "Enemies/Dynamics/EnemyWalk.dyn",
				animation = {
					mode = "loop",
					frames = "1-2,2",
					defaultDelay = 8/60
				},
			},

			hopping = {
				class = "Enemies/States/Hop.lua",
				dynamics = "Enemies/Dynamics/EnemyHop.dyn",
				animation = {
					mode = "loop",
					frames = "1-4,1",
					defaultDelay = 4/60
				},
			},

			jumping = {
				class = "Enemies/States/Jump.lua",
				dynamics = "Enemies/Dynamics/EnemyJump.dyn",
				animation = {
					mode = "loop",
					frames = "1-4,1",
					defaultDelay = 4/60
				},
			}

		},


		transitions = {
			{	
				from		= { "jumping" },
				to 			= "walkingWithWings",
				condition = 
					function (currentState, collisionFlags)
						return (not collisionFlags.canMoveDown) and 
								currentState.dynamics.velocity.y > 0 
					end
			},

			{	
				from		= { "hopping" },
				to 			= "hopping",
				condition =
					function (currentState, collisionFlags)
						return (not collisionFlags.canMoveDown) and 
								currentState.dynamics.velocity.y > 0 and 
								currentState.hopCount <= 3
					end
			},

		 	{
				from		= { "hopping" },
				to 			= "jumping",
				condition =
					function (currentState, collisionFlags)
						return (not collisionFlags.canMoveDown) and 
								currentState.dynamics.velocity.y > 0 and 
								currentState.hopCount > 3
					end
			},

			{
				from		= { "jumping", "walkingWithWings", "hopping" },
				to 			= "walking",
				condition = 
					function (currentState, collisionFlags)
						return collisionFlags.hit and false -- TODO: life
					end
			},

			{	from		= "walkingWithWings",
				to 			= "hopping",
				condition = 	
					function (currentState, collisionFlags)
						return currentState.stateTime > 32/60 
					end,
			}
		},
	

		initialState = "hopping"
	},


	{ 
		name = "GreenKoopa",

		elementType = "Enemy",

		size = vector(14, 14),
		
		sprites = {
			sheet = "Enemies/Sprites/GreenParaKoopa.png",
			spriteSize = vector(18, 28),
			spriteOffset = vector(0, 1)
		},

		states = {

			walking = {
				class = "Enemies/States/Walk.lua",
				dynamics = "Enemies/Dynamics/EnemyWalk.dyn",
				animation = {
					mode = "loop",
					frames = "5-6,1",
					defaultDelay = 8/60
				}
			}
		},

		initialState = "walking"
	},


	{ 
		name = "Goomba",
		--elementType = "Enemy",

		size = vector(14, 14),
		
		sprites = {
			sheet = "Enemies/Sprites/ParaGoomba.png",
			spriteSize = vector(20, 24),
			spriteOffset = vector(0, 1)
		},

		states = {

			walking = {
				class = "Enemies/States/Walk.lua",
				dynamics = "Enemies/Dynamics/EnemyWalk.dyn",
				animation = {
					mode = "loop",
					frames = "1-2,2",
					defaultDelay = 8/60
				}
			}
		},

		initialState = "walking"
	},

	{
		name = 'GreenPiranhaPlant',
		class = 'Enemies/Classes/PiranhaPlant.lua',
		size = vector(14, 25),

		sprites = {
			sheet = "Enemies/Sprites/GreenPiranhaPlant.png",
			spriteSize = vector(32, 25),
		},

		helperAnimations = {
			Pipe = 

			{	
				sprites = {
					sheet = "Enemies/Sprites/Pipe.png",
					spriteSize = vector(32, 32)
				},

				animation = {
					mode = "once",
					frames = "1,1",
					defaultDelay = 0.1
				}

			}
		},

		states = {

			hidden = {
				dynamics = "Enemies/Dynamics/PiranhaPlantStatic.dyn",
				animation = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				}
			},

			up = {
				dynamics = "Enemies/Dynamics/PiranhaPlantStatic.dyn",
				animation = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				}
			},

			movingUp = {
				class = "Enemies/States/PiranhaPlantMoving.lua",
				dynamics = "Enemies/Dynamics/PiranhaPlantMovingUp.dyn",
				animation = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				}
			},

			movingDown = {
				class = "Enemies/States/PiranhaPlantMoving.lua",
				dynamics = "Enemies/Dynamics/PiranhaPlantMovingDown.dyn",
				animation = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				}
			},
		},

		transitions = {

			{	
				from 		= { "hidden" },
				to  		= "movingUp",
				condition 	=
					function (currentState, collisionFlags)
						return currentState.stateTime > currentState.dynamics.maxStateTime
					end
			},

			{	
				from 		= { "movingUp" },
				to  		= "up",
				condition 	=
					function (currentState, collisionFlags)
						return currentState.stateTime > currentState.dynamics.maxStateTime
					end
			},

			{	
				from 		= { "up" },
				to  		= "movingDown",
				condition 	=
					function (currentState, collisionFlags)
						return currentState.stateTime > currentState.dynamics.maxStateTime
					end
			},

			{	
				from 		= { "movingDown" },
				to  		= "hidden",
				condition 	=
					function (currentState, collisionFlags)
						return currentState.stateTime > currentState.dynamics.maxStateTime
					end
			},

		},

		initialState = "hidden"
	}


}	

return enemyTypes