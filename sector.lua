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
      table.insert(row, Terrain:new())
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


