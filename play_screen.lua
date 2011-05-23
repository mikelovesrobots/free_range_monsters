-- add a state to that class using addState, and re-define the method
local PlayScreen = ScreenManager:addState('PlayScreen')
PlayScreen.CELL_WIDTH = 10
PlayScreen.CELL_HEIGHT = 10
PlayScreen.MAP_MARGIN_TOP = 10
PlayScreen.MAP_MARGIN_LEFT = 25
PlayScreen.MAP_CELLS_Y = 46
PlayScreen.MAP_CELLS_X = 75

function PlayScreen:enterState() 
  log("PlayScreen initialized")
end

function PlayScreen:draw()
  love.graphics.setColor(255,255,255);
  love.graphics.printf("Press q to quit", 0, 500, 800, 'center')

  self:draw_map()
  self:draw_fps()
end

function PlayScreen:keypressed(key, unicode)
  if (key == "q") then
    screen_manager:popState()
  end
end

function PlayScreen:draw_map()
  love.graphics.setColor(255,255,255)

  for x=1,PlayScreen.MAP_CELLS_X do
    for y=1,PlayScreen.MAP_CELLS_Y do
      love.graphics.setColor(math.random(70,130),math.random(180,255), math.random(70,130))
      local pix_x = (x - 1) * PlayScreen.CELL_WIDTH + PlayScreen.MAP_MARGIN_LEFT
      local pix_y = (y - 1) * PlayScreen.CELL_HEIGHT + PlayScreen.MAP_MARGIN_TOP

      love.graphics.print(".", pix_x, pix_y)
    end
  end
end

function PlayScreen:draw_fps()
  love.graphics.setColor(0,0,255);
  love.graphics.print("FPS: " .. love.timer.getFPS(), 2, 2)
end
