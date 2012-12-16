--[[
  API for easier access to bundled cables.
  Version 0.3

  Call wrap function with side of bundled cable and 
  table object containing map where key is name for 
  cable and value is it's color.

  cable = api.wrap( "back", {
    button = colors.red,
    output = colors.blue,
    extra = colors.green
  })

  -- To read input simply supply name of cable
  cable("button") -- returns TRUE if there is Red signal on input
  
  -- Result from more inputs can be combined using table
  cable({"button","extra"}) -- logical AND for given inputs giving one boolean result
  
  -- To set output use second boolean argument
  cable("output", true) -- send Blue signal
  
  -- More output cables can be set at once too
  cable({"output","extra"}, false) -- setting multiple outputs to same result
  
  -- Finally when you specify just boolean value for the first argument, it will set all configured cables to that value
  cable(false) -- turn off all configured colors on cable
   
--]]

local dbg = function(msg)
  print(msg)
end

function wrap(side, config)

  -- Combine all configured colors to one number and make some checks
  local combined = 0
  for n,c in pairs(config) do 
    if type(c) ~= "number" then
      print(string.format("Warning: Cable named %s has invalid color %s", n, tostring(c)))
    elseif bit.band(combined, c) == c then
      print(string.format("Warning: Cable named %s has duplicate color %s", n, tostring(c)))
    else  
      combined = colors.combine(combined, c) 
    end
  end

  local currentOutput = rs.getBundledOutput(side)
  dbg(string.format("Current output: %u", currentOutput))

  -- Sets the output cable in bundle
  set = function(what, how)
    --dbg(string.format("Set %s to %s", tostring(what), how and "On" or "Off"))
    if (type(what) == "string") then what = config[what] end
    result = how and colors.combine(currentOutput, what) or colors.subtract(currentOutput, what)
    rs.setBundledOutput(side, result)
    currentOutput = result
  end

  -- Checks input in bundle
  check = function(what)
    name = tostring(what)
    if (type(what) == "string") then what = config[what] end
    --dbg(string.format("Check %s = %s", name, rs.testBundledInput(side, what) and "On" or "Off"))
    return rs.testBundledInput(side, what)
  end

  return function(action, value)
    if (type(action) == "boolean") then
      dbg("Set all to "..action and "true" or "false") 
      set(combined, action)

    -- Reading of input
    elseif (value == nil) then 
      if (type(action) == "table") then
        result = false
        for i,n in ipairs(action) do result = result or check(n) end
        return result
      end
      return check(action)

    -- Setting output
    else 
      if (type(action) == "table") then
        result = 0
        for i,n in ipairs(action) do result = colors.combine(result, config[n]) end
        set(result, value)
      else
        set(action, value)
      end
      
    end
    
  end
end