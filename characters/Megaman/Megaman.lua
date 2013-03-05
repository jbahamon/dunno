local BasicPlayer = require 'Actors/BasicPlayer/BasicPlayer'

local Class = require 'Util/hump.class'
local vector = require 'Util/Hump.vector'

local anim8 = require 'Util/anim8'

local ElementStateMachine = require 'Actors/ActiveElement/ElementStateMachine'
local ElementState = require 'Actors/ActiveElement/ElementState'
local MegamanJumpState = require 'Actors/Megaman/MegamanJumpState'

local Megaman = Class {
	
	name = "Megaman",

	inherits = BasicPlayer,

	function(self, position, width, height, tileCollider, activeCollider) 
		BasicPlayer.construct(self, position, width, height, tileCollider, activeCollider)
        
		self.sprites = love.graphics.newImage('Actors/Megaman/Sprites.png')

        self.spriteSizeX = 64
        self.spriteSizeY = 64
        self.spritesGrid = anim8.newGrid(self.spriteSizeX,
                                         self.spriteSizeY,
                                         self.sprites:getWidth(),
                                         self.sprites:getHeight())

        self:initStateMachine()
        self.stateMachine:start(position)

	end
}

function Megaman:initStateMachine(sprites)

	self.stateMachine = ElementStateMachine(self.sprites, true, self)
    -- States
    local walk, stand, jump, fall

    local walkAnim = { sprites = self.sprites,
    					animation = anim8.newAnimation('loop',
        	                        self.spritesGrid('1,1-4'),
        	 	                    0.2),
                        spriteSize = vector(self.spriteSizeX, self.spriteSizeY) }

    local standAnim = { sprites = self.sprites,
    					animation = anim8.newAnimation('loop',
        	                        self.spritesGrid('2,1-2'),
        	                        0.1,
        	                        {2, 0.1}),
                        spriteSize = vector(self.spriteSizeX, self.spriteSizeY) }

    local jumpAnim = { sprites = self.sprites,
    					animation = anim8.newAnimation('once',
                                    self.spritesGrid('2,3'),
                                    0.2),
                        spriteSize = vector(self.spriteSizeX, self.spriteSizeY) }

    local fallAnim = { sprites = self.sprites,
    					animation = anim8.newAnimation('once',
                                    self.spritesGrid('2,3'),
                                    0.2),
                        spriteSize = vector(self.spriteSizeX, self.spriteSizeY)}

    local walkDynamics = require 'Actors/Megaman/Walk_dyn'
    local standDynamics = require 'Actors/Megaman/Stand_dyn'
    local jumpDynamics = require 'Actors/Megaman/Jump_dyn'
    local fallDynamics = require 'Actors/Megaman/Fall_dyn'

    local walkState, standState, jumpState, fallState =
        self:addBasicStates({ walk = walkDynamics,
                          stand = standDynamics,
                          jump = jumpDynamics,
                          fall = fallDynamics },

                        { walk = walkAnim,
                          stand = standAnim,
                          jump = jumpAnim,
                          fall = fallAnim })

   
    jumpState = MegamanJumpState(jumpState.name,
                                jumpState.dynamics,
                                jumpState.control,
                                jumpState.animationData)

    jumpState:addTransition( 
        function(currentState, collisionFlags) 
            return currentState.dynamics.velocity.y >= currentState.dynamics.jumpClipVelocity
        end,
        "fall")

    jumpState:addTransition( 
        function(currentState, collisionFlags) 
            return not collisionFlags.canMoveDown
        end,
        "stand")

    self.stateMachine:addState(jumpState)
end

return Megaman