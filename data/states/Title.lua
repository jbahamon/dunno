return function (state)

    function state:init()
        self.drawGrid = false

        self.colors = require 'lib.colors'
        self.gui = require 'lib.quickie'
        self.grid = require 'lib.quickie.grid'        

        self.debugName = "Title"

        self.fonts = {
            title = love.graphics.newFont("data/fonts/joystixmono.otf", 50),
            subtitle = love.graphics.newFont("data/fonts/joystixmono.otf", 12),
            menu = love.graphics.newFont("data/fonts/joystixmono.otf", 16)

        }

        self.gridschema = {

            columns = {160, 310, 160 },
            rows = { 100, 20, 30, 30, 10, 30, 10, 30 },
            alignment = {
                horizontal = "center",
                vertical = "center"
            },
            margin = { left = 0, top = 0, right = 0, bottom = 0 }
        }

    end

    function state:enter(previous)
        self.gui.keyboard.clearFocus()
        self.drawGrid = false
        self.grid:init(self.gui, self.gridschema)
    end

    function state:leave(previous)
        self.doExit = nil
    end

    function state:update(dt)
        if self.doExit then return self.doExit() end

        self.grid:Label("DUNNO", 1, 1, 3, 1, 'center', self.fonts["title"])
        self.grid:Label("'cause we didn't know what to name it", 1, 2, 3, 1, "center", self.fonts["subtitle"])

        if self.grid:Button("Single Player", 2, 4, 1, 1, self.fonts["menu"]) then
            return "GameSelection"
        end

        if self.grid:Button("Settings", 2, 6, 1, 1, self.fonts["menu"]) then
            return "Settings"
        end

        if self.grid:Button("Quit", 2, 8, 1, 1, self.fonts["menu"]) then
            love.event.push("quit")
        end

    end

    function state:draw()
        self.gui.core.draw()
        if self.drawGrid then self.grid:TestDrawGrid() end
    end

    function state:keypressed(key, code)
        self.gui.keyboard.pressed(key, code)

        if globals.DEBUG and key == "g" then
            self.drawGrid = not self.drawGrid
        end

        if key == "escape" then
            love.event.push("quit")
        end
    end

    return state

end


