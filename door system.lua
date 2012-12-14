term.clear()
mon = peripheral.wrap("left")
mon.clear()
mon.setTextScale(1)
mon.setCursorPos(2, 1)
mon.write("< Door System >")

cable = "back"
cables = {
  light = colors.white,
  plate = colors.yellow,
  seal = colors.red,
  timer = colors.blue,
  wait = colors.lightBlue,
  inner = colors.orange,
  res = colors.green
}
check = function(what)
  return rs.testBundledInput(cable,cables[what])
end
state = false
go = function(open)
  mon.setCursorPos(1,4)
  if open then
    rs.setBundledOutput(cable, cables.res)
    mon.write("     Opened")
  else
    rs.setBundledOutput(cable, 0)
    mon.write("     Closed")
  end
  state = open
end

wStatus = function(msg)
  local w = mon.getSize()
  local len = string.len(msg)
  mon.setCursorPos(math.ceil(w/2 - len/2), 3)
  mon.clearLine()
  if len > 0 then
    mon.write(msg)
    print("status: " .. msg)
  end
end

while true do
  if rs.getInput("right") then
    wStatus("Not running")
    break
  end

  
  if not check("seal") then
    wStatus("Seal active")
    go(false)
  elseif check("light") then
    wStatus("Daylight")
    go(true)
  else

    if check("plate") then
      if check("inner") and state then
        wStatus("Forced close")
        go(false)
      else
        wStatus("Step on plate")
        go(true)
      end
    elseif check("timer") then
      wStatus("Autoclose")
      go(false)
    elseif not check("light") and not check("wait") then
      wStatus("Kill em all!")
      go(false)
    end
  end
  os.pullEvent("redstone")
end