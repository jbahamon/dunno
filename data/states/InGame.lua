local WorldManager = require 'data.core.WorldManager'
local vector = require 'lib.hump.vector'

return function (state)

    function state:init()
        self.manager = nil
    end

    function state:enter(previous)

        self.manager = WorldManager("")
        self.manager:addViewport(vector(0, 0), vector(512, 480))
        self.manager:setStage(previous.chosenStage)
        self.manager:addPlayer(previous.chosenCharacter)
        self.manager:start()
    end


    function state:leave(previous)
        self.doExit = nil
    end

    function state:update(dt)
        if self.doExit then
            -- TODO: self.manager:destroySelf()
            self.manager = nil
            return self.parent
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
            self.doExit = function () return self.parent end
        end
  
    end

    return state

end
