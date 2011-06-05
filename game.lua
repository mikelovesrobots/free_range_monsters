-- add a state to that class using addState, and re-define the method
local Game = ScreenManager:addState('Game')
function Game:enterState() 
  debug("Game initialized")
  
  local font = love.graphics.newFont("fonts/VeraMono.ttf", 13)
  love.graphics.setFont(font);

  self.status_messages = {}
end

function Game:draw()
  if self.sector then
    self:draw_map(self)
    self:draw_status_messages(self)
    self:draw_stats(self)
    self:draw_fps(self)
  end
end

function Game:keypressed(key, unicode)
  if (key == "q") then
    self:save_sector()
    screen_manager:popState()
  elseif (self.sector.data.player_turn) then
    local ends_turn = function ()
      self:schedule_event(self.sector.player, "AI", 100)
      self.sector.data.player_turn = false
    end
    if (key == "s") then
      ends_turn()
    elseif (key == "h") then
      self:move_entity(self.sector.player, -1, 0)
      ends_turn()
    elseif (key == "j") then
      self:move_entity(self.sector.player, 0, 1)
      ends_turn()
    elseif (key == "k") then
      self:move_entity(self.sector.player, 0, -1)
      ends_turn()
    elseif (key == "l") then
      self:move_entity(self.sector.player, 1, 0)
      ends_turn()
    elseif (key == "y") then
      self:move_entity(self.sector.player, -1, -1)
      ends_turn()
    elseif (key == "u") then
      self:move_entity(self.sector.player, 1, -1)
      ends_turn()
    elseif (key == "b") then
      self:move_entity(self.sector.player, -1, 1)
      ends_turn()
    elseif (key == "n") then
      self:move_entity(self.sector.player, 1, 1)
      ends_turn()
    else
      debug("unmapped key:" .. key)
    end
  end
end

function Game:start_new_game()
  self:generate_sector()
  self:message("You wake to a nightmare.")
  self:message("Friends, family slaughtered.")
  self:message("All is in flames.")
end

function Game:message(msg)
  table.insert(self.status_messages, msg)
end

function Game:schedule_event(entity, task, ticks)
  local scheduled_time = self.sector.data.current_time + ticks
  local new_job = {entity=entity, task=task, scheduled_time=scheduled_time}
  for i,job in ipairs(self.sector.data.event_queue) do
    if job.scheduled_time > scheduled_time then
      table.insert(self.sector.data.event_queue, i, new_job)
      return
    end
  end

  table.insert(self.sector.data.event_queue, new_job)
end

function Game:process_events()
  while #self.sector.data.event_queue > 0 and not self.sector.data.player_turn do
    self:process_next_event()
  end
end

function Game:process_next_event()
  local job = table.shift(self.sector.data.event_queue)
  if job then
    if job.task == "AI" then
      self:ai(job.entity)
    else
      print("Unknowreturn n task: '" .. job.task .. "'")
    end
    self.sector.data.current_time = job.scheduled_time
  end
end

function Game:ai(entity)
  if (entity.name == "player") then
    self.sector.data.player_turn = true
  elseif (entity.name == "raider") then
    if (self:get_entity_target(entity)) then
      local target = self:get_entity_target(entity)
      local astar_path = self:astar(entity.x, entity.y, target.x, target.y)
      if (astar_path and not table.empty(astar_path)) then
        local next_move = table.shift(astar_path)

        local relative_x = next_move.x - entity.x
        local relative_y = next_move.y - entity.y

        self:move_entity(entity, relative_x, relative_y)
      else
        debug("couldn't find a path")
      end
    else
      debug("couldn't find a target")
    end
    self:schedule_event(entity, "AI", 100)
  elseif (entity.name == "random-walk") then
    self:move_entity(entity, math.random(-1, 1), math.random(-1, 1))
    self:schedule_event(entity, "AI", 100)
  else
    debug("unknown ai for entity: " .. entity.name)
  end
end

function Game:get_entity_target(entity)
  return self.sector.player
end

