--- A Component that represents an element's physics.
-- @classmod data.core.Component.PhysicsComponent

local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local anim8 = require 'lib.anim8'

local BaseComponent = require 'data.core.Component.BaseComponent'

local PhysicsComponent = Class {
    name = 'PhysicsComponent',
    __includes = BaseComponent
}

-----------------------------------------------------------------
--- Building and destroying
-- @section building


--- Builds a new PhysicsComponent with a set of (optional) default parameters.
-- @class function
-- @name PhysicsComponent.__call
-- @tparam[opt] table parameters The default physics parameters for this Component.
-- @treturn PhysicsComponent The newly created PhysicsComponent.

function PhysicsComponent:init(parameters)
    BaseComponent.init(self)
    self.stateTime = 0
    self.velocity = vector(0, 0)

    if parameters then
        self:setParameters(parameters)
    end
    self.externalForces = {}
end    

--- Adds this component to a GameObject. This method registers
-- the update and changeToState methods with the container
-- GameObject. The PhysicsComponent will be added as the physics field of
-- the GameObject.
-- @tparam GameObject container The GameObject this component is being added to.
function PhysicsComponent:addTo(container)
    BaseComponent.addTo(self, container)
    container:register("changeToState", self)
    container:register("update", self)
    container.physics = self
end

--- Sets the dynamic parameters for this Component.
-- @tparam table parameters The dynamics parameters to set. 
function PhysicsComponent:setParameters(parameters) 
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
-- @tparam State nextState The target state.
function PhysicsComponent:changeToState(nextState)
    self.stateTime = 0
    if nextState.dynamics then
        self.parameters = nextState.dynamics
    end
end

--- Updates the component, applying the current acceleration to the container object.
-- @tparam number dt The time interval to apply to the Component.
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

--- Adds an external force under a name and duration to this component.
-- @tparam string identifier The force's name. If two different forces are added 
-- under the same identifier, the second will replace the first.
-- @tparam vector forceValue The external force in acceleration units (pixels/seconds^2)
-- @tparam[opt=-1] number duration How long, in seconds, the force will last.
-- A negative value represents a force that will last until it 
-- is explicitly removed by replacement.
function PhysicsComponent:addForce(identifier, forceValue, duration)
    duration = duration or -1
    self.externalForces[identifier] = { duration = duration, value = forceValue }
end

--- Applies the provided friction force to the Component.
-- A friction force is always dissipative: it will never cause 
-- the Component to reverse its velocity.
-- @tparam number dt The current frame's time slice, in seconds
-- @tparam vector frictionForce The friction to apply in acceleration units (pixels/seconds^2)
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

--- Returns the total external force currently applied to this component.
-- @treturn vector The current external force in acceleration units (pixels/seconds^2).
function PhysicsComponent:getAdditionalForces()
    local externalForce = vector(0,0)


    for id, force in pairs(self.externalForces) do
        externalForce = externalForce + force.value
    end

    return externalForce
end

return PhysicsComponent