local assert = assert
local colors = require 'lib.colors'

local export = {}

function export:init(quickie, schema)
  self.quickie = quickie

  self.grid = {}
  self.grid.columns = schema.columns
  self.grid.rows = schema.rows
  self.grid.alignment = {
    horizontal = schema.alignment.horizontal,
    vertical = schema.alignment.vertical
  }
  self.grid.margin = schema.margin

  self.grid.width = 0
  self.grid.height = 0
  self.grid.offset = { x = 0, y = 0 }

  -- calculate grid width
  for i=1,#self.grid.columns do
    self.grid.width = self.grid.width + self.grid.columns[i]
  end

  -- calculate grid height
  for i=1,#self.grid.rows do
    self.grid.height = self.grid.height + self.grid.rows[i]
  end

  -- calculate grid horizontal offset based on alignment
  if self.grid.alignment.horizontal == "center" then
    local window_width = love.graphics.getWidth()
    self.grid.offset.x = (window_width / 2) - (self.grid.width / 2)
  end

  -- calculate grid vertical offset based on alignment
  if self.grid.alignment.vertical == "center" then
    local window_height = love.graphics.getHeight()
    self.grid.offset.y = (window_height / 2) - (self.grid.height / 2)
  end

  -- initialize cell array
  self.grid.cells = {}
  for column=1,#self.grid.columns do
    self.grid.cells[column] = {}
    for row=1,#self.grid.rows do
      self.grid.cells[column][row] = {
        x = 0,
        y = 0,
        width = 0,
        height = 0
      }
    end
  end

  -- set y position values in cell array
  local y_accumulator = 0
  for row=1,#self.grid.rows do
    local temp_y = y_accumulator

    local non_carry_y = self.grid.offset.y + self.grid.margin.top
    -- print(non_carry_y)
    if row == 1 then
      for c=1,#self.grid.columns do
        self.grid.cells[c][row].y = non_carry_y
        self.grid.cells[c][row].height = self.grid.rows[row]
      end
    else
      temp_y = temp_y + self.grid.rows[row - 1]
      -- print(non_carry_y)
      for c=1,#self.grid.columns do
        self.grid.cells[c][row].y = non_carry_y + temp_y
        self.grid.cells[c][row].height = self.grid.rows[row]
      end
    end
    y_accumulator = temp_y
  end

  -- set x position values in cell array
  local x_accumulator = 0
  for column=1,#self.grid.columns do
    local temp_x = x_accumulator

    local non_carry_x = self.grid.offset.x + self.grid.margin.left
    if column == 1 then
      for r=1,#self.grid.rows do
        self.grid.cells[column][r].x = non_carry_x
        self.grid.cells[column][r].width = self.grid.columns[column]
      end
    else
      temp_x = temp_x + self.grid.columns[column - 1]
      for r=1,#self.grid.rows do
        self.grid.cells[column][r].x = non_carry_x + temp_x
        self.grid.cells[column][r].width = self.grid.columns[column]
      end
    end
    x_accumulator = temp_x
  end

  return self.grid.width
end

function export:TestDrawGrid()
  love.graphics.setLine(1, "rough")
  colors:push(255, 0, 255, 255)

  local y_accumulator = 0
  for row=1,#self.grid.rows do
    if row == 1 then
      local x1 = self.grid.margin.left
      local y1 = 0
      local x2 = self.grid.margin.left + self.grid.width
      local y2 = y1

      love.graphics.line(
        x1 + self.grid.offset.x,
        y1 + self.grid.margin.top + self.grid.offset.y,
        x2 + self.grid.offset.x,
        y2 + self.grid.margin.top + self.grid.offset.y)
    end

    local x1 = self.grid.margin.left
    local y1 = self.grid.rows[row] + y_accumulator
    local x2 = self.grid.margin.left + self.grid.width
    local y2 = y1

    love.graphics.line(
      x1 + self.grid.offset.x,
      y1 + self.grid.margin.top + self.grid.offset.y,
      x2 + self.grid.offset.x,
      y2 + self.grid.margin.top + self.grid.offset.y)

    y_accumulator = y1
  end

  local x_accumulator = 0
  for column=1,#self.grid.columns do
    if column == 1 then
      local x1 = 0
      local y1 = self.grid.margin.top
      local x2 = x1
      local y2 = self.grid.margin.top + self.grid.height

      love.graphics.line(
      x1 + self.grid.margin.left + self.grid.offset.x,
      y1 + self.grid.offset.y,
      x2 + self.grid.margin.left + self.grid.offset.x,
      y2 + self.grid.offset.y)
    end

    local x1 = self.grid.columns[column] + x_accumulator
    local y1 = self.grid.margin.top
    local x2 = x1
    local y2 = self.grid.margin.top + self.grid.height

    love.graphics.line(
      x1 + self.grid.margin.left + self.grid.offset.x,
      y1 + self.grid.offset.y,
      x2 + self.grid.margin.left + self.grid.offset.x,
      y2 + self.grid.offset.y)

    x_accumulator = x1
  end

  colors:pop()
end


function export:getShape(column, row, columnspan, rowspan, align)
  assert(column + columnspan - 1 <= #self.grid.columns, string.format("oops: %d, %d, %d", column, columnspan,#self.grid.columns))
  assert(row + rowspan - 1 <= #self.grid.rows)

  local x = self.grid.cells[column][row].x
  local y = self.grid.cells[column][row].y

  local width = self.grid.cells[column][row].width
  local height = self.grid.cells[column][row].height

  if columnspan > 1 then
    local lastColumn = column + columnspan
    for c=column+1,lastColumn-1 do
      width = width + self.grid.cells[c][row].width
    end
  end

  return x, y, width, height
end

function export:Label(content, column, row, columnspan, rowspan, align, font, id)
  local x, y, width, height = self:getShape(column, row, columnspan, rowspan)
  if font then
    love.graphics.setFont(font)
  end
  return self.quickie.Label{text = content, pos = {x, y}, size = {width, height}, align = align, id = id }
end

function export:Button(content, column, row, columnspan, rowspan, font, id)
  local x, y, width, height = self:getShape(column, row, columnspan, rowspan)
  if font then
    love.graphics.setFont(font)
  end
  return self.quickie.Button{text = content, pos = {x, y}, size = {width, height}}
end

function export:Slider(info, column, row, columnspan, rowspan, vertical, id)
  local x, y, width, height = self:getShape(column, row, columnspan, rowspan)

  return self.quickie.Slider{info = info, pos = {x, y}, size = {width, height}, vertical = vertical, id = id} 
end


return export
