FlavorText = class('FlavorText') --this is the same as class('Person', Object) or Object:subclass('Person')
function FlavorText:initialize(name)
  self.name = name
  self.db = Library:new(name)
end

function FlavorText:create(name, vars)
  local definitions = self.db:create(name)
  if table.present(definitions) then 
    local definition = table.random(definitions)
    -- <word> loads recursively
    local wip = string.gsub(definition, "<(.-)>", function(word) return self:create(word, vars) end)

    -- {word} tries to do a variable substitution
    wip = string.gsub(wip, "{(.-)}", function(word) return vars[word] end)

    return wip
  else
    error("No known template type " .. name .. " in " .. self.name .. " library")
  end
end

