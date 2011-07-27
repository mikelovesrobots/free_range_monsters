function file_exists(n)
  local f=io.open(n)
  if f then
    io.close(f)
  end
  return f ~= nil
end

function debug(string)
  if (DEBUG) then
    print(string)
  end
end

function between(val, min, max)
  return val >= min and val <= max
end

function math.dist(x1, y1, x2, y2)
  return ((x2-x1)^2+(y2-y1)^2)^0.5
end

function read_file (path)
  local file = assert(love.filesystem.newFile(path, "r"), "Failed to start file: " .. path)
  assert(file:open('r'), "Failed to open file: " .. path)
  local data = file:read()
  file:close()
  return data
end

json.load_from_file = function(path)
  local result = json.decode(read_file(path))
  if table.present(result) then
    return result
  else
    error("Couldn't properly parse json: " .. path)
  end
end

function set_color(rgb)
  love.graphics.setColor(rgb[1], rgb[2], rgb[3])
end

function pluralize(num, string)
  singular = num .. " " .. string
  if num == 1 then
    return singular
  else
    return singular .. "s"
  end
end