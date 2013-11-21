
-- @class module
-- @name data.core.PhysicsComponent

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


function Loader.loadStage(name)

    local folder = globals.stageFolder .. string.gsub(name, '[^%a%d-_/]', '')
    assert(love.filesystem.isFile(folder .. "/config.lua"), "Stage configuration file \'".. folder .. "/config.lua"   .."\' not found")
    local ok, stageFile = pcall(love.filesystem.load, folder .. "/config.lua")
    assert(ok, "Stage file has syntax errors: " .. tostring(stageFile))
    local parameters = stageFile()

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

function Loader.loadCharacter(name)
   
    local path = globals.characterFolder .. string.gsub(name, "[^%a%d-_/]", "") .. "/config.lua"    
    local parameters = Loader.loadFile(path)

    local character = GameObject.new()
    character.folder = globals.characterFolder .. string.gsub(name, "[^%a%d-_/]", "")
    character.name = name

    character:addComponent(TransformComponent())
    character:addComponent(InputComponent())
    character:addComponent(PhysicsComponent())

    if parameters.sprites and parameters.animations then
        assert(parameters.sprites.sheet and 
               parameters.sprites.spriteSize, "sheet and spriteSize must be defined for character " .. name)

        character:addComponent(AnimationComponent(globals.characterFolder ..  string.gsub(name, "[^%a%d-_/]", "") 
                                                        .. "/" .. parameters.sprites.sheet, 
                                                    parameters.sprites.spriteSize, 
                                                    parameters.sprites.spriteOffset))

        for k, v in pairs(parameters.animations) do
            character.animation:addAnimation(k, v)
        end
    end    

    if parameters.size then
        character:addComponent(CollisionComponent(parameters.size))
    end    
    
    if parameters.states or parameters.basicStates then

        assert(parameters.initialState and type(parameters.initialState) == "string", "Must specify a valid initial state")
        character:addComponent(StateMachineComponent())

        if parameters.basicStates then
            Loader.loadBasicStates(character, parameters.basicStates)
        end

        if parameters.states then
            Loader.loadStates(character, parameters.states)
        end

        if parameters.transitions then
            Loader.loadTransitions(character, parameters.transitions)
        end

        character.stateMachine.initialState = parameters.initialState
    end

    if parameters.postBuild then
        parameters.postBuild(character)
    end

    return character

end

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

--- Creates and adds states from a parameter table.
-- See the parameter specification (TODO!) for details of building an Element from a set of parameters.
-- @param parameters The parameter table.
-- @see Element:addSingleStateFromParams, Element:loadSpritesFromParams
function Loader.loadStates(object, states)

    assert(type(states) == "table", "\'states\' parameter must be a table.")

    local CustomState, newState

    for stateName, stateParams in pairs(states) do

        if stateParams.class then
            if type(stateParams.class) == "string" then
                local ok, classFile = pcall(love.filesystem.load, object.folder ..  '/' .. stateParams.class)
                assert(ok, "State class file has syntax errors: " .. tostring(classFile))
                CustomState = classFile()
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

    local ok, dynamicsFile = pcall(love.filesystem.load, folder .. "/" .. stateParams.dynamics)
    
    assert(ok, "Character dynamics file has syntax errors: " .. tostring(dynamicsFile))

    for field, value in pairs(stateParams) do
        newState[field] = value
    end

    local dynamics = dynamicsFile()

    newState.dynamics = dynamics

    
    object.stateMachine:addState(newState)

end


--- Creates and adds transition from a parameter table.
-- See the parameter specification (TODO!) for details of building an Element from a set of parameters.
-- @param parameters The parameter table.
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

function Loader.loadFile(path)
    assert(love.filesystem.isFile(path), "File \'".. path .. "\' not found")
    local ok, paramsFile = pcall(love.filesystem.load, path)
    assert(ok, "Loaded file " .. path .. " has syntax errors: " .. tostring(playerFile))
    local parameters = paramsFile()
    assert(type(parameters) == "table", "Loaded file \'" .. path .. "\' must return a table")
    return parameters
end

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
