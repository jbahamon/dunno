local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local Element = require 'data.core.Element'

local PiranhaPlant = Class {

	name = "PiranhaPlant",
	__includes = Element,

	init =
		function(self, size)
			Element.init(self, size)
		end
}

function PiranhaPlant:update(dt)
	Element.update(self, dt)
	self.pipeAnimation.animation:update(dt)
end

function PiranhaPlant:start()
	Element.start(self)
	local position = self:getPosition()
	self.pipePosition = vector(math.ceil(position.x), math.ceil(position.y))
	self:disableTileCollisions()
	self.pipeAnimation = self.helperAnimations["Pipe"]
end

function PiranhaPlant:draw()
	Element.draw(self)
	self.pipeAnimation.animation:draw(self.pipeAnimation.sprites,
	                    self.pipePosition.x - self.pipeAnimation.spriteSize.x/2,
                       	self.pipePosition.y - self.pipeAnimation.spriteSize.y, 0, 1, 1)
end


return PiranhaPlant