-- add a state to that class using addState, and re-define the method
local HelpScreen = ScreenManager:addState('HelpScreen')

function HelpScreen:enterState() 
end

function HelpScreen:draw()
  set_color(app.config.MENU_TITLE_COLOR)
  love.graphics.printf("Keymappings", 0, 50, 800, 'center')
  
  local keys = {
    {"h",  "move left"},
    {"l",  "move right"},
    {"j",  "move down"},
    {"b",  "move down and left"},
    {"n",  "move down and right"},
    {"k",  "move up"},
    {"y",  "move up and left"},
    {"u", "move up and right"},
    {"s", "rest"},
    {"q", "quit"}
  }

  set_color(app.config.MENU_REGULAR_COLOR)
  table.each(keys, function (keypair, i) 
                     local text = keypair[1] .. ") " .. keypair[2]
                     love.graphics.printf(text, 50, 100 + (25 * i), 800, 'left')
                   end)

  love.graphics.printf("Press enter to return to the previous screen", 0, 500, 800, 'center')
end

function HelpScreen:keypressed(key, unicode)
  if (key == "return") then
    screen_manager:popState()
  end
end
