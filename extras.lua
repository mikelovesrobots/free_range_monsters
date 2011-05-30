-- FIXME this is osx/linux specific  windows says this command will work instead: mkdir [dir].  no -p
function mkdir(dir)
  os.execute("mkdir -p " .. dir)
end

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
