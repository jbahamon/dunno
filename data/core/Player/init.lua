
local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local Element = require 'data.core.Element'

local PlayerState = require 'data.core.Player.PlayerState'
local Jump = require 'data.core.CommonStates.Jump'

local anim8 = require 'lib.anim8'

local Player = Class {

	name = 'Player',
	__includes = Element,

	init =
		function (self, width, height, tileCollider, activeCollider)
			Element.init(self, width, height, tileCollider, activeCollider)
			self.binds, self.control = love.filesystem.load("lib/TLbind.lua")()

			self.binds.keys = {
			    w="up", a="left", s="down", d="right", [" "]="jump", lctrl="attack", escape="menu",
			    up="up", left="left", down="down", right="right", z="jump", rctrl="attack", x="attack"
			}
		end	
}

function Player:setSpriteData(sprites, spriteSizeX, spriteSizeY)
	self.spriteSizeX = spriteSizeX
	self.spriteSizeY = spriteSizeY
	self.sprites = love.graphics.newImage(sprites)
	self.spritesGrid = anim8.newGrid(self.spriteSizeX,
                                         self.spriteSizeY,
                                         self.sprites:getWidth(),
                                         self.sprites:getHeight())
end

function Player:setControls(bindings) 
	self.binds.keys = bindings
end

function Player:update(dt)
	self.binds:update()
	Element.update(self, dt)	
end


function Player:addBasicStates(standParams, walkParams, jumpParams, fallParams)

    local walk, stand, fall, jump 

    stand = PlayerState("stand", standParams.dynamics, anim8.newAnimation(unpack(standParams.animationData)))
    walk = PlayerState("walk", walkParams.dynamics, anim8.newAnimation(unpack(walkParams.animationData)))
    jump = Jump("jump", jumpParams.dynamics, anim8.newAnimation(unpack(jumpParams.animationData)))
    fall = PlayerState("fall", fallParams.dynamics, anim8.newAnimation(unpack(jumpParams.animationData)))

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


    self:addState(walk)
    self:addState(stand)
    self:addState(fall)
    self:addState(jump)

    return walk, stand, jump, fall
end


---------------------------------------
-- Static functions
---------------------------------------

Player.characterFolder = 'characters/'


Player.defaultParameters = {
	
	size = { width =  10,
			 height = 16 },

	states = {
		jump = {
			dynamics = "data/core/BasicStates/jump/jump.dyn",
			class = "data/core/BasicStates/jump/jump.dyn"
		},
		stand = {
			dynamics = "data/core/BasicStates/stand/stand.dyn"
		},
		walk = {
			dynamics = "data/core/BasicStates/walk/walk.dyn"
		},
		fall = {
			dynamics = "data/core/BasicStates/fall/fall.dyn"
		}
	}

}

