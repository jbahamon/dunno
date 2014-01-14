
--- A module for loading and building game elements from user files.
-- @module data.core.Loader

local GameObject = require 'data.core.GameObject'
local State = require 'data.core.Component.State'
local BasicJump = require 'data.core.CommonStates.BasicJump'
local Climb = require 'data.core.CommonStates.Climb'
local Hit = require 'data.core.CommonStates.Hit'

local TransformComponent = require 'data.core.Component.TransformComponent'
local CollisionComponent = require 'data.core.Component.CollisionComponent'
local AnimationComponent = require 'data.core.Component.AnimationComponent'
local StateMachineComponent = require 'data.core.Component.StateMachineComponent'
local InputComponent = require 'data.core.Component.InputComponent'
local PhysicsComponent = require 'data.core.Component.PhysicsComponent'

local Stage = require 'data.core.Stage'

local vector = require 'lib.hump.vector'

local Loader = {}

--- Loads a Stage, given its folder path.
-- @tparam string name The Stage's folder's name.
-- @return Stage The newly created Stage
function Loader.loadStage(name)

    local folder = globals.stageFolder .. string.gsub(name, '[^%a%d-_/]', '')
    local parameters = Loader.loadFile("/config.lua", folder)

    assert(type(parameters) == "table", "Stage configuration file must return a table")

    local mapPath = folder .. "/" ..parameters.map
    local stage = Stage(mapPath, parameters)

    assert(parameters.startingPosition and vector.isvector(parameters.startingPosition), 
        "Missing parameter \'startingPosition\' or parameter is not a vector.")

    stage:setStartingPosition(parameters.startingPosition)

    if parameters.roomTransitionMode then
        assert(type(parameters.roomTransitionMode) == "string", "Room transition mode must be specified using a string")
        stage.roomTransitionMode = parameters.roomTransitionMode
    end

    if parameters.rooms then
        assert (type(parameters.rooms) == "table", "\'rooms\' parameter must be an array")
        for _, room in ipairs(parameters.rooms) do
            assert(room.topLeft and room.bottomRight and vector.isvector(room.topLeft) and vector.isvector(room.bottomRight), 
                "Room must specify top left and bottom right corners as vectors.")
            stage:addRoom(room)
        end
    end

    if parameters.defaultCameraMode then
        stage.defaultCameraMode = parameters.defaultCameraMode
    end

    if parameters.elementTypes then
        stage.elementTypes = parameters.elementTypes
    end

    stage:setFolder(folder)

    return stage
end

--- Loads a Player character, given its folder name. 
-- Transform, Input and Physics components are added to the GameObject. 
-- Animation, Collision and StateMachine components are added if sprites 
-- (and animations), size and states (or basicStates) fields are present 
-- in the character's parameters.
-- @tparam string name The Player character's folder's name.
-- @return GameObject The newly created Player character.
function Loader.loadCharacterFromName(name)
   
    local path = string.gsub(name, "[^%a%d-_/]", "") .. "/config.lua"    

    local parameters = Loader.loadFile(path, globals.characterFolder)

    parameters.name = parameters.name or name
    parameters.input = parameters.input or true
    parameters.elementType = parameters.elementType or "Player"

    local folder = globals.characterFolder .. string.gsub(name, "[^%a%d-_/]", "")
    local character = Loader.loadObjectFromParameters(parameters, folder)

    
    return character

end

function Loader.loadObjectFromParameters(parameters, folder)
    local object = GameObject.new()
    object.folder = folder
    object.name = parameters.name

    object.elementType = parameters.elementType or "Neutral"

    Loader.loadComponents(object, parameters)


    if parameters.postBuild then
        parameters.postBuild(object)
    end

    if parameters.onStart then
        object:setEventHandler("start", parameters.onStart)
    end

    return object
end

function Loader.loadComponents(object, parameters)
    
    object:addComponent(TransformComponent(object))

    if parameters.physics ~= false then
        Loader.loadPhysics(object)
    end 

    if parameters.input then
        Loader.loadInput(object)
    end

    if parameters.animation then
        Loader.loadAnimation(object, parameters.animation)
    end    

    if parameters.collision then
        Loader.loadCollision(object, parameters.collision)
    end    
    
    if parameters.stateMachine then
        Loader.loadStateMachine(object, parameters.stateMachine)     
    end

    if parameters.customComponents then
        for _, customComponent in ipairs(parameters.customComponents) do
            Loader.loadCustomComponent(object, customComponent.class, customComponent.parameters)
        end
    end

end

function Loader.loadPhysics(object)
    object:addComponent(PhysicsComponent())
end

function Loader.loadTransform(object)
    object:addComponent(TransformComponent())
end

function Loader.loadInput(object)
    local playerIndex = index or 1
    object:addComponent(InputComponent(globals.playerKeys[1]))
end

