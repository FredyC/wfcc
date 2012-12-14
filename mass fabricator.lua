-- SchedulePower 0.3
-- By Dessimat0r and FredyC

enabled = true -- current status changed upon times
mon = peripheral.wrap("top") -- monitor display
startHour = 12 -- when to start working
endHour = 17 -- end of the shift

i = 0 -- counter for the wanker

checkForDisk = function()
  local hasDisk = disk.isPresent("right")
  if not hasDisk then
    print("Disk removed from drive. Shutting down...")
    os.shutdown()
  end
  return true
end

checkForLever = function()
  if not rs.getInput("bottom") then
    mon.clear()
    mon.setCursorPos(1,1)
    mon.write("Disabled")
    mon.setCursorPos(1,3)
    mon.write("Override is")
    mon.setCursorPos(1,4)
    mon.write("Active")
    sleep(2)
    return false
  end
  return true
end

while true do
  if checkForLever() and checkForDisk() then
    local hour = os.time()
    if hour >= startHour and hour < endHour then
      redstone.setOutput("back", false)
      enabled = true
    else
      redstone.setOutput("back", true)
      enabled = false
      i = 0
    end
  
    mon.clear()
    mon.setCursorPos(1,1)
    mon.write("Enabled:")
    mon.setCursorPos(1,2)
    str = string.format("%s", enabled and "true" or "false")
    mon.write(str)
    mon.setCursorPos(1,3)
  
    if (not enabled or i % 6 == 0) then mon.write("8||===D")
    elseif (i % 6 == 1) then mon.write("8=||==D")
    elseif (i % 6 == 2) then mon.write("8==||=D")
    elseif (i % 6 == 3) then mon.write("8===||D")
    elseif (i % 6 == 4) then mon.write("8==||=D")
    elseif (i % 6 == 5) then mon.write("8=||==D")
    end
  
    mon.setCursorPos(1,4)
    mon.write(textutils.formatTime(hour,true))
  
    i = i + 1
  
    -- send pulse to front every 4 seconds for Retriever and Transposer
    rs.setOutput("front", (i % 20 == 0))
    -- negative status to the left to signal Filter
    rs.setOutput("left", not enabled)
    
    sleep(0.2)
  end
end