-- add a state to that class using addState, and re-define the method
local MorgueScreen = ScreenManager:addState('MorgueScreen')

function MorgueScreen:enterState() 
  log("MorgueScreen initialized")
end

function MorgueScreen:draw()
  love.graphics.setColor(255,255,255);
  love.graphics.printf("[unimplemented]", 0, 200, 800, 'center')
  love.graphics.printf("Press enter to return to the previous screen", 0, 400, 800, 'center')
end

function MorgueScreen:keypressed(key, unicode)
  if (key == "return") then
    screen_manager:popState()
  end
end
