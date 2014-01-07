local vector = require 'lib.hump.vector'

local elementTypes = {

	{
		name = "Goal",
		elementType = "Neutral",
		physics = false,
		collision = {
			size = vector(16, 16),
		},

		postBuild = function (element)
			element.collision.onDynamicCollide = function (self, dt, otherComponent)
				if otherComponent.container.elementType == "Player" then
					self.container.world:win()
				end
			end
		end
	},

	{ 
		name = "RedKoopa",

		elementType = "Enemy",

		collision = {
			size = vector(14, 14),
		},
		
		animation = {
			sprites = {
				sheet = "Elements/Sprites/RedKoopa.png",
				spriteSize = vector(18, 27),
				spriteOffset = vector(0, 1)
			},
	
			animations = {
				walk = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				},
			},
		},

		stateMachine = {
			states = {
				walking = {
						class = "Elements/States/RedKoopaWalk.lua",
						dynamics = "Elements/Dynamics/EnemyWalk.dyn",
						animation = "walk"
				}
			},
	
			initialState = "walking"
		}
	},

	{
		name = "GreenParaKoopa",

		elementType = "Enemy",

		collision = {
			size = vector(14, 14),
		},
		
		animation = {
			sprites = {
				sheet = "Elements/Sprites/GreenParaKoopa.png",
				spriteSize = vector(18, 28),
				spriteOffset = vector(0, 1)
			},
	
			animations = {
				jump = {
					mode = "loop",
					frames = "1-4,1",
					defaultDelay = 4/60
				},
				walk = {
					mode = "loop",
					frames = "5-6,1",
					defaultDelay = 8/60
				},
			},
		},

		stateMachine = {
			states = {
				jumping = {
					class = "Elements/States/Jump.lua",
					dynamics = "Elements/Dynamics/EnemyJump.dyn",
					animation = "jump"
				},
	
				walking = {
					dynamics = "Elements/Dynamics/EnemyWalk.dyn",
					animation = "walk"
				}
			},
	
			transitions = {
				{	
					from		= { "jumping" },
					to 			= "jumping",
					condition = 
						function (currentState, collisionFlags)
							return (not collisionFlags.canMoveDown) and currentState.owner.physics.velocity.y > 0
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
		}
	},

	{ 
		name = "RedParaGoomba",

		elementType = "Enemy",

		collision = {
			size = vector(14, 14),
		},
		
		animation = {
			sprites = {
				sheet = "Elements/Sprites/RedParaGoomba.png",
				spriteSize = vector(20, 24),
				spriteOffset = vector(0, 1)
			},
	
			animations = {
				winged = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				},
	
				walk = {
					mode = "loop",
					frames = "1-2,2",
					defaultDelay = 8/60
				},
	
				hop = {
					mode = "loop",
					frames = "1-4,1",
					defaultDelay = 4/60
				},
	
				jump = {
					mode = "loop",
					frames = "1-4,1",
					defaultDelay = 4/60
				},
			},
		},

		stateMachine = {
			states = {
				walkingWithWings = {
					dynamics = "Elements/Dynamics/EnemyWalk.dyn",
					animation = "winged"
				},
	
				walking = {
					dynamics = "Elements/Dynamics/EnemyWalk.dyn",
					animation = "walk"
				},
	
				hopping = {
					class = "Elements/States/Hop.lua",
					dynamics = "Elements/Dynamics/EnemyHop.dyn",
					animation = "hop"
				},
	
				jumping = {
					class = "Elements/States/Jump.lua",
					dynamics = "Elements/Dynamics/EnemyJump.dyn",
					animation = "jump"
				}
			},
	
	
			transitions = {
				{	
					from		= { "jumping" },
					to 			= "walkingWithWings",
					condition = 
						function (currentState, collisionFlags)
							return (not collisionFlags.canMoveDown) and 
									currentState.owner.physics.velocity.y > 0 
						end
				},
	
				{	
					from		= { "hopping" },
					to 			= "hopping",
					condition =
						function (currentState, collisionFlags)
							return (not collisionFlags.canMoveDown) and 
									currentState.owner.physics.velocity.y > 0 and 
									currentState.hopCount <= 3
						end
				},
	
			 	{
					from		= { "hopping" },
					to 			= "jumping",
					condition =
						function (currentState, collisionFlags)
							return (not collisionFlags.canMoveDown) and 
									currentState.owner.physics.velocity.y > 0 and 
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
							return currentState.owner.physics.stateTime > 32/60 
						end,
				}
			},
		
	
			initialState = "hopping"
		},
	},


	{ 
		name = "GreenKoopa",

		elementType = "Enemy",

		collision = {
			size = vector(14, 14),
		},
		
		animation = {
			sprites = {
				sheet = "Elements/Sprites/GreenParaKoopa.png",
				spriteSize = vector(18, 28),
				spriteOffset = vector(0, 1)
			},
	
			animations = {
				walk = {
					mode = "loop",
					frames = "5-6,1",
					defaultDelay = 8/60
				}
			},
	
			states = {
	
				walking = {
					class = "Elements/States/Walk.lua",
					dynamics = "Elements/Dynamics/EnemyWalk.dyn",
					animation = "walk"
				}
			},
	
			initialState = "walking"
		},
	},


	{ 
		name = "Goomba",
		elementType = "Enemy",

		collision = {
			size = vector(14, 14),
		},
		
		animation = {
			sprites = {
				sheet = "Elements/Sprites/ParaGoomba.png",
				spriteSize = vector(20, 24),
				spriteOffset = vector(0, 1)
			},
	
			animations = {
				walk = {
					mode = "loop",
					frames = "1-2,2",
					defaultDelay = 8/60
				}
			},
		},

		stateMachine = {
			states = {
				walking = {
					class = "Elements/States/Walk.lua",
					dynamics = "Elements/Dynamics/EnemyWalk.dyn",
					animation = "walk"
				}
			},
	
			initialState = "walking"
		}
	},

	{
		name = 'GreenPiranhaPlant',
		elementType = "Enemy",
		
		collision = {
			size = vector(14, 25),
		},

		animation = {
			sprites = {
				sheet = "Elements/Sprites/GreenPiranhaPlant.png",
				spriteSize = vector(32, 25),
			},
	
			animations = {
				default = {
					mode = "loop",
					frames = "1-2,1",
					defaultDelay = 8/60
				}
			},
		},

		stateMachine = {
			states = {
	
				hidden = {
					dynamics = "Elements/Dynamics/PiranhaPlantStatic.dyn",
					animation = "default"
				},
	
				up = {
					dynamics = "Elements/Dynamics/PiranhaPlantStatic.dyn",
					animation = "default"
				},
	
				movingUp = {
					class = "Elements/States/PiranhaPlantMoving.lua",
					dynamics = "Elements/Dynamics/PiranhaPlantMovingUp.dyn",
					animation = "default"
				},
	
				movingDown = {
					class = "Elements/States/PiranhaPlantMoving.lua",
					dynamics = "Elements/Dynamics/PiranhaPlantMovingDown.dyn",
					animation = "default"
				},
			},
	
			transitions = {
				{	
					from 		= { "hidden" },
					to  		= "movingUp",
					condition 	=
						function (currentState, collisionFlags)
							return currentState.owner.physics.stateTime > currentState.dynamics.maxStateTime
						end
				},
	
				{	
					from 		= { "movingUp" },
					to  		= "up",
					condition 	=
						function (currentState, collisionFlags)
							return currentState.owner.physics.stateTime > currentState.dynamics.maxStateTime
						end
				},
	
				{	
					from 		= { "up" },
					to  		= "movingDown",
					condition 	=
						function (currentState, collisionFlags)
							return currentState.owner.physics.stateTime > currentState.dynamics.maxStateTime
						end
				},
	
				{	
					from 		= { "movingDown" },
					to  		= "hidden",
					condition 	=
						function (currentState, collisionFlags)
							return currentState.owner.physics.stateTime > currentState.dynamics.maxStateTime
						end
				},
	
			},
	
			initialState = "hidden",
		},

		customComponents = {

			{
				class = "Elements/Components/PipeComponent.lua",
				parameters = {
					name = "Pipe",
					physics = false,
					animation = {
						sprites = {
							sheet = "Elements/Sprites/Pipe.png",
							spriteSize = vector(32, 32)
						},

						animations = {
							default = {
								mode = "once",
								frames = "1,1",
								defaultDelay = 0.1
							}
						}
					}
				}
			}
		},

		onStart = function(plant)
				plant.collision:disableTileCollisions()
			end
	}

}	

return elementTypes