require('middleclass')
require('middleclass-extras')
require('lua-enumerable')
json = require('json/dkjson')

require('config')
require('extras')
require('library')
require('flavor_text')
require('screen_manager')
require('main_menu_screen')
require('morgue_screen')
require('about_screen')
require('dead_screen')
require('level_up_screen')
require('game')

DEBUG = true

function love.load()
  math.randomseed( os.time() )
  
  terrain_db = Library:new('terrain')
  entities_db = Library:new('entities')
  monster_parts_db = Library:new('monster_parts')
  crypts_db = Library:new('crypts')
  flavor_text_db = FlavorText:new('flavor_text')

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
