local colors = {}

colors.stack = {}
colors.stackLimit = 128


colors.pushRandom = function (self)
  self:push(math.random(255), 100 + math.random(155), math.random(255), 255)
end

colors.push = function (self, r, g, b, a)
  if #self.stack >= self.stackLimit then
    error("colors stack limit exceeded")
  end
  do
    local r, g, b, a = love.graphics.getColor()
    table.insert(self.stack, { r, g, b, a })
  end
  love.graphics.setColor(r, g, b, a)
end

colors.pop = function (self)
  if #self.stack < 1 then
    return nil
  else
    local color = table.remove(self.stack)
    love.graphics.setColor(color[1],
                            color[2],
                            color[3],
                            color[4])
  end
end

return colors
