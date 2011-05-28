Sector = class('Sector')
function Sector:initialize(play_screen, x, y)
  self.play_screen = play_screen
  self.x = x
  self.y = y

  self.entities = {}
  self.map = self:generate_map()
end

function Sector:generate_map()
  local maps = {}

  for x = 1, self.play_screen.MAP_NUM_CELLS_X do
    local row = {}
    for y = 1, self.play_screen.MAP_NUM_CELLS_Y do
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

function Sector:move(entity, x_offset, y_offset)
  if (self.map[entity.x][entity.y].entity == entity) then
    self.map[entity.x][entity.y].entity = nil
  end
  
  local x = self:clip(entity.x + x_offset, 1, self.play_screen.MAP_NUM_CELLS_X)
  local y = self:clip(entity.y + y_offset, 1, self.play_screen.MAP_NUM_CELLS_Y)

  entity.x = x
  entity.y = y

  self.map[x][y].entity = entity
end

function Sector:clip(i, min, max)
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

