ScreenManager = class('ScreenManager')
ScreenManager:include(Stateful)

function ScreenManager:initialize()
  log("screenmanager initialized")
  self:pushState('MainMenuScreen')
end

function ScreenManager:draw()
end

function ScreenManager.keypressed(key, unicode)
end

function ScreenManager.update(dt)
end