function Loader.loadAnimation(object, parameters)
    assert(parameters.sprites and 
           parameters.animations, "Both sprites and animations must be defined for animation component of object " .. object.name)

    assert(parameters.sprites.sheet and 
           parameters.sprites.spriteSize, "sheet and spriteSize must be defined for object " .. object.name)

    object:addComponent(AnimationComponent(parameters.sprites.sheet, 
                                            parameters.sprites.spriteSize, 
                                            parameters.sprites.spriteOffset, object.folder))

    for k, v in pairs(parameters.animations) do
        object.animation:addAnimation(k, v)
    end

    if parameters.initialAnimation then
        object.animation:setAnimation(parameters.initialAnimation)
    end
end

function Loader.loadStateMachine(object, parameters)
   assert(parameters.initialState and type(parameters.initialState) == "string", "Must specify a valid initial state")

    object:addComponent(StateMachineComponent())

    if parameters.basicStates then
        Loader.loadBasicStates(object, parameters.basicStates)
    end

    if parameters.states then
        Loader.loadStates(object, parameters.states)
    end

    if parameters.transitions then
        Loader.loadTransitions(object, parameters.transitions)
    end

    object.stateMachine.initialState = parameters.initialState
end

function Loader.loadCollision(object, parameters)
    object:addComponent(CollisionComponent(parameters.size))

    if parameters.getHitBy then
        object.collision.getHitBy = parameters.getHitBy
    end

    if parameters.onDynamicCollide then
        object.collision.onDynamicCollide = parameters.onDynamicCollide
    end

    if parameters.hitDef then
        object.collision:setHitDef(parameters.hitDef)
    end

end

function Loader.loadCustomComponent(object, class, parameters)
    assert(class, "Custom component class must be defined for object " .. object.name )
    local CustomComponent = Loader.loadFile(class, object.folder)

    object:addComponent(CustomComponent(parameters))

end


--- Adds a set of basic player states to a GameObject. The GameObject should have
-- a StateMachine, Animation, Transform, Input, Collision and Physics components.
-- See the parameter specification (TODO!) for details of building a GameObject from 
-- a set of parameters.
-- @tparam GameObject object The GameObject that will receive the created states. Must have a StateMachineComponent.
-- @tparam table stateParams The parameter table.
function Loader.loadBasicStates(object, stateParams)

    assert(stateParams.stand and 
           stateParams.walk and 
           stateParams.jump and 
           stateParams.fall and 
           stateParams.climb and
           stateParams.hit,
        "All six basic states must be specified for basic state inclusion")

    assert(stateParams.stand.dynamics and
           stateParams.walk.dynamics and
           stateParams.jump.dynamics and 
           stateParams.fall.dynamics and 
           stateParams.climb.dynamics and
           stateParams.hit.dynamics,
        "All six basic state dynamics must be specified for basic state inclusion")

    assert(stateParams.stand.animation and 
           stateParams.walk.animation and 
           stateParams.jump.animation and 
           stateParams.fall.animation and 
           stateParams.climb.animation and
           stateParams.hit.animation,
            "All six basic state animations must be specified for basic state inclusion")

    if not stateParams.jump.class then
        stateParams.jump.class = BasicJump
    end

    if not stateParams.climb.class then
        stateParams.climb.class = Climb
    end
       
    if not stateParams.hit.class then
        stateParams.hit.class = Hit
    end
       
    Loader.loadStates(object, stateParams)

    Loader.loadTransitions(object, Loader.basicTransitions)

    for stateName, state in pairs(stateParams) do
        if state.omitTransitions then
            object.stateMachine.states[stateName].transitions = {}
        end
    end

    object.stateMachine.states.stand:addFlag("grounded")
    object.stateMachine.states.walk:addFlag("grounded")
    object.stateMachine.states.jump:addFlag("air")
    object.stateMachine.states.fall:addFlag("air")
    object.stateMachine.states.climb:addFlag("climb")

end

--- Creates and adds states from a list of state parameters.
-- See the parameter specification (TODO!) for details of building a GameObject from a set of parameters.
-- @tparam GameObject object The GameObject that will receive the created states. Must have a StateMachineComponent.
-- @tparam table states The states' parameters table.
function Loader.loadStates(object, states)

    assert(type(states) == "table", "\'states\' parameter must be a table.")

    local CustomState, newState

    for stateName, stateParams in pairs(states) do
        if stateParams.class then
            if type(stateParams.class) == "string" then
                CustomState = Loader.loadFile(stateParams.class, object.folder)
            elseif type(stateParams.class) == "table" or type(stateParams.class) == "function" then
                CustomState = stateParams.class
            end
        else
            CustomState = State
        end
        
        newState = CustomState(stateName)
        Loader.loadSingleState(object, newState, stateParams)
    end

end

function Loader.loadSingleState(object, newState, stateParams)
    local folder = object.folder
    local dynamics = Loader.loadFile(stateParams.dynamics, object.folder)

    for field, value in pairs(stateParams) do
        newState[field] = value
    end

    if stateParams.dynamics then
        
        newState.dynamics = dynamics
        Loader.normalizeDynamics(dynamics)
    end

    
    object.stateMachine:addState(newState)

end


