--- A StateMachineComponent's basic State.
-- @classmod data.core.Component.State
local Class = require 'lib.hump.class'

local State = Class {
	name = "State"
}


--- Builds a new State with no flags nor transitions.
-- @class function
-- @name State.__call
-- @tparam string name The state's name.
-- @treturn State The newly created State.

function State:init(name)
	self.name = name
	self.flags = {}
	self.transitions = {}
end

--- Adds a transition to the state.
-- @tparam function condition The condition function that shall be evaluated to 
-- determine if the transition should be performed.
-- @tparam string targetState The name of the state the transition will lead to.
-- @tparam[opt=1] number position The priority of the transition with respect to the others.
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
-- @tparam string flag The name of the flag to turn on.
function State:addFlag(flag)
	self.flags[flag] = true
end

--- Sets a state's flag as off.
-- @tparam string flag The name of the flag to turn off.
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

--- Sets every flag of this state as off.
function State:clearFlags()
	self.flags = {}
end

return State