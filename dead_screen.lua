-- add a state to that class using addState, and re-define the method
local DeadScreen = ScreenManager:addState('DeadScreen')

function DeadScreen:enterState() 
  debug("DeadScreen initialized")


end

function DeadScreen:draw()
  set_color(app.config.MENU_TITLE_COLOR)
  love.graphics.printf("Your race ends with you.", 0, 200, 800, 'center')
  
  set_color(app.config.MENU_REGULAR_COLOR)  
  love.graphics.printf("Press enter to return to the previous screen", 0, 400, 800, 'center')
end

function DeadScreen:keypressed(key, unicode)
  if (key == "return") then
    screen_manager:popState()
  end
end