function Player.loadFromFolder(path, tileCollider, activeCollider)
	local defaultParameters = Player.defaultParameters

	local folder = Player.characterFolder .. string.gsub(path, '[^%a%d-_/]', '')
	assert(love.filesystem.isFile(folder .. "/config.lua"), "Character configuration file \'".. folder .. "/config.lua"   .."\' not found")
	local ok, playerFile = pcall(love.filesystem.load, folder .. "/config.lua")

	assert(ok, "Character file has syntax errors: " .. tostring(playerFile))

	local parameters = playerFile()
	assert(type(parameters) == "table", "Character configuration file must return a table")

	------------------------------------
	-- Size
	------------------------------------

	assert(parameters.size and parameters.size.width and parameters.size.height, "Character size not specified")

	local player = Player(parameters.size.width, parameters.size.height, tileCollider, activeCollider)

	------------------------------------
	-- Sprite Data
	------------------------------------

	assert(parameters.sprites,"No sprite info supplied")
	assert(parameters.sprites.sheet, "No spritesheet info supplied" )

	local sprites = folder .. "/" .. string.gsub(parameters.sprites.sheet, '[^%a%d-_/.]', '')

	assert(love.filesystem.isFile(sprites), "Spritesheet \'".. sprites .."\' supplied is not a file")	
	assert(parameters.sprites.spriteSizeX and parameters.sprites.spriteSizeY,
		"No sprite size supplied")

	player:setSpriteData(sprites, parameters.sprites.spriteSizeX, parameters.sprites.spriteSizeY)

	assert(parameters.states and type(parameters.states) == "table" and next(parameters.states) ~= nil,
		 "\'states\' parameter must not be empty.")

	------------------------------------
	-- States
	------------------------------------

	local states = parameters.states

	if parameters.includeBasicStates then

		assert(states.stand and states.walk and states.jump and states.fall
				and states.stand.dynamics and states.walk.dynamics and states.jump.dynamics and states.fall.dynamics
				and states.stand.animation and states.walk.animation and states.jump.animation and states.fall.animation,
				"All four basic state dynamics and animations must be specified for basic state inclusion")

		local statesData = {stand = {}, walk = {}, jump = {}, fall = {}}

		for _, state in ipairs({"stand", "walk", "jump", "fall"}) do
			assert(states[state].animation and states[state].animation.mode and states[state].animation.frames 
				and states[state].animation.defaultDelay, "Missing arguments in animation data")
			
			statesData[state].animationData = {
				states[state].animation.mode, 
				player.spritesGrid(states[state].animation.frames),
				states[state].animation.defaultDelay,
				states[state].animation.delays or {},
				states[state].animation.flippedH or false,
				states[state].animation.flippedV or false
			}

			assert(love.filesystem.isFile(folder .. "/" .. states[state].dynamics), "Dynamics file \'".. folder .. "/" .. states[state].dynamics .. "\'does not exist")

			statesData[state].dynamics = love.filesystem.load(folder .. "/" .. states[state].dynamics)()

		end

		player:addBasicStates(statesData.stand, statesData.walk, statesData.jump, statesData.fall)
	end

	------------------------------------
	-- Creating the States
	------------------------------------
	for stateName, stateParams in pairs(states) do
		
		assert(stateParams.dynamics, "Missing dynamics data for state \'".. stateName .."\'.")
		assert(stateParams.animation and stateParams.animation.mode and stateParams.animation.frames 
				and stateParams.animation.defaultDelay, "Missing animation data for state \'" .. stateName .. "\'.")

		local isBaseState = stateName == "stand" or stateName == "walk" or stateName == "jump" or stateName == "fall"

		if stateParams.class or (not isBaseState)  then --non basic state or overriden basic state

			local animation = anim8.newAnimation( stateParams.animation.mode, 
													player.spritesGrid(stateParams.animation.frames),
													stateParams.animation.defaultDelay,
													stateParams.animation.delays or {},
													stateParams.animation.flippedH or false,
													stateParams.animation.flippedV or false )


			local CustomState, newState

			if stateParams.class then
				local ok, classFile = pcall(love.filesystem.load, folder ..  '/' .. stateParams.class)
				assert(ok, "Character state class file has syntax errors: " .. tostring(classFile))
				CustomState = classFile()
			else
				CustomState = PlayerState
			end

			local ok, dynamicsFile = pcall(love.filesystem.load, folder .. "/" .. stateParams.dynamics)
			
			assert(ok, "Character dynamics file has syntax errors: " .. tostring(dynamicsFile))

			local dynamics = dynamicsFile()

			newState = CustomState(stateName, dynamics, animation)

			player:addState(newState)

			print(newState.name)
			print(newState.addTransition)

		end
	end


	------------------------------------
	-- Transitions
	------------------------------------



	for stateName, stateParams in pairs(states) do
		
		if stateParams.transitions then
			for _, transition in ipairs(stateParams.transitions) do

				assert(transition.condition, "Transition condition not specified for state \'".. stateName .."\'")
				assert(transition.targetState, "Transition target not specified for state \'".. stateName .."\'")
				
				player.states[stateName]:addTransition(transition.condition, transition.targetState)
			end
		end
	end


	assert(parameters.initialState and type(parameters.initialState) == "string" and parameters.states[parameters.initialState],
		"Must specify a valid initial state")

	player:setInitialState(parameters.initialState)

	-- Build all other states and replace those that should not be there...
	--Build transitions

	
	if parameters.postBuild then
		parameters.postBuild(player)
	end

	return player
   
end

return Player