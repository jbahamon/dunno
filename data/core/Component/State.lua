--- State machine's state implementation
-- @class module
-- @name data.core.StateMachine.State

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

--- Builds a new State.
-- @class function
-- @name State
-- @param name The state's name.
-- @return The newly created State.

local State = Class {
	name = "State"
}

function State:init(name)
	self.name = name
	self.flags = {}
	self.transitions = {}
end

---A StateMachine's state implementation.
-- It is the base for all other states.
-- @type State

--- Adds a transition to the state.
-- position indicates the priority of the transition with respect to the others.
-- (1 meaning the new transition will be checked before all those added before)
function State:addTransition(condition, targetState, position)

	position = position or -1

	local transition = {condition = condition, targetState = targetState}

	if not position or position < 0 then
		table.insert(self.transitions, transition)
	else
		table.insert(self.transitions, position, transition)
	end
end

--- Sets a state's flag as on.
-- @param flag The name of the flag to turn on.
function State:addFlag(flag)
	self.flags[flag] = true
end

--- Sets a state's flag as off.
-- @param flag The name of the flag to turn off.
function State:removeFlag(flag)
	self.flags[flag] = nil
end

--- Retrieves a state's flags.
-- @return The state's flags. as a table 
-- @usage local foo = state:getFlags()
--assert(foo["someStateFlag"], "The 'someStateFlag' flag is not set")
function State:getFlags()
	return self.flags
end

--- Sets all of a state's flag to off.
function State:clearFlags(flag)
	self.flags = {}
end

return State