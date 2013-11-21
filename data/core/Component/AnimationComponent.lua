--- A game AnimationComponent implementation.
-- @class module
-- @name data.core.AnimationComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'

local Component = require 'data.core.Component'

--- Builds a new AnimationComponent with a collision box and no states.
-- @class function
-- @name AnimationComponent
-- @param defaultSize The size of the AnimationComponent's default collision box, as a vector, in pixels.
-- @return The newly created AnimationComponent.

local AnimationComponent = Class {
    name = 'AnimationComponent',
    __includes = Component
}

function AnimationComponent:init(spritesPath, spriteSize, spriteOffset)
    Component.init(self)

    local sprites = string.gsub(spritesPath, '[^%a%d-_/.]', '')

    assert(love.filesystem.isFile(sprites), "Spritesheet \'".. spritesPath .."\' supplied is not a file")   

    self:setSpriteData(sprites, spriteSize, spriteOffset)

    self.drawTimer = 0
    self.animations = {}
end    

-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Adds this component to a GameObject. This method registers
-- the update and changeToState methods with the container
-- GameObject.
-- @param container The GameObject this component is being added to.
function AnimationComponent:addTo(container)
    Component.addTo(self, container)
    container:register("changeToState", self)
    container:register("update", self)
    container:register("draw", self)
    container.animation = self
end


-----------------------------------------------------------------
-- Drawing and animation data
-- @section drawing

--- Draws the AnimationComponent's current box. If globals.DEBUG is set to <i>true</i>, 
-- The collision box is drawn over the AnimationComponent's sprite.
function AnimationComponent:draw()    
    self.currentAnimation.flippedH = self.container.transform.facing < 0
    self.currentAnimation:draw(self.sprites,
                self.container.transform.position.x - self.spriteSize.x/2 + self.spriteOffset.x,
                self.container.transform.position.y - self.spriteSize.y + self.spriteOffset.y,
                0, 1, 1)

end

--- Sets the Element's sprite data for it to be drawn.
-- @param sprites The sprite sheet image, as loaded by love.graphics.newImage.
-- Sprites in the sheet must be arranged in a grid where every cell must have the same size.
-- @param spriteSize The size of a sprite's cell in the sheet, as a hump vector, in pixels.
-- @param offset The sprites' offset, as a vector, in pixels. 
function AnimationComponent:setSpriteData(spritePath, spriteSize, offset)
    self.spriteSize = spriteSize:clone()
    self.sprites = love.graphics.newImage(spritePath)
    self.sprites:setFilter('nearest', 'nearest')
    self.spritesGrid = anim8.newGrid(self.spriteSize.x,
                                         self.spriteSize.y,
                                         self.sprites:getWidth(),
                                         self.sprites:getHeight())

    if offset then
        self.spriteOffset = offset:clone()
    else
        self.spriteOffset = vector(0,0)
    end
end

--- Adds an animation to the component.
-- @param name The name of the new animation. If the component already
-- had an animation with this name, it is overwritten.
-- @param params A table of animation parameters. Mandatory entries in 
-- this table are "mode" (animation mode, which can be "loop", "once" 
-- or "bounce"); frames, which must be an array of frame coordinates as 
-- strings; and defaultDelay, the default time for each animation frame.
-- Optional entries are delays, an array of numbers representing each frame's
-- duration; flippedH and flippedV, the animation's horizontal and vertical,
-- flipping respectively.
function AnimationComponent:addAnimation(name, params)
    assert(params.mode, "Parameters for animation \"" .. name .. "\" must specify mode")
    assert(params.frames, "Parameters for animation \"" .. name .. "\" must specify frames")
    assert(params.defaultDelay, "Parameters for animation \"" .. name .. "\" must specify defaultDelay")

    local frames = (type(params.frames) == "table") and self.spritesGrid(unpack(params.frames))
                  or self.spritesGrid(params.frames)

    local animation = anim8.newAnimation( params.mode, 
                                        frames,
                                        params.defaultDelay,
                                        params.delays or {},
                                        params.flippedH or false,
                                        params.flippedV or false )

    self.animations[name] = animation
end

--- Sets the component's current animation.
-- @param name The name of the animation to set. If no animation with such 
-- name exists, an error is raised. The animation is restarted unless a
-- true noReset parameter is supplied.
function AnimationComponent:setAnimation(name, noReset)
    assert(self.animations[name], "No animation named \"" .. name .."\" found.")
    self.currentAnimation = self.animations[name]
    if not noReset then
        self.currentAnimation:gotoFrame(1)
        self.currentAnimation:resume()
    end
end


-----------------------------------------------------------------
-- State handling
-- @section state

--- Executes a transition to a specified state.
-- The current state's onExitTo and the target state's onEnterFrom
-- are executed, if found. The AnimationComponent's collision box is adjusted if the next
-- state has a different box from the current one.
-- @param nextState The target state.
function AnimationComponent:changeToState(nextState)
    if nextState.animation and nextState.animation ~= self.currentAnimation then
        self:setAnimation(nextState.animation)
    end
end

--- Updates the Component.
-- @param dt The time interval to apply to the Component.
function AnimationComponent:update(dt)
    -- Animation
    self.currentAnimation:update(dt)
end

function AnimationComponent:pause()
    self.currentAnimation:pause()
end

function AnimationComponent:resume()
    self.currentAnimation:resume()
end

return AnimationComponent