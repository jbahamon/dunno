return function (state)

    function state:init()
        self.characters = {
            "Mario",
            "Samus",
            "Megaman",
            "Scrooge",
            "Bayonetta",
            "Kirby"
        }

        self.stages = {
            "SMB3-1-1",
            "TomahawkMan",
            "Tourian",
            "YoshisIsland3",
        }

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

        self.maxElems = 6

        self.gridschema = {
            columns = {160, 310, 160 },
            rows = { 50, 10, 30, 5, 30, 5, 30, 5, 30, 5, 30, 5, 30, 5, 30},
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

        self.chosenCharacter = nil
        self.chosenStage = nil

        self.charIndex = 1
        self.stageIndex = 1

        self.minCharIndex = 1
        self.minStageIndex = 1

    end

    function state:leave(previous)
        self.doExit = false
    end

    function state:update(dt)

        if self.doExit then return self.parent end

        if not self.chosenCharacter then

            self.grid:Label("Choose your character", 2, 1, 1, 1, 'center', self.fonts["title"])

            for i = self.minCharIndex, math.min(self.maxElems, #self.characters) do
                if self.grid:Button(self.characters[i], 2, 2 * i + 1, 1, 1, self.fonts["menu"], "char-" .. i ) then
                    self.chosenCharacter = self.characters[i]
                end

            end     

            local i = math.min(self.maxElems, #self.characters) + 1

            if self.grid:Button("Back", 2, 2 * i + 1, 1, 1, self.fonts["menu"]) then
                return self.parent
            end

            if self.chosenCharacter then
                self.gui.keyboard.clearFocus()
            end


        elseif not self.chosenStage then

            self.grid:Label("Choose a stage", 2, 1, 1, 1, 'center', self.fonts["title"])

            for i = self.minStageIndex, math.min(self.maxElems, #self.stages) do
                if self.grid:Button(self.stages[i], 2, 2 * i + 1, 1, 1, self.fonts["menu"], "stage-" .. i ) then
                    self.chosenStage = self.stages[i]
                end

            end     

            local i = math.min(self.maxElems, #self.stages) + 1

            if self.grid:Button("Back", 2, 2 * i + 1, 1, 1, self.fonts["menu"]) then
                self.chosenCharacter = nil
            end

        else
            return "InGame"
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
            if self.chosenCharacter then 
                self.chosenCharacter = nil
                self.gui.keyboard.clearFocus()
            else 
                self.doExit = true
            end
        end
    end

    return state

end
