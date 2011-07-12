-- add a state to that class using addState, and re-define the method
local LevelUpScreen = ScreenManager:addState('LevelUpScreen')

function LevelUpScreen:enterState() 
  debug("LevelUpScreen initialized")
  self:reset_menu()
end

function LevelUpScreen:continuedState()
  self:reset_menu()
end

function LevelUpScreen:draw()
  local menu_color = app.config.MENU_REGULAR_COLOR
  love.graphics.setColor(menu_color[1], menu_color[2], menu_color[3])
  love.graphics.setFont(app.config.MENU_FONT)

  love.graphics.printf("Evolve!", 0, 50, 800, 'center')
  
  for i,v in ipairs(self.menu) do 
    local text = v
    if self.menu_index == i then
      text = "[ " .. text .. " ]"
    end

    love.graphics.printf(text, 0, 150 + (25 * i), 800, 'center')
  end
end

function LevelUpScreen:keypressed(key, unicode)
  if (key == "down") then
    self.menu_index = self.menu_index + 1
    if (self.menu_index > #self.menu) then
      self.menu_index = 1
    end
  end

  if (key == "up") then
    self.menu_index = self.menu_index - 1
    if (self.menu_index <= 0) then
      self.menu_index = #self.menu
    end
  end

  if (key == "return") then
    local item = self.menu[self.menu_index]
    self:selected_item(item)
  end
end

function LevelUpScreen:update(dt)
end

function LevelUpScreen:reset_menu()
  debug("resetting the menu")
  self.menu = self:available_monster_parts(self.sector.player)
  self.menu_index = 1
end

function LevelUpScreen:selected_item(item)
  screen_manager:popState()
end