--- Sets the default parameters for a dynamics table if they're missing.
-- @tparam table dynamics The dynamics table to normalize.
function Loader.normalizeDynamics(dynamics)
    dynamics.maxVelocity = dynamics.maxVelocity or vector(math.huge, math.huge)
    dynamics.friction = dynamics.friction or vector(0, 0)
    dynamics.noInputFriction = dynamics.noInputFriction or vector(0, 0)
    dynamics.defaultAcceleration = dynamics.defaultAcceleration or vector(0, 0)
    dynamics.inputAcceleration = dynamics.inputAcceleration or vector(0, 0)
    dynamics.gravity = dynamics.gravity or vector(0, 0)
end

--- Creates and adds transition from a parameter table.
-- See the parameter specification (TODO!) for details of building an Element from a set of parameters.
-- @tparam GameObject object The GameObject that will receive the created transitions. Must have a StateMachineComponent.
-- @tparam table transitions The transitions' parameters table.
function Loader.loadTransitions(object, transitions)
    for _, transition in ipairs(transitions) do
        assert(transition.from, "Transition origin not specified in parameters.")
        assert(transition.condition, "Transition condition not specified in parameters.")
        assert(transition.to, "Transition target not specified in parameters.")

        if type(transition.from) == "string" then
            assert(object.stateMachine.states[transition.from], "Transition origin state "..transition.from.." does not exist")
            object.stateMachine.states[transition.from]:addTransition(transition.condition, transition.to, transition.priority)
        elseif type(transition.from) == "table" then
            for _, fromState in ipairs(transition.from) do
                assert(object.stateMachine.states[fromState], "Transition origin state "..fromState.." does not exist")
                object.stateMachine.states[fromState]:addTransition(transition.condition, transition.to, transition.priority)
            end
        end
    end

end

--- Loads a table from a file.
-- @tparam string path The path of the file to be loaded.
-- @tparam[opt] string folder The folder to load the file from. 
-- @treturn table The loaded table.
function Loader.loadFile(path, folder)

    folder = folder and (folder .. "/") or ""

    local fullPath = folder .. path

    if folder and (not love.filesystem.isFile(fullPath)) then
        fullPath = path
    end

    assert(love.filesystem.isFile(fullPath), "File \'".. path .. "\' does not exist")

    local ok, paramsFile = pcall(love.filesystem.load, fullPath)
    assert(ok, "Loaded file " .. path .. " has errors: " .. tostring(paramsFile))

    local parameters = paramsFile()
    assert(type(parameters) == "table", "Loaded file \'" .. path .. "\' must return a table")

    return parameters
end

--- Transitions between basic states.
-- @table basicTransitions
Loader.basicTransitions =
    {
        { 
            from        = { "walk", "stand", "climb", "jump", "hit"},
            to          = "hit",
            condition   = 
                function (currentState, collisionFlags)
                    return collisionFlags.hit
                end
        },

        {
            from        = { "walk", "stand" },
            to          = "jump",
            condition   = 
                function(currentState, collisionFlags) 
                    return currentState.owner.input.hasControl and currentState.owner.control.tap["jump"]
                end
        },

        {
            from        = { "walk" },
            to          = "stand",
            condition   =
                function(currentState, collisionFlags) 
                    return currentState.owner.input.hasControl and 
                            not (currentState.owner.control["left"] or currentState.owner.control["right"]) and
                            currentState.owner.physics.velocity.x == 0
                end
        },

        {
            from        = { "walk", "stand" },
            to          = "fall",
            condition   = 
                function(currentState, collisionFlags) 
                    return collisionFlags.canMoveDown
                end
        },

        {
            from        = { "stand" },
            to          = "walk",
            condition   =
                function(currentState, collisionFlags) 
                    return currentState.owner.input.hasControl and (currentState.owner.control["left"] or currentState.owner.control["right"])
                end
        },

        {
            from        = { "stand", "fall", "jump", },
            to          = "climb",
            condition   = 
                function (currentState, collisionFlags)
                    local ladder = collisionFlags.specialEvents.ladder
                    if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
                        currentState.owner:move(vector(ladder.position.x - currentState.owner.transform.position.x, 0))
                        return true
                    else
                        return false
                    end
                end
        },

        {
            from        = { "stand" },
            to          = "climb",
            condition   =
                function (currentState, collisionFlags)
                    local ladder = collisionFlags.specialEvents.standingOnLadder
                    if ladder and currentState.owner.control["down"] then
                        currentState.owner:move(ladder.position - currentState.owner.transform.position)
                        return true
                    else
                        return false
                    end
                end
        },


        {
            from        = { "fall" },
            to          = "stand",
            condition   = 
                function(currentState, collisionFlags) 
                    return (not collisionFlags.canMoveDown) and currentState.owner.physics.velocity.y > 0
                end
        },

        {
            from        = { "jump" },
            to          = "fall",
            condition   = 
                function(currentState, collisionFlags) 
                    return currentState.owner.physics.velocity.y > 0
                end
        },
        
        {
            from        = { "climb" },
            to          = "fall",
            condition   = 
                function (currentState, collisionFlags)
                    return currentState.owner.control.tap["jump"] or not collisionFlags.specialEvents.ladder
                end
        },

        {
            from        = { "hit" },
            to          = "fall",
            condition   = 
                function (currentState, collisionFlags)
                    return currentState.owner.input.hasControl
                end
        }
    }

return Loader
