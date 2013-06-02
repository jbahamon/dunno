return function (state)

  function state:init()
    print("init titleoptions")
  end

  function state:enter(previous)
    print("enter titleoptions")
  end

  function state:update(dt)
  end

  function state:draw()
  end

  function state:keypressed(key, code)
    print("titleoptions")
  end

  return state

end
