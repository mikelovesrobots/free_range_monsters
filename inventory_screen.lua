-- add a state to that class using addState, and re-define the method
local InventoryScreen = ScreenManager:addState('InventoryScreen')
InventoryScreen.LETTERS = "abcdefghijklmnopqrstuvwxyz"

function InventoryScreen:enterState() 
  debug("InventoryScreen initialized")

  self.mode = 'default'
  self.prompt = {
    default = "(d)rop, (r)eorder, (s)alvage, (c)onstruct",
    drop = "Select the items to drop then hit enter to finish",
    reorder = "Select a second item to swap with",
    salvage = "Select the item to disassemble (salvage)",
    reorder = "Select the items to construct then enter to finish",
  }
  self.selected_items = {}
end

function InventoryScreen:draw()
  love.graphics.setColor(255,255,255);
  love.graphics.printf("Inventory", 0, app.config.MAP_MARGIN_TOP, 800, 'center')
  
  for i,item in ipairs(self.sector.player.items) do
    local color = app.config.MENU_REGULAR_COLOR
    if (table.includes(self.selected_items, i)) then
      color = app.config.MENU_HIGHLIGHTED_COLOR
    end

    love.graphics.setColor(color[1], color[2], color[3])

    local text = string.sub(InventoryScreen.LETTERS, i, i) .. ") " 
    if (i == 1) then
      text = text .. "[PRIMARY WEAPON] "
    end
    text = text .. item.name

    love.graphics.printf(text, app.config.MAP_MARGIN_LEFT, (i * 25) + app.config.MAP_MARGIN_TOP, 800 - (app.config.MAP_MARGIN_LEFT * 2), 'left')
  end

  love.graphics.printf(self.prompt[self.mode], 0, 475, 800, 'center')
  love.graphics.printf("Press (esc) to return to the previous screen", 0, 500, 800, 'center')
end

function InventoryScreen:keypressed(key, unicode)
  if self.mode == "default" then
    self:keypressed_default(key, unicode)
  elseif self.mode == "drop" then
    self:keypressed_drop(key, unicode)
  elseif self.mode == "reorder" then
    self:keypressed_reorder(key, unicode)
  elseif self.mode == "salvage" then
    self:keypressed_salvage(key, unicode)
  else
    error("unsupported keypress mode")
  end
end

function InventoryScreen:keypressed_default(key, unicode)
  if (key == "escape") then
    screen_manager:popState()
  elseif (key == "d") then
    self.mode = "drop"
  elseif (key == "r") then
    self.mode = "reorder"
  elseif (key == "s") then
    self.mode = "salvage"
  elseif (key == "c") then
    -- construct
  end
end

function InventoryScreen:keypressed_drop(key, unicode)
  if (key == "escape") then
    self.mode = "default"
  elseif (key == "return") then
    local matches, rejects = table.partition(self.sector.player.items, function (item, i) 
      return table.includes(self.selected_items, i) 
    end)

    table.each(matches, function (item) self:drop_item(self.sector.player, item) end)
    self.sector.player.items = rejects

    self.selected_items = {}
    self.mode = "default"
  elseif (string.len(key) == 1 and string.match(key, "%a")) then
    -- any single letter
    local i = string.find(InventoryScreen.LETTERS, string.lower(key))
    if #self.player.items >= i then
      table.push(self.selected_items, i)
    end
  else
    debug("unknown key: " .. key)
  end
end

function InventoryScreen:keypressed_reorder(key, unicode)
  if (key == "escape") then
    self.selected_items = {}
    self.mode = "default"
  elseif (string.len(key) == 1 and string.match(key, "%a")) then
    -- any single letter
    local i = string.find(InventoryScreen.LETTERS, string.lower(key))
    if #self.player.items >= i then
      table.push(self.selected_items, i)
    end

    if #self.selected_items == 2 then
      self.player.items[self.selected_items[1]], self.player.items[self.selected_items[2]] = self.player.items[self.selected_items[2]], self.player.items[self.selected_items[1]]
      self.selected_items = {}
      self.mode = "default"
    end
  else
    debug("unknown key: " .. key)
  end
end

function InventoryScreen:keypressed_salvage(key, unicode)
  if (key == "escape") then
    self.mode = "default"
  elseif (string.len(key) == 1 and string.match(key, "%a")) then
    local i = string.find(InventoryScreen.LETTERS, string.lower(key))
    local item = self.player.items[i]
    if item then
      if table.present(item.salvages_into) then
        table.each(item.salvages_into, function(new_item_def)
          local new_item = create_item(new_item_def)
          self:place_item(new_item, self.player.x, self.player.y)
          self:flavor_message("salvage_success", {item_name=item.name, new_item_name=new_item.name})
        end)

        self.player.items = table.without(self.player.items, item)
      else
        self:flavor_message("salvage_fail", {item_name=item.name})
      end

      self.mode = "default"
      screen_manager:popState()
    end
  else
    debug("unknown key: " .. key)
  end
end
