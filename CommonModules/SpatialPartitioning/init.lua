--[[

= DigitalSwirl =

Source: CommonModules/SpatialPartitioning.lua
Purpose: Spatial Partitioning class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local spatial_partitioning = {}

local run_service = game:GetService("RunService")

local part_class = require(script:WaitForChild("Part"))

--Internal functions
local function RemoveCell(self, vec, part)
	debug.profilebegin("spatial_partitioning:RemoveCell")
	
	if self.cells[vec] ~= nil then
		self.cells[vec][part] = nil
	end
	
	debug.profileend()
end

local function SetCell(self, vec, part)
	debug.profilebegin("spatial_partitioning:SetCell")
	
	if self.cells[vec] == nil then
		self.cells[vec] = {}
	end
	self.cells[vec][part] = true
	
	debug.profileend()
end

local function VectorHash(x, y, z)
	if typeof(x) == "Vector3" then
		y = x.Y
		z = x.Z
		x = x.X
	end
	return (x * 24832) + (y * 48128) + (z * 81935)
end

local function ToCell(self, x)
	return math.floor(x / self.cell_dim)
end

local function Update(self, part)
	debug.profilebegin("spatial_partitioning:Update")
	
	--Get cell updates
	local cell_remove, cell_set = self.parts[part]:Update(part.CFrame, part.Size)
	
	--Update cells
	for _,v in pairs(cell_remove) do
		RemoveCell(self, VectorHash(v), part)
	end
	for _,v in pairs(cell_set) do
		SetCell(self, VectorHash(v), part)
	end
	
	debug.profileend()
end

--Constructor and destructor
function spatial_partitioning:New(cell_dim)
	--Initialize meta reference
	local self = setmetatable({}, {__index = spatial_partitioning})
	
	--Remember given properties
	self.cell_dim = cell_dim
	
	--Initialize state
	self.cells = {}
	self.parts = {}
	self.unanchored_parts = {}
	self.root_cons = {}
	
	--Handle physics updates
	self.physics_conn = run_service.Heartbeat:Connect(function()
		for i,_ in pairs(self.unanchored_parts) do
			if self.parts[i]:Moved(i.CFrame) then
				Update(self, i)
			end
		end
	end)
	
	return self
end

function spatial_partitioning:Destroy()
	--Disconnect connections
	if self.physics_conn ~= nil then
		self.physics_conn:Disconnect()
		self.physics_conn = nil
	end
	
	if self.root_cons ~= nil then
		for _,v in pairs(self.root_cons) do
			for _,k in pairs(v) do
				k:Disconnect()
			end
		end
		self.root_cons = nil
	end
	
	--Destroy parts
	if self.parts ~= nil then
		for _,v in pairs(self.parts) do
			v:Destroy()
		end
		self.parts = nil
	end
	
	--Clear cells table
	self.cells = nil
end

--Spatial partitioning interface
function spatial_partitioning:Add(part)
	debug.profilebegin("spatial_partitioning:Add")
	
	if self.parts[part] == nil then
		--Create part class and get containing cells
		local new_part = part_class:New(self.cell_dim)
		local _, cell_set = new_part:Update(part.CFrame, part.Size)
		
		--Set cells
		for _,v in pairs(cell_set) do
			SetCell(self, VectorHash(v), part)
		end
		
		--Remember part class
		self.parts[part] = new_part
		
		--Attach update connections
		local update_func = function()
			Update(self, part)
		end
		local anchor_func = function()
			if part.Anchored then
				self.unanchored_parts[part] = nil
			else
				self.unanchored_parts[part] = true
			end
		end
		anchor_func()
		
		self.root_cons[part] = {
			part:GetPropertyChangedSignal("CFrame"):Connect(update_func),
			part:GetPropertyChangedSignal("Size"):Connect(update_func),
			part:GetPropertyChangedSignal("Anchored"):Connect(anchor_func),
		}
	end
	
	debug.profileend()
end

function spatial_partitioning:Remove(part)
	debug.profilebegin("spatial_partitioning:Remove")
	
	if self.parts[part] ~= nil then
		--Disconnect update
		if self.root_cons[part] ~= nil then
			for _,v in pairs(self.root_cons[part]) do
				v:Disconnect()
			end
			self.root_cons[part] = nil
		end
		
		--Remove containing cells
		local cell_remove = self.parts[part]:GetCells()
		for _,v in pairs(cell_remove) do
			RemoveCell(self, v, part)
		end
		
		--Destroy part class
		self.parts[part]:Destroy()
		self.parts[part] = nil
		self.unanchored_parts[part] = nil
	end
	
	debug.profileend()
end

function spatial_partitioning:GetPartsInRegion(region)
	debug.profilebegin("spatial_partitioning:GetPartsInRegion")
	
	if typeof(region) == "Region3" then
		region = {
			min = region.CFrame.p - region.Size / 2,
			max = region.CFrame.p + region.Size / 2,
		}
	end
	
	local res = {}
	local temp_map = {}
	
	for x = ToCell(self, region.min.X), ToCell(self, region.max.X) do
		for y = ToCell(self, region.min.Y), ToCell(self, region.max.Y) do
			for z = ToCell(self, region.min.Z), ToCell(self, region.max.Z) do
				local vec = VectorHash(x, y, z)
				if self.cells[vec] ~= nil then
					for i,_ in pairs(self.cells[vec]) do
						if not temp_map[i] then
							table.insert(res, i)
							temp_map[i] = true
						end
					end
				end
			end
		end
	end
	
	debug.profileend()
	
	return res
end

return spatial_partitioning