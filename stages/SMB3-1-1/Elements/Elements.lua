local vector = require 'lib.hump.vector'

local elementTypes = {

	{
		name = "Goal",
		elementType = "Neutral",
		physics = false,
		collision = {
			size = vector(16, 16),
			onDynamicCollide = function (self, dt, otherComponent)
				if otherComponent.container.elementType == "Player" then
					self.container.world:win()
				end
			end
		}
	},

	{ 
		name = "RedKoopa",

		elementType = "Enemy",

		collision = {
			size = vector(14, 14),
			hitDef = {
				target = { Player = true },
				hitType = "contact"
			}
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

				shell = {
					mode = "once",
					frames = "3,1",
					defaultDelay = 1/60
				}

			},
		},

		stateMachine = {
			states = {
				walking = {
						class = "Elements/States/RedKoopaWalk.lua",
						dynamics = "Elements/Dynamics/EnemyWalk.dyn",
						animation = "walk"
				},

				shell = {
					dynamics = "Elements/Dynamics/Shell.dyn",
					animation = "shell",
					class = "Elements/States/Shell.lua"
				},

				thrownShell = {
					dynamics = "Elements/Dynamics/ThrownShell.dyn",
					animation = "shell",
					class = "Elements/States/ThrownShell.lua"
				}

			},

			transitions = {
				{
					from		= {"walking", "thrownShell"},
					to			= "shell",
					condition   = 
						function (currentState, collisionFlags)
							if collisionFlags.hit then
								currentState.owner.physics.velocity = vector(0, 0)
								return true
							end
						end
				},

				{
					from		= "shell",
					to			= "thrownShell",
					condition   = 
						function (currentState, collisionFlags)
							if collisionFlags.touchedFrom then
								if collisionFlags.touchedFrom * currentState.owner.transform.facing < 0 then
									currentState.owner:turn()
								end

								return true
							end
						end
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
			hitDef = {
				target = { Player = true },
				hitType = "contact"
			}
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
				shell = {
					mode = "once",
					frames = "7,1",
					defaultDelay = 1/60
				}
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
				},

				shell = {
					dynamics = "Elements/Dynamics/Shell.dyn",
					animation = "shell",
					class = "Elements/States/Shell.lua"
				},

				thrownShell = {
					dynamics = "Elements/Dynamics/ThrownShell.dyn",
					animation = "shell",
					class = "Elements/States/ThrownShell.lua"
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
							if collisionFlags.hit then
								currentState.owner.physics.velocity = vector(0, 0)
								return true
							end
						end
				},

				{
					from		= {"walking", "thrownShell"},
					to			= "shell",
					condition   = 
						function (currentState, collisionFlags)
							if collisionFlags.hit then
								currentState.owner.physics.velocity = vector(0, 0)
								return true
							end
						end
				},

				{
					from		= "shell",
					to			= "thrownShell",
					condition   = 
						function (currentState, collisionFlags)
							if collisionFlags.touchedFrom then
								if collisionFlags.touchedFrom * currentState.owner.transform.facing < 0 then
									currentState.owner:turn()
								end

								return true
							end
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
			hitDef = {
				target = { Player = true },
				hitType = "contact"
			}
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

				die = {
					mode = "once",
					frames = "3,2",
					defaultDelay = 1
				}
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
				},

				dying = {
					class = "Elements/States/Death.lua",
					dynamics = "Elements/Dynamics/Death.dyn",
					animation = "die"
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
							if collisionFlags.hit then
								currentState.owner.physics.velocity.y = 0
								return true
							end
						end
				},
	
				{	from		= "walkingWithWings",
					to 			= "hopping",
					condition = 	
						function (currentState, collisionFlags)
							return currentState.owner.physics.stateTime > 32/60 
						end,
				},

				{
					from = "walking",
					to = "dying",
					condition = function(currentState, collisionFlags)
						return collisionFlags.hit
					end
				}


			},
		
	
			initialState = "hopping"
		},
	},


	
	{ 
		name = "Goomba",
		elementType = "Enemy",


		collision = {
			size = vector(14, 14),
			hitDef = {
				target = { Player = true },
				hitType = "contact"
			}
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
				},

				die = {
					mode = "once",
					frames = "3,2",
					defaultDelay = 1
				}
			},
		},

		stateMachine = {
			states = {
				walking = {
					class = "Elements/States/Walk.lua",
					dynamics = "Elements/Dynamics/EnemyWalk.dyn",
					animation = "walk"
				},

				dying = {
					class = "Elements/States/Death.lua",
					dynamics = "Elements/Dynamics/Death.dyn",
					animation = "die"
				}
			},

			transitions = {
				{
					from = "walking",
					to = "dying",
					condition = function(currentState, collisionFlags)
						return collisionFlags.hit
					end
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
			hitDef = {
				target = { Player = true },
				hitType = "contact"
			},
			getHitBy = function(self, hitDef)
				if hitDef.hitType == "contact" then 
					return "dodge"
				else
					self.collisionFlags.hit = true
					return "hit"
				end
			end
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