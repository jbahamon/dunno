-- @name data.core.GameObject

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local StateMachineComponent = require 'data.core.Component.StateMachineComponent'



--- Builds a new GameObject with a collision box and no states.
-- @class function
-- @name GameObject
-- @param size The size of the GameObject's collision box, as a vector, in pixels.
-- @return The newly created GameObject.

local InnerGameObject = Class {
	name = 'InnerGameObject'
}

function InnerGameObject:init()
	self.components = {}
	self.events = {}
end	

local GameObject = {}

function GameObject:addComponent(newComponent)
	table.insert(self._inner.components, newComponent)
	newComponent:addTo(self)
end

function GameObject:register(event, component)
	if not self._inner.events[event] then
		self._inner.events[event] = {}
	end

	table.insert(self._inner.events[event], component)
end


function GameObject:destroySelf()
	
end

function GameObject:setEventHandler(event, handler)
	self[event] = function(self, ...)
		handler(self, ...)
		if self._inner.events[event] then
			for k, component in ipairs(self._inner.events[event]) do
				component[event](component, ...)
			end
		end
	end
end

--- Builds a GameObject
-- @class function
-- @name GameObject
-- @return The newly created GameObject

function GameObject.new()
	return setmetatable(
		{	_inner = InnerGameObject(),
			addComponent = GameObject.addComponent,
			register = GameObject.register,
			setEventHandler = GameObject.setEventHandler,
			destroySelf = GameObject.destroySelf },
		{	__index = function (t, key)
				if t._inner.events[key] then
					return function(self, ...)
						for k, component in ipairs(self._inner.events[key]) do
							component[key](component, ...)
						end
						return self._inner[key]
					end
				else
					return t._inner[key]
				end
			end
		})
end

return GameObject
