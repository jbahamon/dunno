--- The objects that represent anything in a stage. Players, enemies, powerups, 
-- stage artifacts... all of them should be GameObjects. GameObjects are classless
-- objects, so there is no class inheritance. Instead, you should manipulate the GameObject's
-- components. Also, do not dynamically add methods to a GameObject, as it may interfere with the
-- callback mechanism.
-- @classmod data.core.GameObject

local Class = require 'lib.hump.class'

local InnerGameObject = Class {
	name = 'InnerGameObject'
}

function InnerGameObject:init()
	self.components = {}
	self.events = {}
end	

local GameObject = {}

--- Adds a component to this GameObject. The component may add itself as one of the GameObject's
-- fields. Be sure to not add more than one component of each type, as one will only partially 
-- overwrite the other. Future releases might include the removal of components.
-- @tparam Component newComponent
function GameObject:addComponent(newComponent)
	table.insert(self._inner.components, newComponent)
	newComponent:addTo(self)
end

--- Registers a component to be called upon a specified event. The method <i>event</i> of <i>component</i>
-- will be called whenever the <i>event</i> method is called on this GameObject. 
-- @tparam string event The event name
-- @tparam Component component The component to register.
function GameObject:register(event, component)
	if not self._inner.events[event] then
		self._inner.events[event] = {}
	end

	table.insert(self._inner.events[event], component)
end

--- Sets a global handler for <i>event</i>. The handler will be called before the 
-- registered objects.
-- @tparam string event The event to register
-- @tparam function handler The global handler to set.
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

--- Creates and returns a new GameObject. Strings that cannot be registered as events are:
-- addComponent, register and setEventHandler.
-- @treturn GameObject The newly created GameObject.
function GameObject.new()
	return setmetatable(
		{	_inner = InnerGameObject(),
			addComponent = GameObject.addComponent,
			register = GameObject.register,
			setEventHandler = GameObject.setEventHandler,
		},
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