-- Sparse loose grid space partitioning.
-- Object: {x, y, radius}
--- x,y: center
--- radius: axis-aligned square radius (half of a side)
local CELL_SIZE = 100
local partition = {cells = {}, cells_count = 0}

function partition:add(o)
  if o[3]*2 > CELL_SIZE then error("object too big") end
  -- get/create cell
  local cx, cy = math.floor(o[1]/CELL_SIZE), math.floor(o[2]/CELL_SIZE)
  local row = self.cells[cy]
  if not row then row = {}; self.cells[cy] = row end
  local cell = row[cx]
  if not cell then
    cell = {}
    row[cx] = cell
    self.cells_count = self.cells_count+1
  end
  -- add
  table.insert(cell, o)
end

-- Query objects from axis-aligned rectangle.
-- return list of objects
function partition:query(x, y, w, h)
  local objs = {}
  for j=math.floor(y/CELL_SIZE-0.5), math.floor((y+h)/CELL_SIZE+0.5) do
    local row = self.cells[j]
    if row then
      for i=math.floor(x/CELL_SIZE-0.5), math.floor((x+w)/CELL_SIZE+0.5) do
        local cell = row[i]
        if cell then for _, o in ipairs(cell) do table.insert(objs, o) end end
      end
    end
  end
  return objs
end

return partition
