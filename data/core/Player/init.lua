--- The game player class and helper functions.
-- @class module
-- @name data.core.Player

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local Element = require 'data.core.Element'

local PlayerState = require 'data.core.Player.PlayerState'
local Jump = require 'data.core.CommonStates.BasicJump'
local Climb = require 'data.core.CommonStates.Climb'
local Hit = require 'data.core.CommonStates.Hit'

local anim8 = require 'lib.anim8'


--- Builds a new Player with the default control scheme, a collision box and states.
-- @class function
-- @name Player
-- @param width The width of the Player's collision box.
-- @param height The height of the Player's collision box.
-- @return The newly created Player.

local Player = Class {

	name = 'Player',
	__includes = Element
}

function Player:init(size)
    Element.init(self, size)
    self.binds, self.control = love.filesystem.load("lib/TLBind.lua")()

    self.binds.keys = {
        w="up", a="left", s="down", d="right", [" "]="jump", lctrl="attack", escape="menu",
        up="up", left="left", down="down", right="right", z="jump", rctrl="attack", x="attack"
    }
end 

--- A game player implementation.  Extends @{data.core.Element|Element}.
-- A player has all of the Element's features, plus receiving input from the user.
-- @type Player

--- Sets the player's bindings.
-- @param bindings The bindings to set, as a table.  See <a href="http://love2d.org/wiki/TLbind">TLbind's documentation</a> for details (under bind.keys).
function Player:setControls(bindings) 
	self.binds.keys = bindings
end

--- Updates the Player. Should be called on each frame where the Player is active.
-- @param dt Time since the last update, in seconds.
function Player:update(dt)
	self.binds:update()
	Element.update(self, dt)	
end

