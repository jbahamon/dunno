return function (state)

    function state:init()
        self.drawGrid = false

        self.colors = require 'lib.colors'
        self.gui = require 'lib.quickie'
        self.grid = require 'lib.quickie.grid'        

        self.debugName = "GameEnded"

        self.fonts = {
            title = love.graphics.newFont("data/fonts/joystixmono.otf", 24),
            menu = love.graphics.newFont("data/fonts/joystixmono.otf", 16)
        }

    end

    function state:enter(previous)
        self.timer = 0
        self.gui.keyboard.clearFocus()
         self.title = (previous.summary.endState == "Win") and "You won!" or "You lost!"

        local gridschema = {
            columns = {150, 10, 310 , 10, 150 },
            rows = { 30, 10, 30 },
            alignment = {
                horizontal = "center",
                vertical = "center"
            },

            margin = { left = 0, top = 0, right = 0, bottom = 0 }
        }

        self.grid:init(self.gui, gridschema)
    end

    function state:leave(previous)
        self.doExit = nil
    end

    function state:update(dt)

        self.timer = self.timer + dt

        if self.doExit and self.timer > 0.5 then
            return "Title"
        end

        self.grid:Label(self.title, 3, 1, 1, 1, "center", self.fonts["title"])
        self.grid:Label("Press any key to continue (or click!)", 3, 3, 1, 1, "center", self.fonts["menu"])

    end

    function state:draw()
        self.gui.core.draw()
        if self.drawGrid then self.grid:TestDrawGrid() end
    end

    function state:keypressed(key, code)
        if globals.DEBUG and key == "g" then
            self.drawGrid = not self.drawGrid
        else 
            self.doExit = true 
        end
    end

    function state:keypressed(key, code)
        if globals.DEBUG and key == "g" then
            self.drawGrid = not self.drawGrid
        else 
            self.doExit = true 
        end
    end

    function state:mousepressed(x, y, button)
        self.doExit = true
    end

    return state

end
