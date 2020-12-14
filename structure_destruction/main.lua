local world = require("world")

local info
local scx, scy = 0, 0 -- selected cell
local pencil_fill = true
local last_its, last_components = 0, 0
function love.load()
  info = love.graphics.newText(love.graphics.getFont())
end

function love.update(dt)
  local w, h = love.graphics.getDimensions()
  -- physics
  world.physics:update(dt)
  -- info
  info:set(table.concat({
    "FPS: "..love.timer.getFPS(),
    "pencil: "..(pencil_fill and "fill" or "empty"),
    "last detection: ",
    "  iterations: "..last_its,
    "  components: "..last_components,
    "",
    "[R] reload",
    "[LMB] edit",
    "[SPACE] pencil mode"
  }, "\n"))
end

function love.draw()
  local w, h = love.graphics.getDimensions()
  -- world
  love.graphics.setColor(1,0,0)
  local cw, ch = w/world.w, h/world.h
  for j, row in ipairs(world.grid) do
    for i, cell in ipairs(row) do
      if cell.fill then love.graphics.rectangle("fill", (i-1)*cw, (j-1)*ch, cw, ch) end
    end
  end
  -- bodies
  for _, body in ipairs(world.bodies) do
    local ox, oy = body.b2d:getPosition()
    ox, oy = ox/world.unit*cw, oy/world.unit*ch
    local a = body.b2d:getAngle()
    love.graphics.push()
    love.graphics.translate(ox, oy)
    love.graphics.rotate(a)
    for _, coords in ipairs(body.cells) do
      local x, y = unpack(coords)
      love.graphics.rectangle("fill", (x-1)*cw, (y-1)*ch, cw, ch)
    end
    love.graphics.pop()
  end
  -- cell selection
  love.graphics.setColor(1,1,1)
  love.graphics.rectangle("line", (scx-1)*cw, (scy-1)*ch, cw, ch)
  -- info
  love.graphics.setColor(0,0,0,0.75)
  love.graphics.rectangle("fill", 0, 0, info:getWidth()+4, info:getHeight()+4)
  love.graphics.setColor(1,1,1)
  love.graphics.draw(info, 2, 2)
end

function love.keypressed(key)
  if key == "space" then pencil_fill = not pencil_fill
  elseif key == "r" then world:clear() end
end

local function edit_cell()
  world:setCell(scx, scy, pencil_fill)
  if not pencil_fill then
    last_its, last_components = world:detectSplit(scx, scy)
  end
end

function love.mousemoved(x, y)
  local w, h = love.graphics.getDimensions()
  -- cell selection
  local mx, my = love.mouse.getPosition()
  local cw, ch = w/world.w, h/world.h
  scx, scy = math.floor(mx/cw)+1, math.floor(my/ch)+1
  -- edit
  if love.mouse.isDown(1) then edit_cell() end
end

function love.mousepressed(x, y, button)
  if button == 1 then edit_cell() end
end
