local partition = require("partition")
local AREA = 25000 -- area size
local DISKS = 1e6
local DISK_MINR = 1
local DISK_MAXR = 15
local SCALE = 10 -- pixels/meter
local SPEED = 100 -- m/s
local MRADIUS = 2

local function randf(a, b) return math.random()*(b-a)+a end

local function reflect(vx, vy, nx, ny)
  local NdotI = nx*vx+ny*vy
  return vx-2*NdotI*nx, vy-2*NdotI*ny
end

-- return (nx, ny, p)
-- nx, ny: normal
-- p: penetration factor
local function circleCollision(x1, y1, r1, x2, y2, r2)
  local dx, dy = x1-x2, y1-y2
  local dist = math.sqrt(dx*dx+dy*dy)
  if dist < r1+r2 then return dx/dist, dy/dist, r1+r2-dist end
end

local objs = {}
local mx, my, mvx, mvy
local info

function love.load()
  -- spawn disks
  math.randomseed(love.timer.getTime())
  for i=1,DISKS do
    local o = {randf(-AREA/2, AREA/2), randf(-AREA/2, AREA/2), randf(DISK_MINR, DISK_MAXR)}
    partition:add(o)
  end
  -- init mobile
  mx, my = 0, 0
  mvx, mvy = math.r
  local a = math.random()*math.pi*2
  mvx, mvy = math.cos(a)*SPEED, math.sin(a)*SPEED
  -- info
  info = love.graphics.newText(love.graphics.getFont())
end

function love.update(dt)
  local w, h = love.graphics.getDimensions()
  sw, sh = w/SCALE, h/SCALE
  -- query active objects
  objs = partition:query(mx-sw/2, my-sh/2, sw, sh)
  -- movement
  mx, my = mx+mvx*dt, my+mvy*dt
  -- collisions
  for _, o in ipairs(objs) do
    if not o.marked then
      local nx, ny, p = circleCollision(mx, my, MRADIUS, o[1], o[2], o[3])
      if nx then -- collision: simple response
        o.marked = true
        mvx, mvy = reflect(mvx, mvy, nx, ny) -- reflect velocity
        mx, my = mx+p*nx, my+p*ny
        break
      end
    end
  end
  -- info
  info:set("FPS: "..love.timer.getFPS().."\narea: "..(AREA*AREA*1e-6).." km²\ndisks: "..DISKS.."\ncells: "..partition.cells_count.."\nspeed: "..SPEED.." m/s\nscale: "..SCALE.." px/m\nactive disks: "..#objs.."\nx: "..math.floor(mx+0.5).."\ny: "..math.floor(my+0.5))
end

function love.draw()
  local w, h = love.graphics.getDimensions()
  -- game
  love.graphics.push()
  --- center render on mobile
  love.graphics.translate(w/2-mx*SCALE, h/2-my*SCALE)
  love.graphics.scale(SCALE)
  --- disks
  love.graphics.setColor(1,0,0)
  for _, o in ipairs(objs) do
    love.graphics.circle(o.marked and "line" or "fill", o[1], o[2], o[3])
  end
  --- mobile
  love.graphics.setColor(1,1,1)
  love.graphics.circle("fill", mx, my, MRADIUS)
  love.graphics.pop()
  -- info
  love.graphics.setColor(0,0,0,0.75)
  love.graphics.rectangle("fill", 0, 0, info:getWidth()+4, info:getHeight()+4)
  love.graphics.setColor(1,1,1)
  love.graphics.draw(info, 2, 2)
end
