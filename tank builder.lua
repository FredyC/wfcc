size = 3
height = 4
steps = 1

-- 1 - 4 Walls (biggest tank needs exactly 256 blocks for frame)
-- 5 - 8 Lids (5 = front, 6 = left side, 7 = back, 8 = right side)
-- 9 - 12 Valve (second row for each side)
-- 13 Valve for bottom
-- 14 Valve for top

innerHeight = (height - 2) -- Height without bases
basesBlocks = (size * size) * 2 -- Blocks for the bases  
frameBlocks = (innerHeight * 4) + basesBlocks -- Blocks for whole frame
liquidAmount = basesBlocks * height * 16

function placeDown()
  if turtle.detectDown() then
    turtle.digDown()
  end
  turtle.placeDown()
end

function placeFront()
  if turtle.detectDown() then
    turtle.digDown()
  end
  turtle.placeDown()
end

turtle.forward() -- [0,0;0]
turtle.turnLeft() -- [0,0;3]



turtle.back() -- [1,0;3]
placeFront("wall")
turtle.back() -- [2,0;3]
placeFront("wall")
turtle.turnLeft() -- [2,0;2]

turtle.back() -- [2,1;2]
placeFront("wall")
turtle.back() -- [2,2;2]
placeFront("wall")
turtle.turnLeft() -- [2,2;1]

turtle.back() -- [1,2;1]
placeFront("wall")
turtle.back() -- [0,2;1]
placeFront("wall")
turtle.turnLeft() -- [0,2;0]

turtle.back() -- [0,1;0]
placeFront("wall")
turtle.turnLeft() -- [0,1;3]
turtle.back() -- [1,1;3]
placeFront("wall")
turtle.up() -- [1,1,1;3]
placeDown("valve")

