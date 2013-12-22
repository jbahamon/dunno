--- Dunno entry point. Also the point of definition of global variables.
-- @module main

--- Global variables.
-- @class table
-- @name globals
-- @field DEBUG Debug flag. If set to true, hitboxes are visible and other
--  debug messages are enabled.
-- @field Timer Utility for programming delayed events and others.
-- See <a href="http://vrld.github.com/hump/">hump's documentation</a> for 
-- more info on its use and behavior.
globals = {
    -- FIXME set these in their own file
    characterFolder = 'characters/',
    stageFolder = 'stages/',
	scale = 2,
	DEBUG = true,
	debugSettings = {
		collisionBoxColor = {0, 0, 255, 100},
		hitBoxColor = {255, 0, 0, 100}
	},

  playerKeys = {
    {
      up = "up",
      down = "down",
      left = "left",
      right = "right",
      z = "jump",
      x = "special"
    },

    {
      i = "up",
      j = "down",
      k = "left",
      l = "right",
      t = "jump",
      y = "special",
    },

  }
}

globals.Timer = require 'lib.hump.timer'
globals.Loader = require 'data.core.Loader'


--- Clamp number between two values.
-- Globally defined.
-- Returns input if it is between min_val and max_val; max_val if it is 
-- larger than it; min_val if it is smaller than it.
-- @param input The value to be clamped
-- @param min_val The lower bound of the clamping interval.
-- @param max_val The upper bound of the clamping interval. Must be 
-- greater than or equal to min_val

function math.clamp(input, min_val, max_val)
	input = math.min(input, max_val)
	input = math.max(input, min_val)
	return input
end

local game = {
  libs = {},
  states = {
    head = nil,
    Title = {
      template = require 'data.states.Title',
      parent = nil
    },
    GameSelection = {
      template = require 'data.states.GameSelection',
      parent = "Title"
    },
    InGame = {
      template = require 'data.states.InGame',
      parent = "Title"
    },
    InGameOptions = {
      template = require 'data.states.InGameOptions',
      parent = "InGame"
    },
    Settings = {
        template = require 'data.states.Settings',
        parent = "Title"
    },
    InputSettings = {
        template = require 'data.states.InputSettings',
        parent = "Settings"
    },
    DisplaySettings = {
        template = require 'data.states.DisplaySettings',
        parent = "Settings"
    },
    GameEnded = {
        template = require 'data.states.GameEnded',
        parent = "InGame"
    },
  }
}

local newState = function (blankState, stateTemplate)
  return stateTemplate(blankState)
end

function love.load()
	love.graphics.setMode(love.graphics.getMode())
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setBackgroundColor(39, 40, 34, 255)
	love.graphics.setFont(love.graphics.newFont(16))

	-- load libs
	game.libs.Gamestate = require 'lib.hump.gamestate'

	for name, value in pairs(game.states) do
		value.state = value.template({})
		value.state.parent = value.parent
	end

	game.states.head = game.states.Title.state
	game.libs.Gamestate.switch(game.states.head)
end

function love.update(dt)
	globals.Timer.update(dt)
	local nextstate = game.states.head:update(dt)
    
	if nextstate then
		assert(game.states[nextstate] ~= nil, string.format("%s does not exist", nextstate))
		game.libs.Gamestate.switch(game.states[nextstate].state)
		game.states.head = game.states[nextstate].state
	end
end

function love.draw()
	game.states.head:draw()
end

function love.keypressed(key, code)
	game.states.head:keypressed(key, code)
end

function love.mousepressed(x, y, button)
    if game.states.head.mousepressed then
        game.states.head:mousepressed(x, y, button)
    end
end