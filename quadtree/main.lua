local Quadtree = require("Quadtree")
local intersect = Quadtree.intersect

local world
local scale = 10 -- px/unit
local camx, camy = 0, 0 -- units
local pencil_tile = true
local pencil_size = 1 -- units
local info
local last_drawn_nodes = 0
function love.load()
  world = Quadtree()
  info = love.graphics.newText(love.graphics.getFont())
end

function love.update(dt)
  local w, h = love.graphics.getDimensions()
  -- edit tiles
  if love.mouse.isDown(1) then
    local x, y = love.mouse.getPosition()
    -- mouse to world units
    x, y = math.floor(camx+(x-w/2)/scale), math.floor(camy+(y-h/2)/scale)
    -- pencil fill
    world:fill(x-math.floor(pencil_size/2), y-math.floor(pencil_size/2), pencil_size, pencil_size, pencil_tile)
    -- shrink quadtree
    world:shrink()
  end
  -- info
  info:set(table.concat({
    "FPS: "..love.timer.getFPS(),
    "scale: "..scale.." px/unit",
    "pencil tile: "..(pencil_tile and "fill" or "empty"),
    "pensil size: "..pencil_size,
    "drawn nodes: "..last_drawn_nodes,
    "",
    "[LMB] edit",
    "[RMB] move",
    "[MWHEEL] zoom",
    "[SPACE] pencil tile",
    "[+][-] pencil size"
  }, "\n"))
end

-- x,y: node origin (units)
-- size: node size (units)
local function draw_node(state, node, x, y, size)
  -- view check
  local iw, ih = intersect(state.x, state.y, state.w, state.h, x, y, size, size)
  if iw <= 0 or ih <= 0 then return end
  if size < state.min_size then return end
  state.count = state.count+1
  -- draw node
  love.graphics.setColor(1,0,0)
  if node.tile then love.graphics.rectangle("fill", x*scale, y*scale, size*scale, size*scale) end
  love.graphics.setColor(1,1,1)
  love.graphics.rectangle("line", x*scale, y*scale, size*scale, size*scale)
  -- recursion
  if #node > 0 then
    local hsize = size/2
    draw_node(state, node[1], x, y, hsize)
    draw_node(state, node[2], x+hsize, y, hsize)
    draw_node(state, node[3], x, y+hsize, hsize)
    draw_node(state, node[4], x+hsize, y+hsize, hsize)
  end
end

-- x,y,w,h: view rect (units)
-- min_size: minimum node size (units)
-- return number of drawn nodes
local function draw_quadtree(quadtree, x, y, w, h, min_size)
  local state = {x = x, y = y, w = w, h = h, min_size = min_size, count = 0}
  if quadtree.root then draw_node(state, quadtree.root, quadtree.x, quadtree.y, quadtree.size) end
  return state.count
end

function love.draw()
  local w, h = love.graphics.getDimensions()
  -- world
  love.graphics.push()
  love.graphics.translate(w/2-camx*scale, h/2-camy*scale)
  local uw, uh = w/scale, h/scale -- view size in units
  last_drawn_nodes = draw_quadtree(world, camx-uw/2, camy-uh/2, uw, uh, 1/scale)
  love.graphics.pop()
  -- info
  love.graphics.setColor(0,0,0,0.75)
  love.graphics.rectangle("fill", 0, 0, info:getWidth()+4, info:getHeight()+4)
  love.graphics.setColor(1,1,1)
  love.graphics.draw(info, 2, 2)
end

function love.mousemoved(x, y, dx, dy)
  if love.mouse.isDown(2) then
    camx, camy = camx-dx/scale, camy-dy/scale
  end
end

function love.wheelmoved(x, y)
  scale = scale*math.pow(2, y)
end

function love.keypressed(key, scancode, isrepeat)
  if key == "space" then
    if pencil_tile then pencil_tile = nil else pencil_tile = true end
  elseif key == "kp+" then pencil_size = pencil_size*2
  elseif key == "kp-" then pencil_size = math.max(1, pencil_size/2) end
end
