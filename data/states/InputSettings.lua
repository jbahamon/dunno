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
            columns = {75, 10, 75, 10, 75, 10, 50, 5, 20},
            rows = { 50, 10, 30, 10, 30, 10, 30, 10, 30, 10, 30, 10, 30, 10, 30, 10, 30, 10, 30 },
            alignment = {
                horizontal = "center",
                vertical = "center"
            },

            margin = { left = 0, top = 0, right = 0, bottom = 0 }
        }
        self.checkboxSizes = {1, 1, 1, 2}

        self.currentDisplacement = 0
        self.minGridPos = 7
        self.bindsOrder = {"up", "down", "left", "right", "jump", "special"}

        self.numItems = 5


    end

    function state:enter(previous)
        self.gui.keyboard.clearFocus()
        self.grid:init(self.gui, self.gridschema)
        self.selectedPlayer = 1
        self.changeKeyPrompt = false
        self.currentDisplacement = 1
        self.sliderData = {value = 1, max = 1, min = #self.bindsOrder - self.numItems + 1, step = -1}

        self.playerKeys = {}
        for _, bindings in ipairs(globals.playerKeys) do
            local binds = {}
            for key, command in pairs(bindings) do
                binds[command] = key
            end
            table.insert(self.playerKeys, binds)
        end
    end

    function state:update(dt)

        self.sliderData.value = self.currentDisplacement + 1

        if self.doExit then return self.parent end

        self.grid:Label("Input Settings", 1, 1, 8, 1, 'center', self.fonts["title"])
        self.grid:Label("Select player: ", 1, 3, 1, 1, 'left', self.fonts["menu"] )


        for i = 1, 4 do
            if self.grid:Checkbox(tostring(i), 1 + (i - 1) * 2, 5, 2, 1, 
                'left', self.fonts["menu"], self.selectedPlayer == i, "checkbox"..i) then
                self.selectedPlayer = i
            end
        end

        if self.grid:Button("Set All", 1, 7, 9, 1, self.fonts["menu"], "all") then
            return self.parent
        end


        if self.grid:Slider(self.sliderData, 9, self.minGridPos + 2, 1, self.numItems * 2 - 1, true, "slider") then
            self.sliderData.value = math.floor(self.sliderData.value + 0.5)
            self.currentDisplacement = self.sliderData.value - 1
        end


        for i = 1, self.numItems do

            self.grid:Label(self.bindsOrder[i + self.currentDisplacement], 1, 
                self.minGridPos + 2 * i, 3, 1, 'left', self.fonts["menu"]) 
            

            if self.grid:Button(self.playerKeys[self.selectedPlayer][self.bindsOrder[self.currentDisplacement + i]], 
                5, self.minGridPos + 2 * i, 3, 1, 
                self.fonts["menu"], 
                "control"..tostring(self.currentDisplacement + i)) then

                self.changeKeyPrompt  = true
                self.selectedControlIndex = self.currentDisplacement + i

            end            
        end

        if self.grid:Button("Back", 2, 19, 5, 1, self.fonts["menu"], "back") then
            return self.parent
        end

        if self.changeKeyPrompt then
            self.gui.BoxedLabel{text = "Press key/button to set", pos = "center", size = {"tight", "tight"}}
            self.gui.mouse.disable()
            self.gui.keyboard.disable()
        end
    end

    function state:draw()
        self.gui.core.draw()
        if self.drawGrid then self.grid:TestDrawGrid() end
    end

    function state:keypressed(key, code)

        if self.changeKeyPrompt then
            -- If we are actually creating a new binding, we ignore everything else.
            if key ~= "escape" then 
                local oldKey = self.playerKeys[self.selectedPlayer][self.bindsOrder[self.selectedControlIndex]]

                if globals.playerKeys[self.selectedPlayer][key] then
                    self.playerKeys[self.selectedPlayer][globals.playerKeys[self.selectedPlayer][key]] = oldKey  
                    globals.playerKeys[self.selectedPlayer][oldKey] = globals.playerKeys[self.selectedPlayer][key]
                end

                self.playerKeys[self.selectedPlayer][self.bindsOrder[self.selectedControlIndex]] = key                
                globals.playerKeys[self.selectedPlayer][key] = self.bindsOrder[self.selectedControlIndex]

            end
            self.changeKeyPrompt = false
            self.gui.mouse.enable()
            self.gui.keyboard.enable()
            self:controlsForward(self.selectedControlIndex)

        elseif key == "escape" then
            -- Exiting
            self.doExit = self.parent

        elseif type(self.gui.keyboard.getFocus()) == "string" and 
            self.gui.keyboard.getFocus():find("^checkbox") and
            (key == "left" or key == "right" or
             key == "up" or key == "down") then

            -- Custom navigation according to the layout
            if key == "left" or key == "right" then
                local inc = key == "left" and -1 or 1
                local newIndex = ((tonumber(self.gui.keyboard.getFocus():sub(9)) - 1) + inc) % 4 + 1
                self.gui.keyboard.setFocus("checkbox".. newIndex)
            elseif key == "up" then
                self.gui.keyboard.setFocus("back")
            elseif key == "down" then
                self.gui.keyboard.setFocus("all")
            end
        
        elseif type(self.gui.keyboard.getFocus()) == "string" and 
            self.gui.keyboard.getFocus():find("^control") and
            (key == "up" or key == "down" or key == "right") then
            local controlIndex = tonumber(self.gui.keyboard.getFocus():sub(8))

            if key == "up" then
                self:controlsBack(controlIndex)
            elseif key == "down" then
                self:controlsForward(controlIndex)
            end

        elseif self.gui.keyboard.hasFocus("all") and key == "down" then
            self.gui.keyboard.setFocus("control"..tostring(self.currentDisplacement + 1))
        elseif globals.DEBUG and key == "g" then
            self.drawGrid = not self.drawGrid
        else
            -- The library handles all other keypresses.
            self.gui.keyboard.pressed(key, code)
        end

       

    end


    function state:controlsForward(controlIndex)
        if controlIndex - self.currentDisplacement < self.numItems then
            self.gui.keyboard.setFocus("control"..tostring(controlIndex + 1))
        elseif controlIndex < #self.bindsOrder then
            self.currentDisplacement = self.currentDisplacement + 1
            self.gui.keyboard.setFocus("control"..tostring(controlIndex + 1))
        else
            self.gui.keyboard.setFocus("back")
        end
    end

    function state:controlsBack(controlIndex)
        if controlIndex - self.currentDisplacement > 1 then
            self.gui.keyboard.setFocus("control"..tostring(controlIndex - 1))
        elseif self.currentDisplacement > 0 then
            self.currentDisplacement = self.currentDisplacement - 1
            self.gui.keyboard.setFocus("control"..tostring(controlIndex - 1))
        else
            self.gui.keyboard.setFocus("all")
        end
    end

    return state
end
