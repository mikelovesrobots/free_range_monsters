-- add a state to that class using addState, and re-define the method
local PlayScreen = ScreenManager:addState('PlayScreen')
PlayScreen.CELL_WIDTH = 10
PlayScreen.CELL_HEIGHT = 15
PlayScreen.MAP_MARGIN_TOP = 10
PlayScreen.MAP_MARGIN_LEFT = 25
PlayScreen.MAP_NUM_CELLS_X = 75
PlayScreen.MAP_NUM_CELLS_Y = 21

PlayScreen.DIVIDER_X = 400

function PlayScreen:enterState() 
  log("PlayScreen initialized")
  
  local font = love.graphics.newFont("fonts/VeraMono.ttf", 13)
  love.graphics.setFont(font);
end

function PlayScreen:draw()
  self:draw_map(self)
  self:draw_stream(self)
  self:draw_stats(self)
  self:draw_fps(self)
end

function PlayScreen:keypressed(key, unicode)
  if (key == "q") then
    screen_manager:popState()
  end
end

function PlayScreen:draw_map()
  love.graphics.setColor(255,218,185)

  for x=1,PlayScreen.MAP_NUM_CELLS_X do
    for y=1,PlayScreen.MAP_NUM_CELLS_Y do
      local pix_x = (x - 1) * PlayScreen.CELL_WIDTH + PlayScreen.MAP_MARGIN_LEFT
      local pix_y = (y - 1) * PlayScreen.CELL_HEIGHT + PlayScreen.MAP_MARGIN_TOP

      love.graphics.print(".", pix_x, pix_y)
    end
  end
end

function PlayScreen:draw_stream()
  love.graphics.setColor(255,255,255);
  
  local sample_text = "Reached skill level 11 in Street Fighting\nEarned 20 XP\nLearned a level 5 spell: Blades of Dooooooooom\nReached skill level 10 in Transmutations\nReached skill level 12 in Unarmed Combat\nNoticed Erica\nReached skill level 11 in Unarmed Combat\nReached XP level 11. HP: 79/79 MP: 17/21\nLearned a level 5 spell: Blade Hands\nReached skill level 10 in Transmutations\nReached skill level 12 in Unarmed Combat\nNoticed Erica";
  
  love.graphics.printf(sample_text, PlayScreen.MAP_MARGIN_LEFT, 350, 400, "left");
end

function PlayScreen:draw_stats()
  love.graphics.setColor(255,255,255);
  love.graphics.print("Health: [" .. "**********" .. "] 20/20", PlayScreen.DIVIDER_X + PlayScreen.MAP_MARGIN_LEFT, 350);
  love.graphics.print("  Food: [" .. "*****" .. "     " .. "] 20/20", PlayScreen.DIVIDER_X + PlayScreen.MAP_MARGIN_LEFT, 370);
  love.graphics.print("  Rads: [" .. "*" .. "         " .. "] 1/10", PlayScreen.DIVIDER_X + PlayScreen.MAP_MARGIN_LEFT, 390);
  love.graphics.print("(a) 9mm Semiautomatic Pistol +2/+1", PlayScreen.DIVIDER_X + PlayScreen.MAP_MARGIN_LEFT, 430); 
  love.graphics.print("        -- 7/9 rounds chambered", PlayScreen.DIVIDER_X + PlayScreen.MAP_MARGIN_LEFT, 450); 
  love.graphics.print("(b) Board with a nail in it +1/+1", PlayScreen.DIVIDER_X + PlayScreen.MAP_MARGIN_LEFT, 470); 
end

function PlayScreen:draw_fps()
  love.graphics.setColor(150,150,255);
  love.graphics.print("FPS: " .. love.timer.getFPS(), 2, 2)
end
