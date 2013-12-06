local WorldManager = require 'data.core.WorldManager'
local vector = require 'lib.hump.vector'

return function (state)

    function state:init()
        
    end

    function state:enter(previous)
        self.manager = WorldManager("")
        self.manager:addViewport(vector(0, 0), vector(512, 480))
        self.manager:setStage(previous.chosenStage)
        self.manager:createPlayer(previous.chosenCharacter)
        self.manager:start()
    end


    function state:leave(previous)
        self.doExit = nil
        self.manager:destroySelf()
        self.manager = nil
    end

    function state:update(dt)

        if self.doExit then
            return self.parent
        end

        if self.manager.gameFinished then
            self.summary = {
                endState = self.manager.endState,
            }
            
            return "GameEnded"
        end

        if dt <= 1/60.0 then
            self.manager:update(dt)
        end
    end

    function state:draw()
        self.manager:draw()
    end

    function state:keypressed(key, code)
        if key == "escape" then
            self.doExit = true
        end
  
    end

    return state

end
