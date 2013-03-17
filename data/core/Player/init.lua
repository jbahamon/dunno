
local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local Element = require 'data.core.Element'

local PlayerState = require 'data.core.Player.PlayerState'
local Jump = require 'data.core.CommonStates.Jump'
local Climb = require 'data.core.CommonStates.Climb'

local anim8 = require 'lib.anim8'

local Player = Class {

	name = 'Player',
	__includes = Element,

	init =
		function (self, width, height)
			Element.init(self, width, height)
			self.binds, self.control = love.filesystem.load("lib/TLBind.lua")()

			self.binds.keys = {
			    w="up", a="left", s="down", d="right", [" "]="jump", lctrl="attack", escape="menu",
			    up="up", left="left", down="down", right="right", z="jump", rctrl="attack", x="attack"
			}
		end	
}

function Player:setControls(bindings) 
	self.binds.keys = bindings
end

function Player:update(dt)
	self.binds:update()
	Element.update(self, dt)	
end


function Player:addBasicStates(standParams, walkParams, jumpParams, fallParams, climbParams)

    local walk, stand, fall, jump 

    stand = PlayerState("stand", standParams.dynamics, anim8.newAnimation(unpack(standParams.animationData)))
    walk = PlayerState("walk", walkParams.dynamics, anim8.newAnimation(unpack(walkParams.animationData)))
    jump = Jump("jump", jumpParams.dynamics, anim8.newAnimation(unpack(jumpParams.animationData)))
    fall = PlayerState("fall", fallParams.dynamics, anim8.newAnimation(unpack(fallParams.animationData)))
    climb = Climb("climb", climbParams.dynamics, anim8.newAnimation(unpack(climbParams.animationData)))


    stand:addFlag("grounded")
    walk:addFlag("grounded")
    jump:addFlag("air")
    fall:addFlag("air")
    climb:addFlag("climb")

    walk:addTransition( 
    	function(currentState, collisionFlags) 
    		return currentState.hasControl and currentState.owner.control.tap["jump"]
    	end,
    	"jump")

    walk:addTransition( 
    	function(currentState, collisionFlags) 
    		return currentState.hasControl and not (currentState.owner.control["left"] or currentState.owner.control["right"])
    	end,
    	"stand")

    walk:addTransition( 
    	function(currentState, collisionFlags) 
            return collisionFlags.canMoveDown 
    	end,
    	"fall")

    stand:addTransition( 
    	function(currentState, collisionFlags) 
    		return currentState.hasControl and (currentState.owner.control["left"] or currentState.owner.control["right"])
    	end,
    	"walk")

    stand:addTransition( 
        	function(currentState, collisionFlags) 
       		   return currentState.hasControl and currentState.owner.control.tap["jump"]
        	end,
       	"jump")

    stand:addTransition( 
    	function(currentState, collisionFlags) 
    		return collisionFlags.canMoveDown
    	end,
    	"fall")

    stand:addTransition(
        function (currentState, collisionFlags)
            local ladder = collisionFlags.specialEvents.ladder
            if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
                currentState.owner:move(ladder.position.x - currentState.dynamics.position.x, 0)
                return true
            else
                return false
            end
        end,   
        "climb")

    stand:addTransition(
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
        "climb")

	fall:addTransition( 
    	function(currentState, collisionFlags) 
    		return not collisionFlags.canMoveDown
    	end,
    	"stand")

	fall:addTransition(
		function (currentState, collisionFlags)
		    local ladder = collisionFlags.specialEvents.ladder
		    if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
		        currentState.owner:move(ladder.position.x - currentState.dynamics.position.x, 0)
		        return true
		    else
		        return false
		    end
		end,   
		"climb")

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

    jump:addTransition(
        function (currentState, collisionFlags)
            local ladder = collisionFlags.specialEvents.ladder
            if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
                currentState.owner:move(ladder.position.x - currentState.dynamics.position.x, 0)
                return true
            else
                return false
            end
        end,   
        "climb")

    climb:addTransition(
        function (currentState, collisionFlags)
            return currentState.owner.control.tap["jump"] or not collisionFlags.specialEvents.ladder
        end,
        "fall")

    self:addState(walk)
    self:addState(stand)
    self:addState(fall)
    self:addState(jump)
    self:addState(climb)

    return walk, stand, jump, fall, climb
end


function Player:getDefaultStateClass()
	return PlayerState
end


function Player:loadBasicStates(parameters, folder)

	------------------------------------
	-- States
	------------------------------------

	folder = folder or self:getFolder()
	
	local states = parameters.basicStates

	if states then
		
		assert(states.stand and states.walk and states.jump and states.fall and states.climb,
			"All five basic states must be specified for basic state inclusion")

		assert(states.stand.dynamics and states.walk.dynamics and states.jump.dynamics and states.fall.dynamics and states.climb.dynamics,
			"All five basic state dynamics must be specified for basic state inclusion")
		assert(states.stand.animation and states.walk.animation and states.jump.animation and states.fall.animation and states.climb.animation,
				"All five basic state animations must be specified for basic state inclusion")

		local statesData = {stand = {}, walk = {}, jump = {}, fall = {}, climb = {}}

		for stateName, state in pairs(statesData) do
			assert(states[stateName].animation and states[stateName].animation.mode and states[stateName].animation.frames 
				and states[stateName].animation.defaultDelay, "Missing arguments in animation data")
			
			local frames 
			if type(states[stateName].animation.frames) == "table" then
				frames = self.spritesGrid(unpack(states[stateName].animation.frames))
			else
				frames = self.spritesGrid(states[stateName].animation.frames)
			end 

			state.animationData = {
				states[stateName].animation.mode, 
				frames,
				states[stateName].animation.defaultDelay,
				states[stateName].animation.delays or {},
				states[stateName].animation.flippedH or false,
				states[stateName].animation.flippedV or false
			}

			assert(love.filesystem.isFile(folder .. "/" .. states[stateName].dynamics), "Dynamics file \'".. folder .. "/" .. states[stateName].dynamics .. "\'does not exist")

			state.dynamics = love.filesystem.load(folder .. "/" .. states[stateName].dynamics)()

		end

		self:addBasicStates(statesData.stand, statesData.walk, statesData.jump, statesData.fall, statesData.climb)

		for stateName, stateParams in pairs(states) do
			if stateParams.class then
				self:addSingleStateFromParams(stateName, stateParams)
			end

		
			if stateParams.transitions then
				for _, transition in ipairs(stateParams.transitions) do

					assert(transition.condition, "Transition condition not specified for state \'".. stateName .."\'")
					assert(transition.targetState, "Transition target not specified for state \'".. stateName .."\'")
					
					self.states[stateName]:addTransition(transition.condition, transition.targetState)
				end
			end


			if stateParams.flags then
				for _, flag in ipairs(stateParams.flags) do
					assert(type(flag) == "string", "Flag name must be a string, got \'".. tostring(flag) .."\'")
					self.states[stateName]:addFlag(flag)
				end
			end
		end
	end
end


--=====================================
-- Static functions
--=====================================

Player.characterFolder = 'characters/'

--------------------------
-- STATIC FUNCTIONS
--------------------------
function Player.loadBasicFromParams(parameters, folder)

	assert(type(parameters) == "table", "Character configuration file must return a table")

	assert(parameters.size and parameters.size.width and parameters.size.height, "Element size not specified")

	local player = Player(parameters.size.width, parameters.size.height)

	player:setFolder(folder)

	return player
end

return Player