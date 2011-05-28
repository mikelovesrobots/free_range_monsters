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

function log(string)
  if (DEBUG) then
    print(string)
  end
end
