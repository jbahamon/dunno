local vector = require 'lib.hump.vector'

local params = {
    
    includeBasicStates = true,

    size = vector(12, 24),

    sprites = {
        sheet = "Sprites.png",
        spriteSize = vector(27, 40),
        spriteOffset = vector(0, 2)
    },

    basicStates = {
        jump = {
            dynamics = "States/jump.dyn",
            animation = "jump",
            class = "States/Jump.lua"
        },

        stand = {
            vulnerable = true,
            dynamics = "States/stand.dyn",
            animation = "stand"
        },

        climb = {
            dynamics = "States/Climb.dyn",
            animation = "climb"
        },

        walk = {
            dynamics = "States/walk.dyn",
            animation = "walk"
        },

        fall = {
            dynamics = "States/fall.dyn",
            animation = "fall"
        },

        hit = {
            dynamics = "States/hit.dyn",
            animation = "hit"
        }
    },  

    animations = {

        hit = { 
            mode = 'loop',
            frames = {'1,4', '4,4'},
            defaultDelay = 2/60 
        },

        jump = { 
            mode = 'once',
            frames = {'1,4', '2,1', '4,1'},
            defaultDelay = 3/60 
        },

        fall = { 
            mode = 'once',
            frames = '4,1',
            defaultDelay = 0.2 
        },

        walk = { 
            mode = 'loop',
            frames = '1-3,1',
            defaultDelay = 3/60 
        },

        stand = { 
            mode = 'loop',
            frames = '1,4',
            defaultDelay = 0.2
        },

        spinJump = {
            mode = 'loop',
            frames = '1-4, 2',
            defaultDelay = 2/60.0
        },

        morphBall = {
            mode = 'loop',
            frames = '1-4, 3',
            defaultDelay = 2/60.0
        },

        climb = { 
            mode = 'loop',
            frames = '2-3,4',
            defaultDelay = 10/60.0,
        }

    },

    states = {
        diagJump = {
            dynamics = "States/diagJump.dyn",
            class = "States/diagJump.lua",
            animation = "spinJump",
            size = vector(13, 13),
            flags = {"air"},
        },

        diagFall = {
            dynamics = "States/diagJump.dyn",
            class = "States/diagFall.lua",
            animation = "spinJump",
            size = vector(13, 13),
            flags = {"air"},

        },

        morphBall = {
            dynamics = "States/morphBall.dyn",
            class = "States/morphBall.lua",
            animation = "morphBall",
            size = vector(10, 10),
            flags = {"grounded"},

        }
    },

    transitions = {

        {   
            from        = { "morphBall" },
            to          = "stand",
            condition   =
                function (currentState, collisionFlags)
                    return currentState.owner.control["up"]
                end
        },

        {
            from        = { "diagFall", "morphBall" },
            to          = "hit",
            condition   =
                function (currentState, collisionFlags)
                    return collisionFlags.hit
                end
        },

        {
            from        = { "diagFall", "diagJump" },
            to          = "stand",
            condition =
                function(currentState, collisionFlags) 
                    return (not collisionFlags.canMoveDown) and currentState.owner.physics.velocity.y > 0
                end,
            targetState = "stand"
        },

        {
            from        = { "diagFall", "diagJump" },
            to          = "climb",
            condition =
                function (currentState, collisionFlags)
                    local ladder = collisionFlags.specialEvents.ladder
                    if ladder and (currentState.owner.control["up"] or currentState.owner.control["down"]) then
                        currentState.owner:move(vector(ladder.position.x - currentState.owner.physics.position.x, 0))
                        return true
                    else
                        return false
                    end
                end
        },

        {
            from        = { "diagJump" },
            to          = "diagFall",
            condition =
                function(currentState, collisionFlags) 
                    return currentState.owner.physics.velocity.y > 0
                end,
        },

        {
            from        = { "diagFall" },
            to          = "fall",
            condition   =
                function (currentState, collisionFlags)
                    return currentState.owner.physics.stateTime > 0.8
                end                 
        },

        {
            from        = { "jump" },
            to          = "diagJump",
            condition   = 
                function (currentState, collisionFlags)
                    return currentState.owner.physics.stateTime < 1/30 and (currentState.owner.control["left"] or currentState.owner.control["right"])
                end,    
            priority = 1
        },

        {
            from        = { "stand" },
            to          = "morphBall",
            condition   = 
                function (currentState, collisionFlags)
                    return currentState.owner.control["down"]
                end
        }
            
    },

    initialState = "stand"
}

return params