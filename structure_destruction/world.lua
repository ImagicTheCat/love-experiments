-- Queue
local queue = {}
function queue:push(t)
  local new_tail = {t = t}
  if self.tail then
    self.tail.p = new_tail
    self.tail = new_tail
  else self.head = new_tail end
  self.tail = new_tail
end

function queue:pop()
  local old_head = self.head
  if old_head then
    self.head = old_head.p
    if not self.head then self.tail = nil end
    return old_head.t
  end
end

function queue:clear()
  self.head, self.tail = nil, nil
end

-- World
local GW, GH = 64, 36
local PU = 1 -- physic unit (meters)
local world = {grid = {}, w = GW, h = GH, unit = PU}
-- build world grid
for j=1,GH do
  local row = {}; world.grid[j] = row
  for i=1,GW do table.insert(row, {fill = false}) end
end
love.physics.setMeter(1)
world.physics = love.physics.newWorld(0, 9.81)
world.body = love.physics.newBody(world.physics)
world.bodies = {}

function world:clear()
  -- tiles
  for i=1,GW do
    for j=1,GH do
      self:setCell(i, j, i == 1 or j == 1 or i == GW or j == GH)
    end
  end
  -- bodies
  for _, body in ipairs(self.bodies) do body.b2d:destroy() end
  self.bodies = {}
end

function world:getCell(x, y)
  local row = self.grid[y]
  if row then return row[x] end
end

-- fill: boolean, full or empty
function world:setCell(x, y, fill)
  if x < 1 or y < 1 or x > GW or y > GH then return end
  local cell = self.grid[y][x]
  if cell.fill ~= fill then
    cell.fill = fill
    if fill then
      cell.fixture = love.physics.newFixture(self.body, love.physics.newRectangleShape(PU*(x-0.5), PU*(y-0.5), PU, PU))
    else
      cell.fixture:destroy()
      cell.fixture = nil
    end
  end
end

-- x,y: coords
-- f(i, j): called for each adjacent coords
local function foradj(x, y, f)
  for i=-1,1 do
    for j=-1,1 do
      if i ~= 0 or j ~= 0 then f(x+i, y+j) end
    end
  end
end

-- return iterations, components count
function world:detectSplit(x, y)
  local components = {} -- map of components => list of groups and .grounded
  local groups = {} -- list of label groups => list of coords with .component
  local component_count, grounded_count = 0, 0
  -- new group from each adjacent cells
  foradj(x, y, function(i, j)
    local adj = self:getCell(i, j)
    if adj and adj.fill then
      local component = {}
      component_count = component_count+1
      component.grounded = (i == 1 or j == 1 or i == GW or j == GH)
      if component.grounded then grounded_count = grounded_count+1 end
      local group = {{i, j}, component = component}
      table.insert(component, group)
      table.insert(groups, group)
      components[component] = true
      adj.group = group
      queue:push({i, j})
    end
  end)
  local its = 0
  -- flood fill groups
  local coords = queue:pop()
  while coords and component_count > 1 and grounded_count ~= component_count do
    local x, y = unpack(coords)
    local cell = self:getCell(x, y)
    -- spread label/group
    foradj(x, y, function(i, j)
      local adj = self:getCell(i, j)
      if adj and adj.fill then
        if adj.group then -- already labelled/grouped
          -- groups connection
          if adj.group.component ~= cell.group.component then
            -- merge components
            --- remove component
            local adj_component = adj.group.component
            component_count = component_count-1
            if adj_component.grounded then grounded_count = grounded_count-1 end
            components[adj_component] = nil
            --- merge groups, update component
            for _, group in ipairs(adj_component) do
              table.insert(cell.group.component, group)
              group.component = cell.group.component
            end
            -- spread grounded
            if adj_component.grounded and not cell.group.component.grounded then
              cell.group.component.grounded = true
              grounded_count = grounded_count+1
            end
          end
        else -- add label/group
          adj.group = cell.group
          table.insert(adj.group, {i, j})
          if (i == 1 or j == 1 or i == GW or j == GH) and not adj.group.component.grounded then
            adj.group.component.grounded = true
            grounded_count = grounded_count+1
          end
          if not adj.group.component.grounded then queue:push({i,j}) end -- continue exploration if not grounded
        end
      end
    end)
    -- next
    its = its+1
    coords = queue:pop()
  end
  queue:clear()

  -- remove labels
  for component in pairs(components) do
    for _, group in ipairs(component) do
      for _, coords in ipairs(group) do
        local cell = self:getCell(unpack(coords))
        cell.group = nil -- unlabel
      end
    end
  end
  if component_count > 1 then
    -- generate bodies for ungrounded components
    for component in pairs(components) do
      if not component.grounded then
        local body = love.physics.newBody(self.physics, 0, 0, "dynamic")
        local bcells = {}
        table.insert(self.bodies, {b2d = body, cells = bcells})
        for _, group in ipairs(component) do
          for _, coords in ipairs(group) do
            local x, y = unpack(coords)
            self:setCell(x, y, false)
            love.physics.newFixture(body, love.physics.newRectangleShape((x-0.5)*PU, (y-0.5)*PU, PU, PU))
            table.insert(bcells, coords)
          end
        end
      end
    end
  end
  return its, component_count
end

world:clear() -- init

return world