function Game:astar(sx, sy, dx, dy)
  local visited_map = {}
  for x,row in ipairs(self.sector.data.map) do
    visited_map[x] = {}
    for y,terrain in ipairs(row) do
      visited_map[x][y] = false
    end
  end

  local candidate_stack={{x=sx, y=sy, parent=nil, movement_cost=0}}
  local cells_examined = 0
  visited_map[sx][sy]=true 

  while (not table.empty(candidate_stack)) do
    local candidate = table.pop(candidate_stack)
    cells_examined = cells_examined + 1

    if candidate.x == dx and candidate.y == dy then 
      debug("astar found. cells_examined: " .. cells_examined)
      return self:reconstruct_astar_path(candidate)
    end

    -- find other candidates
    local neighbors = table.select(self:neighboring_squares(candidate.x, candidate.y), function (coordinate)
      -- only keep those which are passable and not already visited
      local terrain = self.sector.data.map[coordinate.x][coordinate.y]
      return(self:terrain_is_passable(terrain) and not visited_map[coordinate.x][coordinate.y])
    end)

    -- put them in the stack in priority of closest to the destination
    table.sort(neighbors, function (a, b) 
      return math.dist(a.x, a.y, dx, dy) > math.dist(b.x, b.y, dx, dy) 
    end)

    -- add the candidates for later processing
    for i,coordinate in ipairs(neighbors) do
      visited_map[coordinate.x][coordinate.y] = true
  
      local new_candidate = {x=coordinate.x, y=coordinate.y, parent=candidate, movement_cost = candidate.movement_cost + 1}
      local inserted = false

      if #candidate_stack > 0 then
        for j, other in ipairs(candidate_stack) do
          if other.movement_cost < new_candidate.movement_cost then
            table.insert(candidate_stack, j, new_candidate)
            inserted = true
            break
          end
        end
      end

      if (not inserted) then
        table.insert(candidate_stack, new_candidate)
      end
    end
  end

  -- unreachable from here
  return nil
end

function Game:reconstruct_astar_path(candidate)
  local cell=candidate
  local path={{x=cell.x, y=cell.y}}
  while (cell.parent) do
    table.unshift(path, {x=cell.parent.x, y=cell.parent.y})
    cell = cell.parent
  end

  -- that first entry contains the starting square
  table.shift(path)

  return path
end

function Game:terrain_is_passable(terrain) 
  return terrain.passable
end

function Game:neighboring_squares(x1,y1)
  local relative_neighbors = {
    {-1,-1}, {0, -1}, {1, -1},
    {-1, 0},          {1, 0},
    {-1, 1}, {0,  1} ,{1, 1}}

  local absolute_neighbors = table.collect(relative_neighbors, function (pair)
    return {x=x1 + pair[1], y=y1 + pair[2]}
  end)

  return table.select(absolute_neighbors, function (coordinate)
    return self:coordinate_inside_map(coordinate)
  end)
end

