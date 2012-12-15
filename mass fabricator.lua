--[[
  Control program for recyclers and mass fabricator to create UU matter
--]]

mon = peripheral.wrap("right") -- Monitor display
if mon == nil then
  print("Cannot find monitor, shutting down...3..2..1")
  sleep(3)
  os.shutdown()
end

runTimeDelay = 60 * 15 -- Number of seconds for fabricator to stay active after MFSU stop reporting full

cable = bundled.wrap("back", {
  setmass = colors.green, -- fabricator main switch
  mfsufull = colors.gray, -- input signal when MFSU is full of energy
  getmatter = colors.white, -- signal Filter on top of fabricator to pull UU Matter
  update = colors.red, -- input signal to update program and reboot
  getmats = colors.yellow, -- signal Retriever to get mats to be scraped
  engines = colors.brown, -- signal for Redstone engines to start pulling scrap from Recyclers
  countscrap = colors.blue, -- counter for created scraps
  countmatter = colors.orange -- counter for created UU matter
})

-- Helper function to write text on the monitor at specified coordinates
writeAt = function(x, y, txt)
  mon.setCursorPos(x, y)
  mon.write(txt)
end

mon.clear()
mon.setTextScale(1) -- set smallest scale
w, h = mon.getSize() -- size of the attached monitor

local title = "Mass production of UU Matter"
os.setComputerLabel(title)
writeAt((w / 2) - (string.len(title) / 2), 1, title)

i = 0 -- internal counter for seconds
running = true -- overall status of whole program (set to FALSE to stop parallels)
started = os.clock() -- record time of start
fabricating = false -- current status of the fabricator  
scrap = 0 -- total number of scraps produced
matter = 0 -- total number of matter produced

-- Parallel function to monitor the production
counter = function()
  while running do
    os.pullEvent("redstone")
    if cable("countscrap") then scrap = scrap + 1
    elseif cable("countmatter") then matter = matter + 1
    else return end
    -- update production display 
    mon.setCursorPos(1, 5)
    mon.clearLine()
    mon.write("Produced %05u scraps and %04u of matter", scrap, matter)
  end
end

writeAt(1, 3, "MFSU Status:")

-- Function to enable/disable fabricator
setMass = function(enabled)
  cable("setmass", not enabled)
  fabricating = enabled
end  

-- Parallel function to watch energy source to shutdown machinery 
watchPower = function()
  local activeFrom = 0
  local x = 14
  while running do
    os.pullEvent("redstone")
    if cable("mfsufull") then -- MFSU is full, start processing
      writeAt(x, 3, "currently full")
      setMass(true) -- start fabricator
      activeFrom = os.clock() -- record start time 
    elseif (activeFrom > 0) then
      local activeTill = activeFrom + runTimeDelay
      if (os.clock() >= activeTill) then -- time for deactivation reached
        setMass(false) -- stop fabricator
        activeFrom = 0
        os.queueEvent("redstone") -- fake redstone event to run next round of loop
      else      
        writeAt(x, 3, string.format("was full %u seconds ago", os.clock() - activeFrom))
        writeAt(x, 4, string.format("will deactivate in %u seconds", math.floor(activeTill - os.clock())))
      end
    else
      writeAt(x, 3, "waiting for FULL status reported...")
    end
  end
end

-- Main function
main = function()
  cable("engines", true) -- Turn on the engines for scrap pulling
  
  every = function(sec)
    return math.floor(started % sec) == 0
  end
  
  while true do
    -- Button was hit, stop everything and 
    if cable("update") then
      running = false
      break
    end
  
    cable("getmats", every(2)) -- Every 2 seconds signal Retriever to get mats
    cable("getmatter", fabricating and every(30)) -- Every 30 seconds signal Filter to pull matter out of fabricator
    
    -- Write uptime every 5 seconds
    if every(5) then
      uptimeMsg = string.format("Uptime: %05u", os.clock() - started)
      writeAt(w - string.len(uptimeMsg), h, uptimeMsg)
    end
  
    sleep(0.5)
  end
end

parallel.waitForAll(main, watchPower, counter)

cable(false) -- Reset all output
setMass(false) -- Stop the fabricator
 
shell.run("update")