--- A game PhysicsComponent implementation.
-- @class module
-- @name data.core.PhysicsComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'

local Component = require 'data.core.Component'

--- Builds a new PhysicsComponent with a collision box and no states.
-- @class function
-- @name PhysicsComponent
-- @param defaultSize The size of the PhysicsComponent's default collision box, as a vector, in pixels.
-- @return The newly created PhysicsComponent.

local PhysicsComponent = Class {
    name = 'PhysicsComponent',
    __includes = Component
}

function PhysicsComponent:init(parameters)
    Component.init(self)
    self.stateTime = 0
    self.velocity = vector(0, 0)

    if parameters then
        self:addParameters(parameters)
    end
    self.externalForces = {}
end    

-----------------------------------------------------------------
--- Building and destroying
-- @section building

--- Adds this component to a GameObject. This method registers
-- the turn, update and changeToState methods with the container
-- GameObject.
-- @param container The GameObject this component is being added to.
function PhysicsComponent:addTo(container)
    Component.addTo(self, container)
    container:register("changeToState", self)
    container:register("update", self)
    container:register("turn", self)
    container.physics = self
end


function PhysicsComponent:addParameters(parameters) 
    for k, v in pairs(parameters) do
        self.parameters[k] = v
    end
end

-----------------------------------------------------------------
-- State handling
-- @section state

--- Executes a transition to a specified state.
-- The current state's onExitTo and the target state's onEnterFrom
-- are executed, if found. The PhysicsComponent's collision box is adjusted if the next
-- state has a different box from the current one.
-- @param nextState The target state.
function PhysicsComponent:changeToState(nextState)
    self.stateTime = 0
    if nextState.dynamics then
        self.parameters = nextState.dynamics
    end
end

--- Updates the component, applying the current acceleration to the container object.
-- @param dt The time interval to apply to the Component.
function PhysicsComponent:update(dt)
    local acceleration  = self.parameters.defaultAcceleration:permul(vector(self.container.transform.facing, 1)) 
                            + self.parameters.gravity
                            + self:getAdditionalForces()
    local displacement

    self.stateTime = self.stateTime + dt

    displacement = self.velocity * (dt / 2.0)
    
    self.velocity = self.velocity + acceleration * dt

    self.velocity.x =  math.min(self.velocity.x, self.parameters.maxVelocity.x)
    self.velocity.y =  math.min(self.velocity.y, self.parameters.maxVelocity.y)
    
    self.velocity.x =  math.max(self.velocity.x, -self.parameters.maxVelocity.x)
    self.velocity.y =  math.max(self.velocity.y, -self.parameters.maxVelocity.y)

    self:applyFriction(dt, self.parameters.friction)

    if self.container.control then
        if not (self.container.control["left"] or self.container.control["right"]) then
            self:applyFriction(dt, vector(self.parameters.noInputFriction.x, 0))
        end

        if not (self.container.control["up"] or self.container.control["down"]) then
            self:applyFriction(dt, vector(0, self.parameters.noInputFriction.y))
        end
    end

    displacement = displacement + self.velocity * (dt / 2.0)

    self.container:move(displacement)

    for id, force in pairs(self.externalForces) do
       if force.duration >= 0 then
            force.duration = force.duration - dt
            if force.duration < 0 then 
                self.externalForces[id] = nil
            end
        end
    end

end

-----------------------------------------------------------------
--- Dynamics
-- @section dynamics

function PhysicsComponent:turn() 
    --self.velocity.x = - self.velocity.x
end

function PhysicsComponent:addForce(identifier, forceValue, duration)
    duration = duration or -1
    self.externalForces[identifier] = { duration = duration, value = forceValue }
end

--- Applies the provided friction force to the Component.
-- A friction force is always dissipative: it will never cause 
-- the Component to reverse its velocity.
-- @param dt The current frame's time slice, in seconds
-- @param frictionForce The friction to apply, as a vector, in acceleration units (pixels/seconds^2)
-- This means that every Component has the same mass, for the time being.
function PhysicsComponent:applyFriction(dt, frictionForce)
    local friction = frictionForce * dt

    if friction.x > math.abs(self.velocity.x) then
        self.velocity.x = 0 
    elseif self.velocity.x > 0 then
        self.velocity.x = self.velocity.x - friction.x
    elseif self.velocity.x < 0 then
        self.velocity.x = self.velocity.x + friction.x
    end
  
    if friction.y > math.abs(self.velocity.y) then
        self.velocity.y = 0
    elseif self.velocity.y > 0 then
        self.velocity.y = self.velocity.y - friction.y
    elseif self.velocity.y < 0 then
        self.velocity.y = self.velocity.y + friction.y
    end

end

function PhysicsComponent:getAdditionalForces()
    local externalForce = vector(0,0)


    for id, force in pairs(self.externalForces) do
        externalForce = externalForce + force.value
    end

    return externalForce
end

return PhysicsComponent