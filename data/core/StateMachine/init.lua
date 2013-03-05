local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local StateMachine = Class {
	name = "StateMachine",

	init = 
		function(self)		
			self.states = {}
			self.currentState = nil
		end

}

function StateMachine:update(dt)
	self.currentState:update(dt)
end

function StateMachine:checkStateChange()
	local currentState = self.currentState
	for _ , transition in ipairs(currentState.transitions) do
		if transition.condition(currentState) then
			self:changeToState(self.states[transition.targetState])
			return
		end
	end
end

function StateMachine:changeToState(nextState)
	print("From " .. self.currentState.name .. " to " .. nextState.name)
	if self.currentState.onExitTo then
		self.currentState:onExitTo(nextState)
	end

	if nextState.onEnterFrom then
		nextState:onEnterFrom(self.currentState)
	end

	self.currentState = nextState
end

function StateMachine:addState(state)
	self.states[state.name] = state
	state.owner = self	
end

function StateMachine:removeState(stateName)
	self.states[stateName] = nil
end

function StateMachine:setInitialState(stateName)
	assert(self.states[stateName], "No state with name \'".. stateName .."\'")
	self.initialState = self.states[stateName]
end

function StateMachine:start(position)
	self.currentState = self.initialState
end

return StateMachine