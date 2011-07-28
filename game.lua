-- add a state to that class using addState, and re-define the method
local Game = ScreenManager:addState('Game')
function Game:enterState()
  debug("Game initialized")

  local font = love.graphics.newFont("fonts/VeraMono.ttf", 13)
  love.graphics.setFont(font);

  self.status_messages = {}
  self.effects_queue = {}
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
      if (math.random(1,5) == 1) then
        self:gain_health(self.sector.player, 1)
      end

      self:schedule_event(self.sector.player, "AI", 100)
      self.sector.data.player_turn = false
    end
    if (key == "s") then
      ends_turn()
    elseif (key == "h" or key == "left") then
      self:move_entity(self.sector.player, -1, 0)
      ends_turn()
    elseif (key == "j" or key == "down") then
      self:move_entity(self.sector.player, 0, 1)
      ends_turn()
    elseif (key == "k" or key == "up") then
      self:move_entity(self.sector.player, 0, -1)
      ends_turn()
    elseif (key == "l" or key == "right") then
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
    elseif (key == "x") then
      self:level_up()
    elseif (key == "/") then
      screen_manager:pushState("HelpScreen")
    else
      debug("unmapped key:" .. key)
    end
  end
end

function Game:start_new_game()
  self:generate_sector()
  self:level_up()
  self:level_up()
  self:level_up()
  self:level_up()
end

function Game:level_up()
  self.sector.player.evolution_credits = self.sector.player.evolution_credits + 1

  screen_manager:pushState("LevelUpScreen")

  self.sector.player.level = self.sector.player.level + 1
  self:gain_health(self.sector.player, self.sector.player.max_health)
  self.sector.player.xp = 0
  self.sector.player.max_xp = 10 * self.sector.player.level
end

function Game:flavor_message(name, vars)
  local flavor_text = flavor_text_db:create(name, vars)
  self:message(flavor_text)
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
  if (entity.ai == "player") then
    self.sector.data.player_turn = true
  elseif (entity.ai == "hostile") then
    if (self:get_entity_target(entity)) then
      local target = self:get_entity_target(entity)
      local astar_path = self:astar(entity.x, entity.y, target.x, target.y)
      if (astar_path and not table.empty(astar_path)) then
        local next_move = table.shift(astar_path)

        local relative_x = next_move.x - entity.x
        local relative_y = next_move.y - entity.y

        self:move_entity(entity, relative_x, relative_y)
      else
        --debug("couldn't find a path")
      end
    else
      --debug("couldn't find a target")
    end
    self:schedule_event(entity, "AI", 100)
  elseif (entity.ai == "random-walk") then
    self:move_entity(entity, math.random(-1, 1), math.random(-1, 1))
    self:schedule_event(entity, "AI", 100)
  else
    debug("unknown ai for entity: " .. entity.name)
  end
end

function Game:get_entity_target(entity)
  local nearby_entities = self:entities_nearby(entity, 10)
  if table.present(nearby_entities) then
    local hostiles = table.reject(nearby_entities, function(target)
      return target.allegiance == entity.allegiance
    end)

    if #hostiles > 0 then
      return hostiles[1]
    else
      return nil
    end
  else
    return nil
  end
end

function Game:entities_nearby(entity, range)
  local results = table.select(self.sector.entities, function(target)
    return (math.dist(entity.x, entity.y, target.x, target.y) <= range) and (target ~= entity)
  end)

  return results
end

