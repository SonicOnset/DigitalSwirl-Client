--[[

= DigitalSwirl =

Source: CommonModules/SpatialPartitioning.lua
Purpose: Spatial Partitioning part class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local part = {}

--Constructor and destructor
function part:New(cell_dim)
	--Initialize meta reference
	local self = setmetatable({}, {__index = part})
	
	--Initialize state
	self.cell_dim = cell_dim
	self.cells = {}
	self.prev_cframe = nil
	
	return self
end

function part:Destroy()
	--Clear cells table
	self.cells = nil
end

--Internal interface
local function GetRegion(cf, size)
	--Get 8 points around the part
	size /= 2
	local p0 = cf * Vector3.new( size.X,  size.Y,  size.Z)
	local p1 = cf * Vector3.new(-size.X,  size.Y,  size.Z)
	local p2 = cf * Vector3.new( size.X, -size.Y,  size.Z)
	local p3 = cf * Vector3.new(-size.X, -size.Y,  size.Z)
	local p4 = cf * Vector3.new( size.X,  size.Y, -size.Z)
	local p5 = cf * Vector3.new(-size.X,  size.Y, -size.Z)
	local p6 = cf * Vector3.new( size.X, -size.Y, -size.Z)
	local p7 = cf * Vector3.new(-size.X, -size.Y, -size.Z)
	
	--Get min and max of each axis
	local min_x = math.min(p0.X, p1.X, p2.X, p3.X, p4.X, p5.X, p6.X, p7.X)
	local min_y = math.min(p0.Y, p1.Y, p2.Y, p3.Y, p4.Y, p5.Y, p6.Y, p7.Y)
	local min_z = math.min(p0.Z, p1.Z, p2.Z, p3.Z, p4.Z, p5.Z, p6.Z, p7.Z)
	local max_x = math.max(p0.X, p1.X, p2.X, p3.X, p4.X, p5.X, p6.X, p7.X)
	local max_y = math.max(p0.Y, p1.Y, p2.Y, p3.Y, p4.Y, p5.Y, p6.Y, p7.Y)
	local max_z = math.max(p0.Z, p1.Z, p2.Z, p3.Z, p4.Z, p5.Z, p6.Z, p7.Z)
	
	--Return region
	return {
		min = Vector3.new(min_x, min_y, min_z),
		max = Vector3.new(max_x, max_y, max_z),
	}
end

local function ToCell(self, x)
	return math.floor(x / self.cell_dim)
end

--Part interface
function part:Moved(cf)
	return cf ~= self.prev_cframe
end

function part:Update(cf, size)
	debug.profilebegin("part:Update")
	
	--Get new region and containing cells
	local region = GetRegion(cf, size)
	self.prev_cframe = cf
	
	local new_cells = {}
	for x = ToCell(self, region.min.X), ToCell(self, region.max.X) do
		for y = ToCell(self, region.min.Y), ToCell(self, region.max.Y) do
			for z = ToCell(self, region.min.Z), ToCell(self, region.max.Z) do
				new_cells[Vector3.new(x, y, z)] = true
			end
		end
	end
	
	--Compare against previous cells
	local cells_remove = {}
	local temp_map = {}
	for i, v in pairs(self.cells) do
		if not new_cells[v] then
			table.insert(cells_remove, v)
			self.cells[i] = nil
		else
			temp_map[v] = true
		end
	end
	
	local cells_set = {}
	for i,_ in pairs(new_cells) do
		if not temp_map[i] then
			table.insert(cells_set, i)
			table.insert(self.cells, i)
		end
	end
	
	debug.profileend()
	
	return cells_remove, cells_set
end

function part:GetCells()
	return self.cells
end

return part