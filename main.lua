
function love.load()
  local font = love.graphics.newFont("fonts/VeraMono.ttf", 15)
  love.graphics.setFont(font);

  math.randomseed( os.time() )
  
  current_color = {0,0,0}
  set_new_target_color()

  menu = {
    {label="Start Game", f=start_game_selected},
    {label="Dead characters", f=morgue_selected}, 
    {label="About", f=about_selected}, 
    {label="Quit", f=quit_selected}
  }
  menu_index = 1
end

function love.draw()
  
  love.graphics.setColor(current_color[1], current_color[2], current_color[3]);
  love.graphics.printf("Dead Hand and the Search For the Last Doomsday Device", 0, 200, 800, 'center')
  
  love.graphics.setColor(200,200,200)
  for i,v in ipairs(menu) do 
    local text = v.label
    if menu_index == i then
      text = "[ " .. text .. " ]"
    end
    love.graphics.printf(text, 0, 300 + (25 * i), 800, 'center')
  end
end

function love.update(dt)
  local change_rate = 1
  ctr = (ctr or 0) + dt
  if (ctr >= change_rate) then
    set_new_target_color()
    ctr = 0
  end
  
  multiplier = dt * 1/change_rate
  current_color[1] = current_color[1] + ((target_color[1] - current_color[1]) * multiplier)
  current_color[2] = current_color[2] + ((target_color[2] - current_color[2]) * multiplier)
  current_color[3] = current_color[3] + ((target_color[3] - current_color[3]) * multiplier)
end

function love.keypressed( key, unicode )
  if (key == "down") then
    menu_index = menu_index + 1
    if (menu_index > #menu) then
      menu_index = 1
    end
  end

  if (key == "up") then
    menu_index = menu_index - 1
    if (menu_index <= 0) then
      menu_index = #menu
    end
  end

  if (key == "return") then
    menu[menu_index].f()
  end
end

function set_new_target_color()
  target_color = {math.random(200,255), math.random(200,255), math.random(100,255)}
end

function start_game_selected()
end

function morgue_selected()
end

function about_selected()
end

function quit_selected()
  love.event.push('q') -- quit the game
end
