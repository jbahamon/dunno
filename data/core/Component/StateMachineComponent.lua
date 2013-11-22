--- A game StateMachineComponent implementation.
-- @class module
-- @name data.core.StateMachineComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local Component = require 'data.core.Component'
local State = require 'data.core.Component.State'
local GeometryUtils = require 'lib.GeometryUtils'
local shapes = require 'lib.HardonCollider.shapes'


--- Builds a new StateMachineComponent with no states.
-- @class function
-- @name StateMachineComponent
-- @param defaultSize The size of the StateMachineComponent's default collision box, as a vector, in pixels.
-- @return The newly created StateMachineComponent.

local StateMachineComponent = Class {
    name = 'StateMachineComponent'
}

StateMachineComponent.defaultFlags = {}

function StateMachineComponent:init()
    Component.init(self)
    self.states = {}
    self.currentState = nil
end    
-----------------------------------------------------------------
--- Building and destroying
-- @section building

-- Adds a state to the StateMachine. 
-- A state can only belong to a single StateMachine at a time: it should not belong 
-- to another StateMachine when this method is called. 
-- Call @{StateMachine:removeState} on the other StateMachine first.
-- @param state The state to be added.
function StateMachineComponent:addState(state)
    self.states[state.name] = state
    state.owner = self.container
end

--- Adds this component to a GameObject. This method registers
-- the move, moveTo, start, draw, changeToState and destroySelf methods
-- with the container GameObject.
-- @param container The GameObject this component is being added to.
function StateMachineComponent:addTo(container)
    Component.addTo(self, container)
    container:register("start", self)
    container:register("update", self)
    container:register("lateUpdate", self)
    container.stateMachine = self

    for k, v in pairs(self.states) do
        v.owner = container
    end
end

--- Removes a state from the StateMachine, leaving it with no owner.
-- @param stateName The name of the state to be removed. If there is no state with such name in the StateMachine, nothing is done.
function StateMachineComponent:removeState(stateName)
    self.states[stateName] = nil
end

function StateMachineComponent:start()
    self:changeToState(self.states[self.initialState])

end

--- Checks for conditions and executes any possible state change.
-- If two or more transitions are possible, the one with higher priority
-- is taken (or the one that was added first, if there is more than one transition with the
-- same priority). State transition conditions take a single argument: the current
-- state.
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
-- @param nextState The target state.
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

function StateMachineComponent:getStateFlags()
    return self.currentState.flags
end



function StateMachineComponent:update(dt)
    if self.currentState.update then
        self.currentState:update(dt)
    end
end

return StateMachineComponent

