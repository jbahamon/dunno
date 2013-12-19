return function (state)

    function state:init()

        self.drawGrid = false

        self.colors = require 'lib.colors'
        self.gui = require 'lib.quickie'
        self.grid = require 'lib.quickie.grid'        

        self.debugName = "Title"

        self.fonts = {
            title = love.graphics.newFont("data/fonts/joystixmono.otf", 24),
            subtitle = love.graphics.newFont("data/fonts/joystixmono.otf", 12),
            menu = love.graphics.newFont("data/fonts/joystixmono.otf", 16)

        }

        self.gridschema = {
            columns = {160, 310, 160 },
            rows = { 50, 10, 30, 10, 30, 10, 30 },
            alignment = {
                horizontal = "center",
                vertical = "center"
            },

            margin = { left = 0, top = 0, right = 0, bottom = 0 }
        }
    end

    function state:enter(previous)
        self.gui.keyboard.clearFocus()
        self.grid:init(self.gui, self.gridschema)
    end

    function state:update(dt)
        if self.doExit then return self.parent end

        self.grid:Label("Settings", 1, 1, 3, 1, 'center', self.fonts["title"])

        if self.grid:Button("Input settings", 2, 3, 1, 1, self.fonts["menu"]) then
            return "InputSettings"
        end

        if self.grid:Button("Display settings", 2, 5, 1, 1, self.fonts["menu"]) then
            return "DisplaySettings"
        end

        if self.grid:Button("Back", 2, 7, 1, 1, self.fonts["menu"]) then
            return self.parent
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
            self.doExit = self.parent
        end
    end

    return state
end
