-- add a state to that class using addState, and re-define the method
local InventoryScreen = ScreenManager:addState('InventoryScreen')
InventoryScreen.LETTERS = "abcdefghijklmnopqrstuvwxyz"

function InventoryScreen:enterState() 
  debug("InventoryScreen initialized")

  self.mode = 'default'
  self.prompt = {
    default = "(d)rop, (r)eorder, (s)alvage, (c)onstruct",
    drop = "Select the items to drop then hit enter to finish",
    reorder = "Select the pair of items to swap",
    salvage = "Select the item to disassemble (salvage) then hit enter to finish",
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
  else
    error("unsupported keypress mode")
  end
end

function InventoryScreen:keypressed_default(key, unicode)
  if (key == "escape") then
    screen_manager:popState()
  elseif (key == "d") then
    -- drop
    self.mode = "drop"
  elseif (key == "r") then
    -- reorder
  elseif (key == "s") then
    -- salvage
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
