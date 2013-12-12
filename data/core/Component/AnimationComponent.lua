--- A Component that represents an element's sprites and animations.
-- @classmod data.core.Component.AnimationComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'

local BaseComponent = require 'data.core.Component.BaseComponent'

local AnimationComponent = Class {
    name = 'AnimationComponent',
    __includes = BaseComponent
}


-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Builds a new AnimationComponent.
-- @class function
-- @name AnimationComponent.__call
-- @tparam string|Image spriteData The component's sprites. Can be supplied as a file path (as a string) or 
--  as an already loaded (using love.graphics.newImage) sprite sheet.
-- @tparam vector spriteSize The sprite size for the animation in pixels.
-- @tparam[opt] vector spriteOffset The sprite offset for the animation in pixels. Default is no offset.
-- @tparam[opt] string folder The base folder to load the sprites from. Default value is the empty string.
-- @treturn AnimationComponent The newly created AnimationComponent.
function AnimationComponent:init(spriteData, spriteSize, spriteOffset, folder)
    BaseComponent.init(self)

    local sprites 

    if type(spriteData) == "string" then
        folder = folder and (folder .. "/") or ""
        sprites = folder .. string.gsub(spriteData, '[^%a%d-_/.]', '')
        assert(love.filesystem.isFile(sprites), "Spritesheet \'".. spriteData .."\' supplied is not a file")   
    else
        sprites = spriteData
    end

    self:setSpriteData(sprites, spriteSize, spriteOffset)

    self.drawTimer = 0
    self.animations = {}
end    

--- Adds this component to a GameObject. This method registers
-- the update, changeToState and draw methods with the container
-- GameObject. The AnimationComponent will be added as the animation field of
-- the GameObject.
-- @tparam @{data.core.GameObject} container The GameObject this component is being added to.
function AnimationComponent:addTo(container)
    BaseComponent.addTo(self, container)
    container:register("changeToState", self)
    container:register("update", self)
    container:register("draw", self)
    container.animation = self
end


-----------------------------------------------------------------
-- Drawing and animation data
-- @section drawing

--- Draws the AnimationComponent's current animation. The default positioning is such that the
--  animation's bottom-center overlaps the container GameObject's position.
function AnimationComponent:draw()    
    self.currentAnimation.flippedH = self.container.transform.facing < 0
    self.currentAnimation:draw(self.sprites,
                self.container.transform.position.x - self.spriteSize.x/2 + self.spriteOffset.x,
                self.container.transform.position.y - self.spriteSize.y + self.spriteOffset.y,
                0, 1, 1) 
end

--- Sets the AnimationComponent's sprite data for it to be drawn. This method is called when 
-- the Component is initialized, so you should only call it if you want to alter sprite data dynamically.
-- @tparam string|Image spriteData The component's sprites. Can be supplied as a file path (as a string) or 
--  as an already loaded (using love.graphics.newImage) sprite sheet.
-- @tparam vector spriteSize The sprite size for the animation in pixels.
-- @tparam[opt] vector spriteOffset The sprite offset for the animation in pixels. Default is no offset.
-- @tparam[opt] vector spriteOffset The sprite offset for the animation in pixels. Default is no offset.
function AnimationComponent:setSpriteData(spriteData, spriteSize, spriteOffset, spriteGrid)

    self.sprites = type(spriteData) == "string" and love.graphics.newImage(spriteData) or spriteData

    self.spriteSize = spriteSize:clone()
    self.sprites:setFilter('nearest', 'nearest')
    self.spritesGrid = anim8.newGrid(self.spriteSize.x,
                                         self.spriteSize.y,
                                         self.sprites:getWidth(),
                                         self.sprites:getHeight())

    self.spriteOffset = spriteOffset and spriteOffset:clone() or vector(0,0)
end

--- Adds an animation to the component.
-- @tparam string name The name of the new animation. If the component already
-- had an animation with this name, it will be overwritten.
-- @tparam table params A table of animation parameters. Mandatory entries in 
-- this table are "mode" (animation mode, which can be "loop", "once" 
-- or "bounce"); frames, which must be an array of frame coordinates as 
-- strings; and defaultDelay, the default time for each animation frame.
-- Optional entries are delays, an array of numbers representing each frame's
-- duration; flippedH and flippedV, the animation's horizontal and vertical
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
-- @tparam string name The name of the animation to set. If no animation with such 
-- name exists, an error is raised. 
-- @tparam[opt=false] bool noReset A flag to prevent restarting the animation if true.
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
-- The next state's animation is set as the current animation, if it differs from
-- the current one.
-- @tparam @{data.core.Component.State} nextState The target state.
function AnimationComponent:changeToState(nextState)
    if nextState.animation and nextState.animation ~= self.currentAnimation then
        self:setAnimation(nextState.animation)
    end
end

--- Updates the Component, advancing the animation.
-- @tparam number dt The time interval to apply to the Component.
function AnimationComponent:update(dt)
    -- Animation
    self.currentAnimation:update(dt)
end

--- Pauses the Component, preventing the animation from advancing.
function AnimationComponent:pause()
    self.currentAnimation:pause()
end

--- Resumes the Component, allowing the animation to advance.
function AnimationComponent:resume()
    self.currentAnimation:resume()
end

return AnimationComponent