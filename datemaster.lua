-- DateMaster 0.1
-- By Dessimat0r

mon = peripheral.wrap("right")
day = 0
lastTime = 0.0
if (fs.exists("/disk/datefile") and not fs.isDir("/disk/datefile")) then
 df = fs.open("/disk/datefile", "r")
 line = df.readLine()
 if line then
  day = tonumber(line)
 end
 df.close()
 if not line then
  df = fs.open("/disk/datefile", "w")
  df.writeLine(string.format("%d", day))
  df.close()
 end
end
while true do
 local currTime = os.time()
 if (currTime >= 0 and lastTime > currTime) then
   day = day + 1
   df = fs.open("/disk/datefile", "w")
   df.writeLine(string.format("%d", day))
   df.close()
   local saystr1 = "It's a new day!"
   local saystr2 = string.format("It's day %d.", day)
   term.clear()
   term.setCursorPos(1,1)
   term.write(saystr1)
   term.setCursorPos(1,2)
   term.write(saystr2)
 end
 lastTime = currTime
 mon.clear()
 mon.setCursorPos(1,1)
 mon.write(string.format("Date: %d PC", day))
 mon.setCursorPos(1,3)
 mon.write("Time: ")
 mon.write(textutils.formatTime(os.time(),true))
 sleep(0.5)
end