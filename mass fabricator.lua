--[[
  Control program for recyclers and mass fabricator to create UU matter
--]]

mon = peripheral.wrap("right") -- Monitor display
if mon == nil then
  print("Cannot find monitor, shutting down...3..2..1")
  sleep(3)
  os.shutdown()
end

os.unloadAPI("bundled")
os.loadAPI("/disk/bundled")

--[[
  Number of seconds for fabricator to stay active after MFSU stops reporting full.
  This number is increased by amount of produced scraps
--]]
runTimeDelay = 60 * 5

cable = bundled.wrap("back", {
  mainswitch = colors.red, -- signal from lever to stop whole system
  stopfab = colors.green, -- stop the fabricator on signal
  mfsufull = colors.gray, -- input signal when MFSU is full of energy
  getmatter = colors.white, -- signal Filter on top of fabricator to pull UU Matter
  getmats = colors.yellow, -- signal Retriever to get mats to be scraped
  engines = colors.brown, -- signal for Redstone engines to start pulling scrap from Recyclers
  countscrap = colors.blue, -- counter for created scraps
  countmatter = colors.orange -- counter for created UU matter
})

mon.clear()
mon.setTextScale(1) -- set smallest scale
w, h = mon.getSize() -- size of the attached monitor

-- Helper function to write text on the monitor at specified coordinates
writeAt = function(x, y, txt, clearLine)
  mon.setCursorPos(x, y)
  if clearLine then mon.clearLine() end
  mon.write(txt)
end

writeC = function(y, txt)
  writeAt((w / 2) - (string.len(txt) / 2) + 1, y, txt)
end

running = false -- overall status of whole program (set to FALSE to stop parallels)
started = 0 -- recorded time of start
fabricating = false -- current status of the fabricator  
scrap = 0 -- total number of scraps produced
matter = 0 -- total number of matter produced

setup = 1
while true do
  if setup == 1 then
    print("Do you want to setup production numbers ? [Y/N]")
    ans = string.lower(read())
    if "y" == ans then setup = 2 elseif "n" == ans then break end
  elseif setup == 2 then
    print("Enter number of produced scraps:")
    ans = tonumber(read())
    if ans == nil then print("Not a number !") else scrap = ans setup = 3 end
  elseif setup == 3 then
    print("Enter number of produced matter:")
    ans = tonumber(read())
    if ans == nil then print("Not a number !") else matter = ans break end
  end
end    

-- Parallel function to watch energy source and control fabricator 
watchPower = function()
  local activeFrom, activeTill = 0, 0
  local y = 3
  local lastScrapCount = 0
  
  -- Update line with state of MFSU
  writeState = function(state)
    writeAt(1, y, "MFSU Status: "..state, true)
  end
  
  -- Clear text in line with sub state information 
  clearSubState = function()
    writeAt(1, y + 1, "", true) -- clear the line about deactivation
  end    
  
  -- Function to enable/disable fabricator
  doWork = function(enabled)
    cable("stopfab", not enabled)
    fabricating = enabled
  end
  
  doWork(false) -- safety policy to turn off fabricator after OS reboot   
  
  -- Main loop controlling the fabricator
  while running do
    os.pullEvent() -- any event triggers checks
    
    -- MFSU is full, start processing
    if cable("mfsufull") then
      print("full")
      writeState("currently full")
      clearSubState()      
      doWork(true) -- start fabricator
      activeFrom = os.clock() -- record start time
      activeTill = activeFrom + runTimeDelay + scrap - lastScrapCount -- when it will stop
      lastScrapCount = scrap -- remember count of scrap so it's not counted next time

    -- MFSU reports not full, however it was full recently     
    elseif (activeFrom > 0) then
      
      -- time for deactivation reached
      if (os.clock() >= activeTill) then
        print("stop fabricating !")
        writeState("stopping machine...")
        clearSubState()
        doWork(false) -- stop fabricator
        activeFrom = 0

      -- display countdown for deactivation  
      elseif (os.clock() >= activeFrom + 1) then -- slight delay for display to forbid flickr
        writeState(string.format("was full %u secs ago", os.clock() - activeFrom))
        writeC(y + 1, string.format("will deactivate in %u secs", math.floor(activeTill - os.clock())), true)
      end
        
    -- MFSU still didn't reported full status
    else
      writeState("not full yet, waiting...")
      clearSubState()
    end
    
    sleep(1) -- just little delay for performance sake
  end

  print("watchPower interrupted")
  doWork(false) -- turn off fabricator
  os.pullEvent("mainswitch")
  watchPower() -- restart function when machine is turned on again
  print("watchPower crashed")  
end

-- Parallel function to monitor the production
counter = function()
  display = function()
    -- update production display 
    writeAt(1, 7, string.format("Produced %05u scraps", scrap), true)
    writeAt(10, 8, string.format("%05u matter", matter), true)
  end
  
  display() -- initial display of production before anything get produced
     
  while running do
    os.pullEvent("redstone")
    -- update count of scraps
    if cable("countscrap") then 
      scrap = scrap + 1 
      display()
    -- update count of matter
    elseif cable("countmatter") then 
      matter = matter + 1 
      display()
    end      
  end
  
  os.pullEvent("mainswitch")
  counter() -- restart function when machine is turned on again    
end

-- Function for the timed actions
timer = function()
  every = function(sec) -- returns TRUE if given amount of seconds has elapsed
    return (math.floor(os.clock()) % sec == 0)
  end
  
  mats = false
  
  while running do 
    cable("getmats", mats)
    mats = not mats
    
    -- every 15 seconds signal Filter to pull matter out of fabricator
    cable("getmatter", every(15))
    
    -- write uptime every 2 seconds
    uptimeMsg = string.format("Uptime: %06u", os.clock() - started)
    writeAt(w - string.len(uptimeMsg), h, uptimeMsg)
    
    os.pullEvent()
  end
  
  mats = true -- signal stays on, as Buffer could still have items and pull them
  cable("getmats", mats)
  
  os.pullEvent("mainswitch")
  timer() -- restart function when machine is turned on again  
end


-- Main function
main = function()
  displayShutdown = function()
    mon.clear()
    writeC(h / 2, "Shutdown is active")
    writeC(h, "Switch nearby lever to kick off !")
  end
    
  while true do
    -- switch is turned on
    if cable("mainswitch") then
      -- it's not running, let's start
      if not running then
        mon.clear()
        local title = "Production of UU Matter"
        os.setComputerLabel(title)
        writeC(1, title)
      
        started = os.clock()
        running = true
        print("START")
        os.queueEvent("mainswitch")
      end
    -- shut it down
    elseif running then
      running = false
      print("SHUTDOWN")
      displayShutdown()
    else
      displayShutdown()
    end
          
    cable("engines", running) -- control redstone engines depending on state
    
    os.startTimer(3) -- little safeguard in case no events are coming
    os.pullEvent()
  end
end

while true do
  parallel.waitForAny(main, watchPower, timer, counter)
  running = false
  print("Something crashed, restarting...")
  sleep(3)
end
