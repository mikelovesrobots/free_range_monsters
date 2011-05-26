-- add a state to that class using addState, and re-define the method
local PlayScreen = ScreenManager:addState('PlayScreen')
PlayScreen.CELL_WIDTH = 10
PlayScreen.CELL_HEIGHT = 15
PlayScreen.MAP_MARGIN_TOP = 10
PlayScreen.MAP_MARGIN_LEFT = 25
PlayScreen.MAP_NUM_CELLS_X = 75
PlayScreen.MAP_NUM_CELLS_Y = 26
PlayScreen.STATS_MARGIN_TOP = 420
PlayScreen.STATS_MARGIN_LEFT = 400
PlayScreen.STREAM_WIDTH = 350
PlayScreen.STREAM_MARGIN_TOP = 420
PlayScreen.STREAM_MARGIN_LEFT = 25

PlayScreen.DIVIDER_X = 400

function PlayScreen:enterState() 
  log("PlayScreen initialized")
  
  local font = love.graphics.newFont("fonts/VeraMono.ttf", 13)
  love.graphics.setFont(font);

  self.player = { forecolor={255,255,255}, character="@", x=10, y=20 }
  self.entities = { self.player }
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
  elseif (key == "h") then
    self.player.x = self.player.x - 1
    self:clip_to_map(self.player)
  elseif (key == "j") then
    self.player.y = self.player.y + 1
    self:clip_to_map(self.player)
  elseif (key == "k") then
    self.player.y = self.player.y - 1
    self:clip_to_map(self.player)
  elseif (key == "l") then
    self.player.x = self.player.x + 1
    self:clip_to_map(self.player)
  elseif (key == "y") then
    self.player.x = self.player.x - 1
    self.player.y = self.player.y - 1
    self:clip_to_map(self.player)
  elseif (key == "u") then
    self.player.x = self.player.x + 1
    self.player.y = self.player.y - 1
    self:clip_to_map(self.player)
  elseif (key == "b") then
    self.player.x = self.player.x - 1
    self.player.y = self.player.y + 1
    self:clip_to_map(self.player)
  elseif (key == "n") then
    self.player.x = self.player.x + 1
    self.player.y = self.player.y + 1
    self:clip_to_map(self.player)
  end
end

function PlayScreen:draw_map()
  love.graphics.setColor(255,218,185)

  for x=1,PlayScreen.MAP_NUM_CELLS_X do
    for y=1,PlayScreen.MAP_NUM_CELLS_Y do
      love.graphics.print(".", self:map_to_pix_x(x), self:map_to_pix_y(y))
    end
  end

  for i,entity in ipairs(self.entities) do
    love.graphics.setColor(entity.forecolor[1], entity.forecolor[2], entity.forecolor[3])
    love.graphics.print(entity.character, self:map_to_pix_x(entity.x), self:map_to_pix_y(entity.y))
  end
end

function PlayScreen:map_to_pix_x(x)
  return (x - 1) * PlayScreen.CELL_WIDTH + PlayScreen.MAP_MARGIN_LEFT
end

function PlayScreen:map_to_pix_y(y)
  return (y - 1) * PlayScreen.CELL_HEIGHT + PlayScreen.MAP_MARGIN_TOP
end

function PlayScreen:clip(i, min, max)
  if (i < min) then
    return min
  elseif (i > max) then
    return max
  else
    return i
  end
end

function PlayScreen:clip_to_map(entity)
  entity.x = self:clip(entity.x, 1, PlayScreen.MAP_NUM_CELLS_X)
  entity.y = self:clip(entity.y, 1, PlayScreen.MAP_NUM_CELLS_Y)
end

function PlayScreen:draw_stream()
  love.graphics.setColor(255,255,255);
  
  local sample_text = "Reached skill level 11 in Construction\n[Salvage] Earned 20 XP\n[Salvage] Earned 15 XP\nFound a handful of nails\nEngineered a board with nails in it\nNoticed a raider\n[Melee] Earned 10 XP\nReached XP level 11";
  
  love.graphics.printf(sample_text, PlayScreen.STREAM_MARGIN_LEFT, PlayScreen.STREAM_MARGIN_TOP, PlayScreen.STREAM_WIDTH, "left");
end

function PlayScreen:draw_stats()
  love.graphics.setColor(255,255,255)
  love.graphics.print("Health: [" .. "**********" .. "] 20/20", PlayScreen.STATS_MARGIN_LEFT, PlayScreen.STATS_MARGIN_TOP)
  love.graphics.print("  Food: [" .. "*****" .. "     " .. "] 20/20", PlayScreen.STATS_MARGIN_LEFT, PlayScreen.STATS_MARGIN_TOP + 20)
  love.graphics.print("  Rads: [" .. "*" .. "         " .. "] 1/10", PlayScreen.STATS_MARGIN_LEFT, PlayScreen.STATS_MARGIN_TOP + 40)
  love.graphics.print("(a) 9mm Semiautomatic Pistol +2/+1", PlayScreen.STATS_MARGIN_LEFT, PlayScreen.STATS_MARGIN_TOP + 80)
  love.graphics.print("        -- 7/9 rounds chambered", PlayScreen.STATS_MARGIN_LEFT, PlayScreen.STATS_MARGIN_TOP + 100)
  love.graphics.print("(b) Board with a nail in it +1/+1", PlayScreen.STATS_MARGIN_LEFT, PlayScreen.STATS_MARGIN_TOP + 120)
end

function PlayScreen:draw_fps()
  love.graphics.setColor(150,150,255)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 2, 2)
end
