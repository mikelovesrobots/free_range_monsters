-- add a state to that class using addState, and re-define the method
local PlayScreen = ScreenManager:addState('PlayScreen')

function PlayScreen:enterState() 
  log("PlayScreen initialized")
  
  local font = love.graphics.newFont("fonts/VeraMono.ttf", 13)
  love.graphics.setFont(font);

  self.player = { forecolor={120,203,255}, character="@", x=10, y=10 }

  self.sector = {
    entities=self.player,
    x=0,
    y=0,
    map=generate_map()
  }
  map_entity_move(self.sector.map, self.player, 0, 0)
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
    mkdir("saves")
    -- print(json:encode(1))
  elseif (key == "h") then
    map_entity_move(self.sector.map, self.player, -1, 0)
  elseif (key == "j") then
    map_entity_move(self.sector.map, self.player, 0, 1)
  elseif (key == "k") then
    map_entity_move(self.sector.map, self.player, 0, -1)
  elseif (key == "l") then
    map_entity_move(self.sector.map, self.player, 1, 0)
  elseif (key == "y") then
    map_entity_move(self.sector.map, self.player, -1, -1)
  elseif (key == "u") then
    map_entity_move(self.sector.map, self.player, 1, -1)
  elseif (key == "b") then
    map_entity_move(self.sector.map, self.player, -1, 1)
  elseif (key == "n") then
    map_entity_move(self.sector.map, self.player, 1, 1)
  end
end

function PlayScreen:draw_map()

  for x,row in ipairs(self.sector.map) do
    for y,terrain in ipairs(row) do
      local forecolor = terrain_top_forecolor(terrain)
      love.graphics.setColor(forecolor[1], forecolor[2], forecolor[3])
      love.graphics.print(terrain_top_character(terrain), self:map_to_pix_x(x), self:map_to_pix_y(y))
    end
  end
end

function PlayScreen:map_to_pix_x(x)
  return (x - 1) * app.config.CELL_WIDTH + app.config.MAP_MARGIN_LEFT
end

function PlayScreen:map_to_pix_y(y)
  return (y - 1) * app.config.CELL_HEIGHT + app.config.MAP_MARGIN_TOP
end

function PlayScreen:draw_stream()
  love.graphics.setColor(255,255,255);
  
  local sample_text = "Reached skill level 11 in Construction\n[Salvage] Earned 20 XP\n[Salvage] Earned 15 XP\nFound a handful of nails\nEngineered a board with nails in it\nNoticed a raider\n[Melee] Earned 10 XP\nReached XP level 11";
  
  love.graphics.printf(sample_text, app.config.STREAM_MARGIN_LEFT, app.config.STREAM_MARGIN_TOP, app.config.STREAM_WIDTH, "left");
end

function PlayScreen:draw_stats()
  love.graphics.setColor(255,255,255)
  love.graphics.print("Health: [" .. "**********" .. "] 20/20", app.config.STATS_MARGIN_LEFT, app.config.STATS_MARGIN_TOP)
  love.graphics.print("  Food: [" .. "*****" .. "     " .. "] 20/20", app.config.STATS_MARGIN_LEFT, app.config.STATS_MARGIN_TOP + 20)
  love.graphics.print("  Rads: [" .. "*" .. "         " .. "] 1/10", app.config.STATS_MARGIN_LEFT, app.config.STATS_MARGIN_TOP + 40)
  love.graphics.print("(a) 9mm Semiautomatic Pistol +2/+1", app.config.STATS_MARGIN_LEFT, app.config.STATS_MARGIN_TOP + 80)
  love.graphics.print("        -- 7/9 rounds chambered", app.config.STATS_MARGIN_LEFT, app.config.STATS_MARGIN_TOP + 100)
  love.graphics.print("(b) Board with a nail in it +1/+1", app.config.STATS_MARGIN_LEFT, app.config.STATS_MARGIN_TOP + 120)
end

function PlayScreen:draw_fps()
  love.graphics.setColor(150,150,255)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 2, 2)
end


function map_entity_move(map, entity, x_offset, y_offset)
  if (map[entity.x][entity.y].entity == entity) then
    map[entity.x][entity.y].entity = nil
  end
  
  local x = clip(entity.x + x_offset, 1, app.config.MAP_NUM_CELLS_X)
  local y = clip(entity.y + y_offset, 1, app.config.MAP_NUM_CELLS_Y)

  entity.x = x
  entity.y = y

  map[x][y].entity = entity
end

function generate_map()
  local maps = {}

  for x = 1, app.config.MAP_NUM_CELLS_X do
    local row = {}
    for y = 1, app.config.MAP_NUM_CELLS_Y do
      if x == 20 or x == 21 or x == 23 or x == 24 then
        table.insert(row, create_terrain("road"))
      elseif x == 22 then
        if y % 2 == 1 and math.random(1,4) <= 3 then
          table.insert(row, create_terrain("lane marker"))
        else 
          table.insert(row, create_terrain("road"))
        end
      elseif (x == 19 or x == 25) and math.random(1,4) <= 3 then
        table.insert(row, create_terrain("road"))
      else
        if math.random(1,10) == 1 then
          table.insert(row, create_terrain("rock"))
        else
          table.insert(row, create_terrain("rubble"))
        end
      end
    end
    table.insert(maps, row)
  end

  return(maps)
end

function clip(i, min, max)
  if (i < min) then
    return min
  elseif (i > max) then
    return max
  else
    return i
  end
end


function create_terrain(name)
  if name == "road" then
    return {
      name="road",
      character='|',
      forecolor={246,235,187}
    }
  elseif name == "lane marker" then
    return {
      name="lane marker",
      character=':',
      forecolor={248,202,0}
    }
  elseif name == "rubble" then
    return {
      name="rubble",
      character='.',
      forecolor={221,78,35} -- {162,165,108}
    }
  elseif name == "rock" then
    return {
      name="rock",
      character='~',
      forecolor={221,78,35}
    }
  else
    print("unknown terrain type: " .. name)
  end
end

function terrain_top_character(terrain)
  return terrain_top_entity(terrain).character
end

function terrain_top_forecolor(terrain)
  return terrain_top_entity(terrain).forecolor
end

function terrain_top_entity(terrain)
  return terrain.entity or terrain
end