function Game:astar(sx, sy, dx, dy)
  local visited_map = self:create_empty_boolean_map()
  local cells_examined = 0
  local open_list={{x=sx, y=sy, parent=nil, f=math.dist(sx,sy,dx,dy), g=0, h=math.dist(sx,sy,dx,dy)}}

  while table.present(open_list) do
    local candidate = table.shift(open_list)

    cells_examined = cells_examined + 1
    if cells_examined > 100 then
      debug("astar: examined " .. cells_examined .. " cells, bailing!")
      return nil
    end

    if candidate.x == dx and candidate.y == dy then
      debug("astar found. cells_examined: " .. cells_examined)
      return self:reconstruct_astar_path(candidate)
    end

    visited_map[candidate.x][candidate.y] = true

    local neighbors = table.select(self:neighboring_coordinates(candidate.x, candidate.y), function (coordinate)
      -- only keep those which are passable and not already visited
      local terrain = self.sector.data.map[coordinate.x][coordinate.y]
      return(
        self:terrain_is_passable(terrain) and
        not visited_map[coordinate.x][coordinate.y] and
        not (terrain.entity and not(dx == coordinate.x and dy == coordinate.y)))
    end)

    table.each(neighbors, function(coord)
                            local b = {x=coord.x, y=coord.y, g=candidate.g + 1, h=math.dist(coord.x,coord.y,dx,dy), parent=candidate}
                            b.f = b.g + b.h

                            local inserted = false
                            for i, other in ipairs(open_list) do
                              if other.f > b.f then
                                table.insert(open_list, i, b)
                                inserted = true
                                break
                              end
                            end

                            if not inserted then
                              table.push(open_list, b)
                            end
                          end)
  end

  -- unreachable from here
  debug("astar gave up after " .. cells_examined .. " cells examined")
  return nil
end

function Game:create_empty_boolean_map()
  local map = {}
  for x,row in ipairs(self.sector.data.map) do
    map[x] = {}
    for y,terrain in ipairs(row) do
      map[x][y] = false
    end
  end
  return map
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

function Game:nearest_walkable_empty_coordinate(x,y)
  local candidates = {{x=x,y=y}}
  local visited_map = self:create_empty_boolean_map()

  local candidates_examined = 0
  while (table.present(candidates)) do
    candidates_examined = candidates_examined + 1
    local candidate = table.pop(candidates)
    local terrain = self.sector.data.map[candidate.x][candidate.y]
    if (self:terrain_is_passable(terrain)) then
      return candidate
    else
      for i,neighboring_coord in ipairs(self:neighboring_coordinates(candidate.x, candidate.y)) do
        if (not(visited_map[candidate.x][candidate.y] or table.detect(candidates, function(coord) return coord.x == neighboring_coord.x and coord.y == neighboring_coord.y end))) then
          table.unshift(candidates, neighboring_coord)
        end
      end

      visited_map[candidate.x][candidate.y] = true
    end
  end

  return nil
end

function Game:terrain_is_passable(terrain)
  return terrain.passable
end

function Game:neighboring_coordinates(x1,y1)
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