--- Adds the basic states and transitions for a player. Called by @{Player:loadBasicStates}.
-- The table entries must have the following structure:
--
-- - animationData: An <a href="https://github.com/kikito/anim8/">anim8</a> animation.
--
-- - dynamics: A dynamics table, as specified (TODO :( )
-- @param basicStatesParams The basic states' parameters, as a table. The table must have "stand", "walk", "jump", "fall" and "climb" entries.
function Player:addBasicStates(basicStatesParams)

    local standParams = basicStatesParams["stand"]
    local walkParams = basicStatesParams["walk"]
    local jumpParams = basicStatesParams["jump"]
    local fallParams = basicStatesParams["fall"]
    local climbParams = basicStatesParams["climb"]
    local hitParams = basicStatesParams["hit"]

    local walk, stand, fall, jump, hit

    stand = PlayerState("stand", anim8.newAnimation(unpack(standParams.animationData)), standParams.dynamics)
    walk = PlayerState("walk", anim8.newAnimation(unpack(walkParams.animationData)), walkParams.dynamics)
    jump = Jump("jump", anim8.newAnimation(unpack(jumpParams.animationData)), jumpParams.dynamics)
    fall = PlayerState("fall", anim8.newAnimation(unpack(fallParams.animationData)), fallParams.dynamics)
    climb = Climb("climb", anim8.newAnimation(unpack(climbParams.animationData)), climbParams.dynamics)
    hit = Hit("hit", anim8.newAnimation(unpack(hitParams.animationData)), hitParams.dynamics)

    stand:addFlag("grounded")
    walk:addFlag("grounded")
    jump:addFlag("air")
    fall:addFlag("air")
    climb:addFlag("climb")


    walk:addTransition(
        function (currentState, collisionFlags)
            return collisionFlags.hit
        end,
        "hit")

    walk:addTransition( 
    	function(currentState, collisionFlags) 
    		return currentState.hasControl and currentState.owner.control.tap["jump"]
    	end,
    	"jump")

    walk:addTransition( 
    	function(currentState, collisionFlags) 
    		return currentState.hasControl and 
                    not (currentState.owner.control["left"] or currentState.owner.control["right"]) and
                    currentState.dynamics.velocity.x == 0
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
                currentState.owner:move(vector(ladder.position.x - currentState.dynamics.position.x, 0))
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
                currentState.owner:move(ladder.position - currentState.dynamics.position)
                return true
            else
                return false
            end
        end,   
        "climb")

    stand:addTransition(
        function (currentState, collisionFlags)
            return collisionFlags.hit
        end,
        "hit")

	fall:addTransition( 
    	function(currentState, collisionFlags) 
    		return (not collisionFlags.canMoveDown) and currentState.dynamics.velocity.y > 0
    	end,
    	"stand")

    fall:addTransition(
        function (currentState, collisionFlags)
            return collisionFlags.hit
        end,
        "hit")

	fall:addTransition(
		function (currentState, collisionFlags)
		    local ladder = collisionFlags.specialEvents.ladder
		    if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
		        currentState.owner:move(vector(ladder.position.x - currentState.dynamics.position.x, 0))
		        return true
		    else
		        return false
		    end
		end,   
		"climb")
    
    jump:addTransition(
        function (currentState, collisionFlags)
            return collisionFlags.hit
        end,
        "hit")

    jump:addTransition( 
        function(currentState, collisionFlags) 
            return not collisionFlags.canMoveDown
        end,
        "stand")

    jump:addTransition(
        function (currentState, collisionFlags)
            local ladder = collisionFlags.specialEvents.ladder
            print("fds")
            if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
                currentState.owner:move(vector(ladder.position.x - currentState.dynamics.position.x, 0))
                return true
            else
                return false
            end
        end,   
        "climb")

    jump:addTransition( 
        function(currentState, collisionFlags) 
            return currentState.dynamics.velocity.y > 0
        end,
        "fall")

    climb:addTransition(
        function (currentState, collisionFlags)
            return collisionFlags.hit
        end,
        "hit")

    climb:addTransition(
        function (currentState, collisionFlags)
            return currentState.owner.control.tap["jump"] or not collisionFlags.specialEvents.ladder
        end,
        "fall")

    hit:addTransition(
        function (currentState, collisionFlags)
            return currentState.hasControl
        end,
        "fall")

    self:addState(walk)
    self:addState(stand)
    self:addState(fall)
    self:addState(jump)
    self:addState(climb)
    self:addState(hit)

    return walk, stand, jump, fall, climb, hit
end

--- Returns the Player's default state class (a <a href="http://vrld.github.com/hump/#hump.class"> hump class</a>).
-- This method is used when building a Player from a file, to determine the class used when no state class is specified.
-- For a Player, it's PlayerState; override this method if you want to create a character with a custom base state.
-- @return The hump class to be used in the construction of this Player's states when no class is specified.
function Player:getDefaultStateClass()
	return PlayerState
end

--- Adds a Players' basic states and transitions from a parameter table.
-- Note that calling this function is completely optional, but offers a way to build the common core of many
-- platforming characters. You can avoid using this function and building al of a Player's states and transitions 
-- from scratch
-- @param parameters The parameter table, as described in (TODO :c)
-- @param folder (Optional) the specific folder to load the state from. If omitted, the Player's folder is used.
function Player:loadBasicStates(parameters, folder)

	------------------------------------
	-- States
	------------------------------------

	folder = folder or self:getFolder()
	
	local states = parameters.basicStates

	if states then
		
		assert(states.stand and 
               states.walk and 
               states.jump and 
               states.fall and 
               states.climb and
               states.hit,
			"All six basic states must be specified for basic state inclusion")

		assert(states.stand.dynamics and
               states.walk.dynamics and
               states.jump.dynamics and 
               states.fall.dynamics and 
               states.climb.dynamics and
               states.hit.dynamics,
			"All six basic state dynamics must be specified for basic state inclusion")
		assert(states.stand.animation and 
               states.walk.animation and 
               states.jump.animation and 
               states.fall.animation and 
               states.climb.animation and
               states.hit.animation,
				"All six basic state animations must be specified for basic state inclusion")

		local statesData = {stand = {}, walk = {}, jump = {}, fall = {}, climb = {}, hit = {} }

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

		self:addBasicStates(statesData)

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

function Player:getHitBy(otherElement)
    Element.getHitBy(self, otherElement)

    if not self.hittable then
        return
    end
    
    if (self:getFacing() > 0 and
        otherElement:getPosition().x < self:getPosition().x) or
        (self:getFacing() < 0 and
        otherElement:getPosition().x > self:getPosition().x)  then
        self:turn()
    end

end

--=====================================
-- Static functions
--=====================================

Player.characterFolder = 'characters/'

--- Loads an empty Player from a minimal set of parameters.
-- @param parameters The set of parameters to be used. It must have width and height as fields.
-- @param folder The base folder to load files (sprites, classes, etc) from. Required (in opposition to uses of folder parameters in Player methods).
function Player.loadBasicFromParams(parameters, folder)

	assert(type(parameters) == "table", "Character configuration file must return a table")

	assert(parameters.size and vector.isvector(parameters.size), "Element size not specified")

	local player = Player(parameters.size)

	player:setFolder(folder)
    player.name = folder
	return player
end

return Player