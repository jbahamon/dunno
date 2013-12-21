local BASE = (...):match("(.-)[^%.]+$")
local core     = require(BASE .. 'core')
local group    = require(BASE .. 'group')
local mouse    = require(BASE .. 'mouse')
local keyboard = require(BASE .. 'keyboard')

-- {text = text, align = align,  pos = {x, y}, size={w, h}, widgetHit=widgetHit, draw=draw}
return function(w)
    assert(type(w) == "table" and w.text, "Invalid argument")
    w.align = w.align or 'left'

    local tight = w.size and (w.size[1] == 'tight' or w.size[2] == 'tight')
    if tight then
        local f = assert(love.graphics.getFont())
        if w.size[1] == 'tight' then
            w.size[1] = f:getWidth(w.text) + 10
        end
        if w.size[2] == 'tight' then
            w.size[2] = f:getHeight(w.text) + 10
        end
    end


    local id = w.id or core.generateID()
    local pos, size = group.getRect(w.pos, w.size)

    if w.pos == "center" then
        pos = { (love.graphics.getWidth() - size[1])/2, (love.graphics.getHeight() - size[2])/2 }
    end

    if keyboard.hasFocus(id) then
        keyboard.clearFocus()
    end

    core.registerDraw(id, w.draw or core.style.BoxedLabel,
        w.text, pos[1],pos[2], size[1],size[2])

    return mouse.releasedOn(id)
end

