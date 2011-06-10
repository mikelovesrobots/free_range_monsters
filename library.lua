Library = class('Library') --this is the same as class('Person', Object) or Object:subclass('Person')
function Library:initialize(name)
  self.name = name
  self.db = json.load_from_file("library/" .. name .. ".json")
end

function Library:create(name)
  local definition = self.db[name]
  if definition then
    -- oooh, magic inheritance of doom
    if definition.base then
      local base = self:create(definition.base)
      return table.merge(base, definition)
    else
      return definition
    end
  else
    error("No known template type " .. name .. " in " .. self.name .. " library")
  end
end