function Game:neighboring_terrain(x,y)
  return table.collect(self:neighboring_coordinates(x, y), function (coordinate)
    return self.sector.data.map[coordinate.x][coordinate.y]
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
  self:expire_effects(dt)

  if self.sector.data.event_queue and not self.sector.data.player_turn then
    local status, err = pcall(function()
      self:process_events()
    end)

    if not status then debug(err) end
  end
end

function Game:expire_effects(dt)
  table.each(self.effects_queue, function (effect) effect.time = effect.time - dt end)
  local expired_effects, live_effects = table.partition(self.effects_queue, function (x) return x.time < 0 end)
  self.effects_queue = live_effects
  table.each(expired_effects, function (effect) effect.entity.effect = nil end)
end

function Game:destroy_saves()
  debug("removing saves... oh please don't delete anything important")
  love.filesystem.remove(sector_filename(0,0))
end

function Game:save_sector()
  love.filesystem.mkdir("saves")
  local path = sector_filename(self.sector.data.x, self.sector.data.y)
  love.filesystem.write(path, json.encode(self.sector.data))
end

function Game:load_sector()
  self.sector = {}

  local data = love.filesystem.read(sector_filename(0,0))
  self.sector.data = json.decode(data)

  sector_index(self.sector)
end


function Game:generate_sector()
  -- add monsters, the player and the map
  local monster1 = create_entity("raider")
  local monster2 = create_entity("raider")
  local monster3 = create_entity("bruiser")
  local monster4 = create_entity("bruiser")
  local monster5 = create_entity("bruiser")
  local monster6 = create_entity("bruiser")
  local monster7 = create_entity("bruiser")
  local player = create_entity("player")
  local entities = {player, monster1, monster2, monster3, monster4, monster5, monster6, monster7}

  self.sector = {
    player=player,
    entities={},
    data={
      current_time=0,
      event_queue={},
      player_turn=false,
      x=0,
      y=0,
      map=generate_map()
    }
  }

  table.each(entities,
             function(entity)
               self:place_entity(entity, math.random(1, app.config.MAP_NUM_CELLS_X), math.random(1, app.config.MAP_NUM_CELLS_Y))
             end)
end

function Game:place_entity(entity, x, y)
  local coordinate = self:nearest_walkable_empty_coordinate(x,y)
  entity.x = coordinate.x
  entity.y = coordinate.y

  table.push(self.sector.entities, entity)
  self:move_entity(entity, 0, 0)
  self:schedule_event(entity, "AI", 100)
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


      if (math.dist(x,y,self.sector.player.x,self.sector.player.y) < 10) then
        terrain.seen = true
        love.graphics.setColor(forecolor[1], forecolor[2], forecolor[3])
        love.graphics.print(terrain_top_character(terrain), self:map_to_pix_x(x), self:map_to_pix_y(y))
      elseif (terrain.seen) then
        local monochrome = (forecolor[1] + forecolor[2] + forecolor[3]) / 3 - 20
        love.graphics.setColor(monochrome, monochrome, monochrome)
        love.graphics.print(terrain.character, self:map_to_pix_x(x), self:map_to_pix_y(y))
      end
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

  local start_index = clip(#self.status_messages - 8, 1, #self.status_messages)
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
    text_indicator("    XP", self.sector.player.xp, self.sector.player.max_xp),
  }

  table.push(stats, "Current Time: " .. self.sector.data.current_time)
  table.push(stats, "       Level: " .. self.sector.player.level)

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
      self:attack(entity, enemy)
    else
      map[entity.x][entity.y].entity = nil

      entity.x = x
      entity.y = y

      map[x][y].entity = entity

      if entity == self.sector.player and map[x][y].item then
        self:flavor_message("see_item", {item_name=map[x][y].item.name})
      end
    end
  else
    debug("goddamn, this terrain isn't passable")
  end
end

function Game:attack(entity, enemy)
  if self:accuracy_check(entity, enemy) then
    self:flavor_message("unarmed_hit", {entity_name=entity.name, enemy_name=enemy.name})
    local armor_absorption = math.random(enemy.armor / 2, enemy.armor)
    if entity.muscle > armor_absorption then
      self:damage_entity(entity, enemy, entity.muscle - armor_absorption)
    else
      self:flavor_message("unarmed_absorbed", {entity_name=entity.name, enemy_name=enemy.name})
    end
  else
    self:flavor_message("unarmed_miss", {entity_name=entity.name, enemy_name=enemy.name})
  end
end

function Game:gain_health(entity, health)
  if entity.health + health > entity.max_health then
    entity.health = entity.max_health
  else
    entity.health = entity.health + health
  end
end

function Game:accuracy_check(entity, enemy)
  return math.random(1,100) > 100 - 70
end

function Game:damage_entity(entity, enemy, points)
  enemy.health = enemy.health - points

  local pct = enemy.health / enemy.max_health
  enemy.effect = {character="*"}
  if pct <= 0.20 then
    enemy.effect.forecolor = {232, 87, 76}
  elseif pct > 0.20 and pct <= 0.40 then
    enemy.effect.forecolor = {242, 123, 41}
  elseif pct > 0.40 and pct <= 0.60 then
    enemy.effect.forecolor = {229, 165, 27}
  elseif pct > 0.60 and pct <= 0.80 then
    enemy.effect.forecolor = {217, 204, 60}
  elseif pct > 0.80 and pct <= 0.95 then
    enemy.effect.forecolor = {57, 153, 119}
  elseif pct > 0.95 then
    enemy.effect.forecolor = {255, 255, 255}
  end
  self:add_effect(enemy, 0.5)

  if self:is_entity_dead(enemy) then
    if self.sector.player == enemy then
      debug("player died")
      self:destroy_saves()

      screen_manager:popState()
      screen_manager:pushState("DeadScreen")

      -- throw the mother of all exceptions
      error("player has died")
    else
      debug("enemy died")
      self:message(enemy.name .. " was killed")
      self:remove_entity(enemy)
      if (entity == self.sector.player) then
        self:award_xp(enemy.level * 2)
      end
    end
  end
end

function Game:award_xp(xp)
  self.sector.player.xp = self.sector.player.xp + xp
  if self.sector.player.xp >= self.sector.player.max_xp then
    self:level_up()
  end
end

function Game:add_effect(entity, time)
  table.insert(self.effects_queue, {entity=entity, time=time})
end

function Game:is_entity_dead(entity)
  return entity.health < 1
end

function Game:remove_entity(entity)
  self.sector.data.map[entity.x][entity.y].entity = nil
  self.sector.entities = table.reject(self.sector.entities, function(x) return entity == x end)
  self.sector.data.event_queue = table.reject(self.sector.data.event_queue, function(job)
    return job.entity == entity
  end)
end

-- returns a random map
function generate_map()
  return add_random_crypt(generate_biome())
end

function generate_biome()
  local map = {}
  for x = 1, app.config.MAP_NUM_CELLS_X do
    local row = {}
    for y = 1, app.config.MAP_NUM_CELLS_Y do
      if math.random(1,10) == 1 then
        table.insert(row, create_terrain("rubble"))
      elseif math.random(1,30) == 1 then
        table.insert(row, create_terrain("rock"))
      else
        table.insert(row, create_terrain("dirt"))
      end
    end
    table.insert(map, row)
  end

  return map
end

function add_random_crypt(map)
  local random_crypt_name = table.random(table.keys(crypts_db.db))
  debug("adding " .. random_crypt_name .. " crypt")
  local crypt = create_crypt(random_crypt_name)

  local crypt_width = #crypt.map[1]
  local crypt_height = #crypt.map

  local map_width = app.config.MAP_NUM_CELLS_X
  local map_height = app.config.MAP_NUM_CELLS_Y

  local offset_x = math.random(1, map_width - crypt_width)
  local offset_y = math.random(1, map_height - crypt_height)

  for x = 1, crypt_width do
    for y = 1, crypt_height do
      local char = string.sub(crypt.map[y], x, x)
      local definition = crypt.definitions[char]
      if definition then
        map[x + offset_x][y + offset_y] = create_terrain(crypt.definitions[char])
      end
    end
  end

  return map
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

function cache_attributes(entity)
  table.each({'armor', 'muscle', 'speed', 'mind'}, function (attribute)
                                                     entity[attribute] = sum_descent(entity.base_part, attribute)
                                                   end)
end

function sum_descent(part, attribute)
  local sum = part[attribute]
  table.each(part.contains, function(other) sum = sum + other[attribute] end)
  return sum
end

function create_terrain(type)
  local base={seen=false}
  local template = terrain_db:create(type)
  return table.merge(base, template)
end

function create_entity(type)
  local base = {x=0, y=0, level=1, base_part=create_monster_part("torso")}
  local template = entities_db:create(type)
  local entity = table.merge(base, template)
  cache_attributes(entity)
  return entity
end

function create_monster_part(type)
  local base = {name=type,armor=0,muscle=0,speed=0,mind=0,health=0,unlocks={},contains={}}
  local template = monster_parts_db:create(type)
  return table.merge(base, template)
end

function create_crypt(type)
  return crypts_db:create(type)
end

function terrain_top_character(terrain)
  return terrain_top_entity(terrain).character
end

function terrain_top_forecolor(terrain)
  return terrain_top_entity(terrain).forecolor
end

function terrain_top_entity(terrain)
  return (terrain.entity and terrain.entity.effect) or terrain.entity or terrain
end

