local ActiveElement = require 'data.core.ActiveElement.ActiveElement'
local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local ElementStateMachine = require 'data.core.ActiveElement.ElementStateMachine'
local ElementState = require 'data.core.ActiveElement.ElementState'
local BasicJump = require 'data.core.BasicPlayer.BasicJump'

local BasicPlayer = Class {
    
    name = "BasicPlayer",

    inherits = ActiveElement,

    function(self, position, width, height, tileCollider, activeCollider) 
        ActiveElement.construct(self, position, width, height, tileCollider, activeCollider)
    end

}

function BasicPlayer:addBasicStates(dynamics, anims)

    local walk, stand, fall, jump 

    jump = BasicJump("jump", dynamics.jump, true, anims.jump)
    walk = ElementState("walk", dynamics.walk, true, anims.walk)
    stand = ElementState("stand", dynamics.stand, true, anims.stand)
    fall = ElementState("fall", dynamics.fall, true, anims.fall)

    walk:addTransition( 
    	function(currentState, collisionFlags) 
    		return currentState.control and currentState.controls.tap["jump"]
    	end,
    	"jump")

    walk:addTransition( 
    	function(currentState, collisionFlags) 
    		return currentState.control and not (currentState.controls["left"] or currentState.controls["right"])
    	end,
    	"stand")

    walk:addTransition( 
    	function(currentState, collisionFlags) 
            if collisionFlags.canMoveDown then
                currentState.dynamics.velocity.x = 0
                return true
            else  
                return false
            end 
    	end,
    	"fall")

    stand:addTransition( 
    	function(currentState, collisionFlags) 
    		return currentState.control and (currentState.controls["left"] or currentState.controls["right"])
    	end,
    	"walk")

    stand:addTransition( 
        	function(currentState, collisionFlags) 
       		   return currentState.control and currentState.controls.tap["jump"]
        	end,
       	"jump")

    stand:addTransition( 
    	function(currentState, collisionFlags) 
    		if collisionFlags.canMoveDown then
                currentState.dynamics.velocity.x = 0
                return true
            else  
                return false
            end 
    	end,
    	"fall")

	fall:addTransition( 
    	function(currentState, collisionFlags) 
    		return not collisionFlags.canMoveDown
    	end,
    	"stand")

    jump:addTransition( 
        function(currentState, collisionFlags) 
            return not collisionFlags.canMoveDown
        end,
        "stand")

    jump:addTransition( 
        function(currentState, collisionFlags) 
            return currentState.dynamics.velocity.y > 0
        end,
        "fall")


    self.stateMachine:addState(walk)
    self.stateMachine:addState(stand)
    self.stateMachine:addState(fall)
    self.stateMachine:addState(jump)

    self.stateMachine:setInitialState("stand")

    return walk, stand, jump, fall
end

return BasicPlayer