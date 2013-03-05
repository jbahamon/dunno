local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local ElementStateMachine = Class {
	name = "ElementStateMachine",

	function(self, spriteSheet, controllable, element)
		self.element = element
		self.states = {}
		self.controllable = controllable
		if self.controllable then
			self.binds, self.control = love.filesystem.load("lib/TLbind.lua")()
			self.binds.keys = {
			    w="up", a="left", s="down", d="right", [" "]="jump", lctrl="attack", escape="menu",
			    up="up", left="left", down="down", right="right", z="jump", rctrl="attack", x="attack"
			}
		end
	end

}

function ElementStateMachine:update(dt)
	if self.controllable then
		self.binds:update()
	end

	self.currentState:update(dt)
	return self.currentState.displacement
end

function ElementStateMachine:draw()
	self.currentState:draw()
end

function ElementStateMachine:move(displacement)
	self.currentState:move(displacement)
end

function ElementStateMachine:changeToState(stateB)
	--print("From " .. self.currentState.name .. " to ".. stateB.name)
	if self.currentState.onExitTo then
		self.currentState:onExitTo(stateB, self.element)
	end

	stateB:enterFrom(self.currentState, self.element)

	self.currentState = stateB

	if self.controllable then
		self.currentState.controls = self.control
	end
end

function ElementStateMachine:addState(state)
	if self.states[state.name] and self.states[state.name].collisionBox then
		if self.element.activeCollider then
			self.element.activeCollider:remove(state)
		end

		self.element.tileCollider:remove(state)
	end

	self.states[state.name] = state

	if state.collisionBox then
		if self.element.activeCollider then
			self.element.activeCollider:addShape(state.collisionBox)
			self.element.activeCollider:setGhost(state.collisionBox)
		end
		self.element.tileCollider:addElement(state.collisionBox)
	end
end

function ElementStateMachine:setInitialState(stateName)
	self.initialState = self.states[stateName]
end

function ElementStateMachine:start(position)
	self.initialState.dynamics.velocity = vector(0,0)
	self.initialState.dynamics.position = position

	self.currentState = self.initialState

	local collisionBox = self.initialState.collisionBox or
							self.element:getDefaultCollisionBox()
	self.element:setCollisionBox(collisionBox)
	
	if self.controllable then
		self.currentState.controls = self.control
	end
end

function ElementStateMachine:checkStateChange(collisionFlags)
	local currentState = self.currentState
	for pos, transition in ipairs(currentState.transitions) do
		if transition.condition(currentState, collisionFlags) then
			self:changeToState(self.states[transition.targetState])
			return
		end
	end
end

return ElementStateMachine