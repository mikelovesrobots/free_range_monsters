require('middleclass')
require('middleclass-extras')
require('screen_manager')
require('main_menu_screen')
require('morgue_screen')
require('about_screen')
require('play_screen')

DEBUG = true

function love.load()
  local font = love.graphics.newFont("fonts/VeraMono.ttf", 15)
  love.graphics.setFont(font);
  
  math.randomseed( os.time() )

  screen_manager = ScreenManager:new() -- this will call initialize and will set the initial menu
end

function love.draw()
  screen_manager:draw()
end

function love.update(dt)
  screen_manager:update(dt)
end

function love.keypressed(key, unicode)
  screen_manager:keypressed(key, unicode)
end

function log(string)
  if (DEBUG) then
    print(string)
  end
end
