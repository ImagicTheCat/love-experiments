-- Sparse tile quadtree.
-- Children (none or 4):
-- |1|2|
-- |3|4|

local Quadtree = {}
local Quadtree_meta = {__index = Quadtree}

local function new()
  -- root: root node
  -- x, y: root origin
  -- size: root node size
  return setmetatable({}, Quadtree_meta)
end

-- return (w,h) of intersection
local function intersect(x1, y1, w1, h1, x2, y2, w2, h2)
  return math.min(x1+w1, x2+w2)-math.max(x1, x2), math.min(y1+h1, y2+h2)-math.max(y1, y2) 
end

local function node_clear(node)
  node.tile = nil
  node[1], node[2], node[3], node[4] = nil, nil, nil, nil
end

local function node_split(node)
  node[1], node[2], node[3], node[4] = {tile = node.tile}, {tile = node.tile}, {tile = node.tile}, {tile = node.tile}
  node.tile = nil
end

local function node_canmerge(node)
  return #node[1] == 0 and #node[2] == 0
    and #node[3] == 0 and #node[4] == 0
    and node[1].tile == node[2].tile
    and node[2].tile == node[3].tile
    and node[3].tile == node[4].tile
end

-- recursive fill
-- x,y: node origin
-- size: node size
local function rfill(self, state, node, x, y, size)
  local iw, ih = intersect(state.x, state.y, state.w, state.h, x, y, size, size)
  if iw <= 0 or ih <= 0 then return end -- no intersection
  if iw == size and ih == size then -- full
    node_clear(node)
    node.tile = state.tile
  else -- partial
    if #node == 0 then node_split(node) end
    local hsize = size/2
    rfill(self, state, node[1], x, y, hsize)
    rfill(self, state, node[2], x+hsize, y, hsize)
    rfill(self, state, node[3], x, y+hsize, hsize)
    rfill(self, state, node[4], x+hsize, y+hsize, hsize)
    -- merge
    if node_canmerge(node) then
      local tile = node[1].tile
      node_clear(node)
      node.tile = tile
    end
  end
end

-- x,y,w,h: fill area (units)
-- tile: value or nil (empty)
function Quadtree:fill(x, y, w, h, tile)
  -- first tile
  if not self.root then
    self.root = {tile = tile}
    self.size = 1
    self.x, self.y = x, y
  end
  -- grow root
  local iw, ih = intersect(x, y, w, h, self.x, self.y, self.size, self.size)
  while iw < w or ih < h do -- no intersection
    local quadrant = 1 
    local sx, sy = 0, 0 -- shifts
    -- expand left/right
    if x < self.x then quadrant = quadrant+1; sx = -self.size end
    -- expand up/down
    if y < self.y then quadrant = quadrant+2; sy = -self.size end
    -- change root
    local old_root = self.root
    self.root = {{}, {}, {}, {}}
    self.root[quadrant] = old_root
    self.x, self.y = self.x+sx, self.y+sy
    self.size = self.size*2
    -- next
    iw, ih = intersect(x, y, w, h, self.x, self.y, self.size, self.size)
  end
  -- fill
  local state = {x = x, y = y, w = w, h = h, tile = tile}
  rfill(self, state, self.root, self.x, self.y, self.size)
end

-- Check if a root node is useless (3/4 children are empty).
-- return new root index or nil
local function node_canshrink(node)
  if #node == 0 then return end
  local index
  local count = 0
  -- count non-empty children
  for i=1,4 do
    if #node[i] ~= 0 or node[i].tile then
      count = count+1
      index = i
    end
  end
  if count == 1 then return index end
end

-- Shrink root.
function Quadtree:shrink()
  local index = node_canshrink(self.root)
  while index do
    -- change root
    local old_root = self.root
    self.root = old_root[index]
    self.size = self.size/2
    if index == 2 then self.x = self.x+self.size
    elseif index == 3 then self.y = self.y+self.size
    elseif index == 4 then self.x, self.y = self.x+self.size, self.y+self.size end
    -- next
    index = node_canshrink(self.root)
  end
end

return setmetatable({intersect = intersect}, {__call = new})
