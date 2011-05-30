table.includes = function(list, value)
  for i,x in ipairs(list) do
    if (x == value) then
      return(true)
    end
  end
  return(false)
end

table.detect = function(list, func)
  for i,x in ipairs(list) do
    if (func(x)) then
      return(x)
    end
  end
  return(nil)
end

table.each = function(list, func)
  for i,v in ipairs(list) do
    func(v)
  end
end

table.select = function(list, func)
  local results = {}
  for i,x in ipairs(list) do
    if (func(x)) then
      table.insert(results, x)
    end
  end
  return(results)
end

table.reject = function(list, func)
  local results = {}
  for i,x in ipairs(list) do
    if (func(x) == false) then
      table.insert(results, x)
    end
  end
  return(results)
end

table.inject = function(list, value, func)
  local result = value
  for i,x in ipairs(list) do
    result = result + func(x)
  end
  return(result)
end

table.merge = function(source, destination)
  for k,v in pairs(source) do destination[k] = v end
  return destination
end

table.unshift = function(list, val)
  table.insert(list, 1, val)
end

table.shift = function(list)
  return table.remove(list, 1)
end

table.pop = function(list)
  return table.remove(list)
end

table.push = function(list)
  return table.insert(list)
end

table.collect = function(source, func) 
  local result = {}
  for i,v in ipairs(source) do table.insert(result, func(v)) end
  return result
end

table.empty = function(source) 
  return #source == 0
end

table.reverse = function(source)
  local result = {}
  for i,v in ipairs(source) do table.unshift(result, v) end
  return result
end
