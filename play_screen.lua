-- add a state to that class using addState, and re-define the method
local PlayScreen = ScreenManager:addState('PlayScreen')

function PlayScreen:enterState() 
  debug("PlayScreen initialized")
  
  local font = love.graphics.newFont("fonts/VeraMono.ttf", 13)
  love.graphics.setFont(font);

  self.status_messages = {}
end

function PlayScreen:draw()
  if self.sector then
    self:draw_map(self)
    self:draw_status_messages(self)
    self:draw_stats(self)
    self:draw_fps(self)
  end
end

function PlayScreen:keypressed(key, unicode)
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
      map_entity_move(self.sector.data.map, self.sector.player, -1, 0)
      ends_turn()
    elseif (key == "j") then
      map_entity_move(self.sector.data.map, self.sector.player, 0, 1)
      ends_turn()
    elseif (key == "k") then
      map_entity_move(self.sector.data.map, self.sector.player, 0, -1)
      ends_turn()
    elseif (key == "l") then
      map_entity_move(self.sector.data.map, self.sector.player, 1, 0)
      ends_turn()
    elseif (key == "y") then
      map_entity_move(self.sector.data.map, self.sector.player, -1, -1)
      ends_turn()
    elseif (key == "u") then
      map_entity_move(self.sector.data.map, self.sector.player, 1, -1)
      ends_turn()
    elseif (key == "b") then
      map_entity_move(self.sector.data.map, self.sector.player, -1, 1)
      ends_turn()
    elseif (key == "n") then
      map_entity_move(self.sector.data.map, self.sector.player, 1, 1)
      ends_turn()
    else
      debug("unmapped key:" .. key)
    end
  end
end

function PlayScreen:start_new_game()
  self:generate_sector()
  self:log("You wake to a nightmare.")
  self:log("Friends, family slaughtered.")
  self:log("All is in flames.")
end

function PlayScreen:log(msg)
  table.insert(self.status_messages, msg)
end

function PlayScreen:schedule_event(entity, task, ticks)
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

function PlayScreen:process_events()
  while #self.sector.data.event_queue > 0 and not self.sector.data.player_turn do
    self:process_next_event()
  end
end

function PlayScreen:process_next_event()
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

function PlayScreen:ai(entity)
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

        map_entity_move(self.sector.data.map, entity, relative_x, relative_y)
      else
        debug("couldn't find a path")
      end
    else
      debug("couldn't find a target")
    end
    self:schedule_event(entity, "AI", 100)
  elseif (entity.name == "random-walk") then
    map_entity_move(self.sector.data.map, entity, math.random(-1, 1), math.random(-1, 1))
    self:schedule_event(entity, "AI", 100)
  else
    debug("unknown ai for entity: " .. entity.name)
  end
end

function PlayScreen:get_entity_target(entity)
  return self.sector.player
end

function PlayScreen:astar(sx, sy, dx, dy)
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
      return reconstruct_astar_path(candidate)
    end

    -- find other candidates
    local neighbors = table.select(neighboring_squares(candidate.x, candidate.y), function (cell)
      if xy_inside_map(self.sector.data.map, cell.x, cell.y) then
        -- only keep those which are passable and not already visited
        local terrain = self.sector.data.map[cell.x][cell.y]
        return(terrain_is_passable(terrain) and not visited_map[cell.x][cell.y])
      else
        return false
      end
    end)

    -- put them in the stack in priority of closest to the destination
    table.sort(neighbors, function (a, b) 
      return math.dist(a.x, a.y, dx, dy) > math.dist(b.x, b.y, dx, dy) 
    end)

    -- add the candidates for later processing
    for i,cell in ipairs(neighbors) do
      visited_map[cell.x][cell.y] = true
  
      local new_candidate = {x=cell.x, y=cell.y, parent=candidate, movement_cost = candidate.movement_cost + 1}
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

function xy_inside_map(map, x, y)
  if (between(x, 1, #map)) then
    return between(y, 1, #map[x])
  else
    return false
  end
end

function reconstruct_astar_path(candidate)
  local path = {}

  local cell=candidate
  while (cell.parent) do
    table.unshift(path, {x=cell.parent.x, y=cell.parent.y})
    cell = cell.parent
  end

  -- that first entry contains the starting square
  table.shift(path)

  return path
end

function terrain_is_passable(terrain) 
  return terrain.passable -- and not terrain.entity
end

function neighboring_squares(x1,y1)
  local relative_neighbors = {
    {-1,-1}, {0, -1}, {1, -1},
    {-1, 0},          {1, 0},
    {-1, 1}, {0,  1} ,{1, 1}}

  return table.collect(relative_neighbors, function (pair)
    return {x=x1 + pair[1], y=y1 + pair[2]}
  end)
end

function PlayScreen:update(dt)
  if (self.sector.data.event_queue and not self.sector.data.player_turn) then
    self:process_events() 
  end
end

function PlayScreen:save_sector()
  mkdir("saves")

  local out = assert(io.open(sector_filename(self.sector.data.x, self.sector.data.y), "w"))
  out:write(json.encode(self.sector.data))
  io.close(out)
end

function PlayScreen:load_sector()
  local infile = assert(io.open(sector_filename(0,0), "r"), "Failed to open input file")
  local injson = infile:read("*a")
  
  self.sector = {}
  self.sector.data = json.decode(injson)
  sector_index(self.sector)
end


function PlayScreen:generate_sector()
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
    map_entity_move(self.sector.data.map, v, 0, 0)
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

function PlayScreen:draw_map()
  for x,row in ipairs(self.sector.data.map) do
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

function PlayScreen:draw_status_messages()
  love.graphics.setColor(255,255,255);
  
  local text = ''

  local start_index = clip(#self.status_messages - 10, 1, #self.status_messages)
  for index = start_index, #self.status_messages do
    text = text .. self.status_messages[index] .. "\n"
  end

  love.graphics.printf(text, app.config.STREAM_MARGIN_LEFT, app.config.STREAM_MARGIN_TOP, app.config.STREAM_WIDTH, "left");
end

function PlayScreen:draw_stats()
  love.graphics.setColor(255,255,255)

  local stats = {
    text_indicator("Health", self.sector.player.current_hp, self.sector.player.max_hp),
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

function PlayScreen:draw_fps()
  love.graphics.setColor(150,150,255)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 2, 2)
end


function map_entity_move(map, entity, x_offset, y_offset)
  local x = clip(entity.x + x_offset, 1, app.config.MAP_NUM_CELLS_X)
  local y = clip(entity.y + y_offset, 1, app.config.MAP_NUM_CELLS_Y)

  if (terrain_is_passable(map[x][y])and not map[x][y].entity) then
    map[entity.x][entity.y].entity = nil
    
    entity.x = x
    entity.y = y

    map[x][y].entity = entity
  end
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
      max_hp=10,
      current_hp=10
    })
  elseif type == "player" then
    return table.merge(base, {
      name="player",
      character="@",
      forecolor={120,203,255},
      max_hp=20,
      current_hp=18
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

