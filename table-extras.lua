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

