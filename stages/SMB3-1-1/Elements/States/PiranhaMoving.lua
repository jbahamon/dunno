local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local ElementState = require 'data.core.Element.ElementState'

local PiranhaPlant = Class {
	name = "PiranhaPlant",
	__includes = Element,

	init =
		function(self, size)
			Element.init(self, size)
		end
}

function PiranhaPlant:start()
	Element.start(self)
	self:disableTileCollisions()
end

return PiranhaPlant