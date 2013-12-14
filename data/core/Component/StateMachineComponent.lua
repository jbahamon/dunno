--- A Component that represents an element's behavior as a state machine.
-- @classmod data.core.Component.StateMachineComponent

local Class = require 'lib.hump.class'
local BaseComponent = require 'data.core.Component.BaseComponent'

local StateMachineComponent = Class {
    name = 'StateMachineComponent',
    __includes = BaseComponent
}

StateMachineComponent.defaultFlags = {}

-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Builds a new StateMachineComponent with no states.
-- @class function
-- @name StateMachineComponent.__call
-- @treturn StateMachineComponent The newly created StateMachineComponent.
function StateMachineComponent:init()
    BaseComponent.init(self)
    self.states = {}
    self.currentState = nil
end    

-- Adds a state to the StateMachineComponent. 
-- A state can only belong to a single StateMachineComponent at a time: it should not belong 
-- to another StateMachineComponent when this method is called. 
-- Call @{StateMachine:removeState} on the other StateMachineComponent first.
-- @tparam State state The state to be added.
function StateMachineComponent:addState(state)
    self.states[state.name] = state
    state.owner = self.container
end

--- Adds this component to a GameObject. This method registers
-- the start, update and lateUpdate methods with the container GameObject.
-- These methods will also be called on the current state, if they exist.
-- The StateMachineComponent will be added as the stateMachine field of
-- the GameObject.
-- @tparam GameObject container The GameObject this component is being added to.
function StateMachineComponent:addTo(container)
    BaseComponent.addTo(self, container)
    container:register("start", self)
    container:register("update", self)
    container:register("lateUpdate", self)
    container.stateMachine = self

    for k, v in pairs(self.states) do
        v.owner = container
    end
end

--- Removes a state from the StateMachine, leaving it with no owner.
-- @tparam string stateName The name of the state to be removed. If there is no state with such name in the StateMachine, nothing is done.
function StateMachineComponent:removeState(stateName)
    self.states[stateName] = nil
end

--- Starts the state machine, changing to the initial state. If the initial state
-- has a start method, it will be called.
function StateMachineComponent:start()
    self:changeToState(self.states[self.initialState])
    if self.initialState.start then
        self.initialState:start()
    end
end

--- Executes the current state's lateUpdate method, if present. Additionally, 
-- checks for conditions and executes any possible state change.
-- If two or more transitions are possible, the one with higher priority
-- is taken (or the one that was added first, if there is more than one transition with the
-- same priority). State transition conditions take a single argument: the current
-- state.
-- @tparam number dt The elapsed time since the last lateUpdate call, in seconds.
function StateMachineComponent:lateUpdate(dt)

    local currentState = self.currentState

    if currentState.lateUpdate then
        currentState:lateUpdate(dt)
    end
    
    for _ , transition in ipairs(currentState.transitions) do

        local collisionFlags = (self.container.collision and self.container.collision.collisionFlags) or StateMachineComponent.defaultFlags
        if transition.condition(currentState, collisionFlags) then
            self:changeToState(self.states[transition.targetState])
            return
        end
    end
end


--- Executes a transition to a specified state.
-- The current state's onExitTo and the target state's onEnterFrom
-- are executed, if found.
-- @tparam State nextState The target state.
function StateMachineComponent:changeToState(nextState)
    
    if self.currentState and self.currentState.onExitTo then
        self.currentState:onExitTo(nextState)
    end

    if nextState.onEnterFrom then
        nextState:onEnterFrom(self.currentState)
    end

    self.currentState = nextState
    self.container:changeToState(nextState)
end

--- Returns the current state's flags.
-- @treturn table The flags, as an array of flags that can be true or false.
function StateMachineComponent:getStateFlags()
    return self.currentState.flags
end


--- Executes the current state's update method, if present. 
-- @tparam number dt The elapsed time since the last update, in seconds.
function StateMachineComponent:update(dt)
    if self.currentState.update then
        self.currentState:update(dt)
    end
end

return StateMachineComponent

