-- add a state to that class using addState, and re-define the method
local LevelUpScreen = ScreenManager:addState('LevelUpScreen')

function LevelUpScreen:enterState() 
  debug("LevelUpScreen initialized")
  self.parent_parts = {}
  self:reset_menu(self.sector.player.base_part)
end

--function LevelUpScreen:continuedState()
--  self.parent_part = {}
--  self:reset_menu(self.sector.player.base_part)
--end

function LevelUpScreen:draw()
  love.graphics.setFont(app.config.MENU_FONT)

  self:set_color(app.config.MENU_TITLE_COLOR)
  love.graphics.printf("Your race of monsters evolves!", 0, 25, 800, 'center')

  self:set_color(app.config.MENU_REGULAR_COLOR)
  love.graphics.printf("Choose an upgrade", 0, 50, 800, 'center')
  
  love.graphics.printf("(" .. self.base_part.name .. ")", 0, 75, 800, 'center')

  if table.present(self.parent_parts) then
    love.graphics.printf("( press esc to return to " .. self.parent_parts[1].name .. " )", 0, 550, 800, 'center')
  end

  for i,part in ipairs(self.menu) do 
    local text = part.name

    if table.includes(self.base_part.contains, part) then
      text = text .. " >>>"
    end

    if self.menu_index == i then
      self:set_color(app.config.MENU_HIGHLIGHT_COLOR)
    else
      self:set_color(app.config.MENU_REGULAR_COLOR)
    end

    love.graphics.printf(text, 50, 100 + (25 * i), 750, 'left')
  end
end

function LevelUpScreen:set_color(color)
  love.graphics.setColor(color[1], color[2], color[3])
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

  if (key == "escape" and table.present(self.parent_parts)) then
    local part = table.pop(self.parent_parts)
    self:reset_menu(part)
  end
end

function LevelUpScreen:update(dt)
end

function LevelUpScreen:reset_menu(base_part)
  debug("resetting the menu")

  self.base_part = base_part

  self.title = self.base_part.name

  self.menu = {}

  table.each(self.base_part.contains, function (part)
                                        if table.present(part.unlocks) then
                                          table.push(self.menu, part)
                                        end
                                      end)

  table.each(self.base_part.unlocks, function (name)
                                       local installed_names = table.collect(self.base_part.contains, function(x) return x.name end)       
                                       if not table.includes(installed_names, name) then
                                         table.push(self.menu, create_monster_part(name)) 
                                       end
                                     end)

  self.menu_index = 1
end

function LevelUpScreen:selected_item(part)
  if table.includes(self.base_part.contains, part) then
    table.push(self.parent_parts, self.base_part)
    self:reset_menu(part)
  else
    debug("installing part")

    table.push(self.base_part.contains, part)
    screen_manager:popState()
  end
end
