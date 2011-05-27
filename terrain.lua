Terrain = class('Terrain')
function Terrain:initialize()
  self.character = '.'
  self.forecolor = {255,255,255}
  self.entity = nil
end

function Terrain:top_forecolor()
  return(self:top_entity().forecolor);
end

function Terrain:top_character()
  return(self:top_entity().character);
end

function Terrain:top_entity()
  if (self.entity) then
    return(self.entity)
  else
    return(self)
  end
end

