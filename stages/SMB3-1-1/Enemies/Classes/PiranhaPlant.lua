local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local GameObject = require 'data.core.GameObject'

local PiranhaPlant = Class {

	name = "PiranhaPlant",
	__includes = GameObject
}

function PiranhaPlant:update(dt)
	self.pipeAnimation.animation:update(dt)
end

function PiranhaPlant:start()
	local position = self.transform.position
	self.collision:disableTileCollisions()
	self.pipePosition = vector(math.ceil(position.x), math.ceil(position.y))
	self.collision:disableTileCollisions()
	self.pipeAnimation = self.helperAnimations["Pipe"]
end

function PiranhaPlant:draw()
	GameObject.draw(self)
	self.pipeAnimation.animation:draw(self.pipeAnimation.sprites,
	                    self.pipePosition.x - self.pipeAnimation.spriteSize.x/2,
                       	self.pipePosition.y - self.pipeAnimation.spriteSize.y, 0, 1, 1)
end


return PiranhaPlant