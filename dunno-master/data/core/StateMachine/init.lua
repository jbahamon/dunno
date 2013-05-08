--- State machine implementation.
-- @class module
-- @name data.core.StateMachine

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local State = require 'data.core.StateMachine.State'

--- Builds a new StateMachine with no states.
-- @class function
-- @name StateMachine
-- @return The newly created StateMachine.
local StateMachine = Class {
	name = "StateMachine",

	init = 
		function(self)		
			self.states = {}
			self.currentState = nil
		end

}

--- A state machine implementation.
-- It is the base for all elements (player, enemy and neutral) in the game.
-- Can also be used for non-element behavior.
-- @type StateMachine

--- Retrieves the current state's flags.
-- @return The current state's flag table.
-- @usage local foo = machine:getStateFlags()
--assert(foo["someStateFlag"], "The state flag is not set")
function StateMachine:getStateFlags()
	return self.currentState:getFlags()
end

--- Updates the StateMachine. Should be called on each frame where the StateMachine is active.
-- @param dt Time since the last update, in seconds.
function StateMachine:update(dt)
	self.currentState:update(dt)
end

--- Checks for conditions and executes any possible state change.
-- If two or more transitions are possible, the one with higher priority
-- is taken (or the one that was added first, if there is more than one transition with the
-- same priority). State transition conditions take a single argument: the current
-- state.
function StateMachine:checkStateChange()
	local currentState = self.currentState
	for _ , transition in ipairs(currentState.transitions) do
		if transition.condition(currentState) then
			self:changeToState(self.states[transition.targetState])
			return
		end
	end
end

--- Executes a transition to a specified state.
-- The current state's onExitTo and the target state's onEnterFrom
-- are executed, if found.
-- @param nextState The target state.
function StateMachine:changeToState(nextState)

	--print("from " .. self.currentState.name .. " to " .. nextState.name)
	if self.currentState.onExitTo then
		self.currentState:onExitTo(nextState)
	end

	if nextState.onEnterFrom then
		nextState:onEnterFrom(self.currentState)
	end

	self.currentState = nextState
end

--- Adds a state to the StateMachine. 
-- A state can only belong to a single StateMachine at a time: it should not belong 
-- to another StateMachine when this method is called. 
-- Call @{StateMachine:removeState} on the other StateMachine first.
-- @param state The state to be added.
function StateMachine:addState(state)
	self.states[state.name] = state
	state.owner = self	
end

--- Removes a state from the StateMachine, leaving it with no owner.
-- @param stateName The name of the state to be removed. If there is no state with such name in the StateMachine, nothing is done.
function StateMachine:removeState(stateName)
	if self.states[stateName] then
		self.states[stateName].owner = nil
	end

	self.states[stateName] = nil
end

--- Sets the StateMachine's initial State
-- @param stateName The name of the state to be set as the StateMachine's initial state.
-- There must be a state with this name in the StateMachine, or an error will be raised.
function StateMachine:setInitialState(stateName)
	assert(self.states[stateName], "No state with name \'".. stateName .."\'")
	self.initialState = self.states[stateName]
end

--- Returns the StateMachine's initial state
-- @return The StateMachine's initial state.
function StateMachine:getInitialState()
	return self.initialState
end

--- Returns the StateMachine's default state class (a <a href="http://vrld.github.com/hump/#hump.class"> hump class</a>).
-- This method is used when building a StateMachine from a file, to determine the class used when no state class is specified.
-- For a StateMachine, it's State; override this method if you want to create a StateMachine with a custom base state.
-- @return The hump class to be used in the construction of this StateMachine's states when no class is specified.
function StateMachine:getDefaultStateClass()
	return State
end

function StateMachine:start(position)
	self.currentState = self.initialState
end

function StateMachine:destroySelf()
	for stateName, state in pairs(self.states) do
		state:destroySelf()
	end

	self.states = {}
end


return StateMachine