function Game:coordinate_inside_map(coordinate)
  if (between(coordinate.x, 1, #self.sector.data.map)) then
    return between(coordinate.y, 1, #self.sector.data.map[coordinate.x])
  else
    return false
  end
end

function Game:update(dt)
  if self.sector.data.event_queue and not self.sector.data.player_turn then
    local status, err = pcall(function()
      self:process_events()
    end)

    if not status then debug(err) end
  end
end

function Game:destroy_saves()
  debug("removing saves... oh please don't delete anything important")
  rmdir("saves")
end

function Game:save_sector()
  mkdir("saves")

  local out = assert(io.open(sector_filename(self.sector.data.x, self.sector.data.y), "w"))
  out:write(json.encode(self.sector.data))
  io.close(out)
end

function Game:load_sector()
  local infile = assert(io.open(sector_filename(0,0), "r"), "Failed to open input file")
  local injson = infile:read("*a")
  
  self.sector = {}
  self.sector.data = json.decode(injson)
  sector_index(self.sector)
end


function Game:generate_sector()
  -- add monsters, the player and the map
  local monster1 = create_entity("raider", 50, 20)
  local monster2 = create_entity("raider", 55, 10)
  local monster3 = create_entity("raider", 56, 15)
  local monster4 = create_entity("raider", 57, 25)
  local monster5 = create_entity("raider", 58, 22)
  local player = create_entity("player", 10, 10)

  self.sector = {
    player=player,
    entities={player, monster1, monster2, monster3, monster4, monster5},
    data={
      current_time=0,
      event_queue={},
      player_turn=false,
      x=0,
      y=0,
      map=generate_map()
    }
  }

  for i, v in ipairs(self.sector.entities) do
    self:move_entity(v, 0, 0)
    self:schedule_event(v, "AI", 100)
  end
  
end

function sector_filename(x, y)
  return "saves/sector-" .. x .. "-" .. y .. ".json"
end

function sector_index(sector)
  sector.entities = {}

  for x,row in ipairs(sector.data.map) do
    for y,terrain in ipairs(row) do
      if terrain.entity then
        table.insert(sector.entities, terrain.entity)
        
        if terrain.entity.name == "player" then
          sector.player = terrain.entity
        end
      end
    end
  end
end

function Game:draw_map()
  for x,row in ipairs(self.sector.data.map) do
    for y,terrain in ipairs(row) do
      local forecolor = terrain_top_forecolor(terrain)
      love.graphics.setColor(forecolor[1], forecolor[2], forecolor[3])
      love.graphics.print(terrain_top_character(terrain), self:map_to_pix_x(x), self:map_to_pix_y(y))
    end
  end
end

function Game:map_to_pix_x(x)
  return (x - 1) * app.config.CELL_WIDTH + app.config.MAP_MARGIN_LEFT
end

function Game:map_to_pix_y(y)
  return (y - 1) * app.config.CELL_HEIGHT + app.config.MAP_MARGIN_TOP
end

function Game:draw_status_messages()
  love.graphics.setColor(255,255,255);
  
  local text = ''

  local start_index = clip(#self.status_messages - 10, 1, #self.status_messages)
  for index = start_index, #self.status_messages do
    text = text .. self.status_messages[index] .. "\n"
  end

  love.graphics.printf(text, app.config.STREAM_MARGIN_LEFT, app.config.STREAM_MARGIN_TOP, app.config.STREAM_WIDTH, "left");
end

function Game:draw_stats()
  love.graphics.setColor(255,255,255)

  local stats = {
    text_indicator("Health", self.sector.player.health, self.sector.player.max_health),
    text_indicator("  Food", 10, 20),
    text_indicator("  Rads", 0, 20),
    "(a) 9mm Semiautomatic Pistol +2/+1",
    "        -- 7/9 rounds chambered",
    "(b) Board with a nail in it +1/+1",
    "Current Time: " .. self.sector.data.current_time
  }

  for i,text in ipairs(stats) do
    love.graphics.print(text, app.config.STATS_MARGIN_LEFT, app.config.STATS_MARGIN_TOP + (20 * (i - 1)))
  end
end

function text_indicator(label, current, max)
  local calc_stars = function () 
    local result = ''

    local num_stars = math.floor(current / max * 10)
    local num_spaces = 10 - num_stars

    for i = 1, num_stars do
      result = result .. "*"
    end

    for i = 1, num_spaces do
      result = result .. " "
    end

    return result
  end

  return label ..": [" .. calc_stars() .. "] " .. current .. "/" .. max
end

function Game:draw_fps()
  love.graphics.setColor(150,150,255)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 2, 2)
end


function Game:move_entity(entity, x_offset, y_offset)
  local x = clip(entity.x + x_offset, 1, app.config.MAP_NUM_CELLS_X)
  local y = clip(entity.y + y_offset, 1, app.config.MAP_NUM_CELLS_Y)

  local map = self.sector.data.map

  if self:terrain_is_passable(map[x][y]) then
    local enemy = map[x][y].entity
    if enemy then
      if self:accuracy_check(entity, enemy) then
        self:message(entity.name .. " hits " .. enemy.name)
        self:damage_entity(enemy, 1)
      else
        self:message(entity.name .. " misses " .. enemy.name)
      end
    else
      map[entity.x][entity.y].entity = nil
      
      entity.x = x
      entity.y = y

      map[x][y].entity = entity
    end
  else
    debug("goddamn, this terrain isn't passable")
  end
end

function Game:accuracy_check(entity, enemy)
  return 100 - math.random(1,100) > 70
end

function Game:damage_entity(entity, points)
  entity.health = entity.health - points
  if self:is_entity_dead(entity) then
    if self.sector.player == entity then
      debug("player died")
      self:destroy_saves()

      screen_manager:popState()
      screen_manager:pushState("DeadScreen")


      -- throw the mother of all exceptions
      error("player has died")
    else
      debug("enemy died")
      self:message(entity.name .. " was killed")
      self:remove_entity(entity)
    end
  end
end

function Game:is_entity_dead(entity)
  return entity.health < 1
end

function Game:remove_entity(entity)
  self.sector.data.map[entity.x][entity.y].entity = nil
  self.sector.entities = table.reject(self.sector.entities, function(x) return entitiy == x end)
end

-- returns a random map
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
        if (x == 13) then
          if math.random(1,10) == 1 then
            table.insert(row, create_terrain("rubble"))
          else
            table.insert(row, create_terrain("rock"))
          end
        else
          if math.random(1,10) == 1 then
            table.insert(row, create_terrain("rubble"))
          elseif math.random(1,30) == 1 then
            table.insert(row, create_terrain("rock"))
          else
            table.insert(row, create_terrain("dirt"))
          end
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
      forecolor={246,235,187},
      passable=true
    }
  elseif name == "lane marker" then
    return {
      name="lane marker",
      character=':',
      forecolor={248,202,0},
      passable=true
    }
  elseif name == "dirt" then
    return {
      name="dirt",
      character='.',
      forecolor={221,78,35},
      passable=true
    }
  elseif name == "rubble" then
    return {
      name="rubble",
      character='~',
      forecolor={221,78,35},
      passable=true
    }
  elseif name == "rock" then
    return {
      name="rock",
      character='^',
      forecolor={162,165,108},
      passable=false
    }
  else
    print("unknown terrain type: " .. name)
  end
end

function create_entity(type, x, y)
  local base = {
    x=x,
    y=y
  }
  if type == "raider" then
    return table.merge(base, {
      name="raider",
      character="@",
      forecolor={246,235,187},
      max_health=10,
      health=10
    })
  elseif type == "player" then
    return table.merge(base, {
      name="player",
      character="@",
      forecolor={120,203,255},
      max_health=20,
      health=18
    })
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

