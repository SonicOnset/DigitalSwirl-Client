--[[

= DigitalSwirl Client =

Source: ControlScript/Object.lua
Purpose: Game Object manager
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local object_class = {}

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local collision = require(common_modules:WaitForChild("Collision"))
local spatial_partitioning = require(common_modules:WaitForChild("SpatialPartitioning"))

--Object creation and destruction
local function AddObject(self, v)
	if self.objects ~= nil then
		--Create new object class instance
		if self.class ~= nil and self.class[v.Name] then
			--Construct object
			local new = self.class[v.Name]:New(v)
			if new == nil then
				error("Failed to create class instance for object "..v.Name)
			end
			
			--Set general object information
			new.class = v.Name
			
			--Register object root
			local root = new.root
			if root ~= nil then
				if self.root_lut[root] == nil then
					self.root_lut[root] = new
					table.insert(self.roots, root)
					self.spatial_partitioning:Add(root)
				else
					self.root_lut[root] = new
				end
			end
			
			--Push object to object list
			self.objects[v] = new
		end
	end
end

local function DestroyObject(self, v)
	--Check if object is currently registered
	if self.objects ~= nil and self.objects[v] then
		--Deregister object root
		local root = self.objects[v].root
		if root ~= nil then
			self.root_lut[root] = nil
			for i, v in pairs(self.roots) do
				if v == root then
					self.roots[i] = nil
					break
				end
			end
			self.spatial_partitioning:Remove(root)
		end
		
		--Destroy object
		self.objects[v]:Destroy()
		self.objects[v] = nil
	end
end

--Object connection
local ChildAddedFunction = nil --prototype
local ChildRemovedFunction = nil --prototype

local function ConnectFolder(self, p)
	--Recursively connect subfolders and initialize already existing objects
	for _, v in pairs(p:GetChildren()) do
		ChildAddedFunction(self, v)
	end
	
	--Connect for child creation and deletion
	table.insert(self.connections, p.ChildAdded:Connect(function(v)
		ChildAddedFunction(self, v)
	end))
	table.insert(self.connections, p.ChildRemoved:Connect(function(v)
		ChildRemovedFunction(self, v)
	end))
end

--Connection functions
ChildAddedFunction = function(self, v)
	if v:IsA("Folder") or (v:IsA("Model") and v.PrimaryPart == nil) then
		ConnectFolder(self, v)
	elseif v:IsA("Model") then
		AddObject(self, v)
	end
end

ChildRemovedFunction = function(self, v)
	if v:IsA("Model") then
		DestroyObject(self, v)
	end
end

--Constructor and destructor
function object_class:New()
	--Initialize meta reference
	local self = setmetatable({}, {__index = object_class})
	
	--Initialize object arrays
	self.objects = {}
	self.connections = {}
	
	--Initialize spatial partitioning
	self.spatial_partitioning = spatial_partitioning:New(16)
	self.root_lut = {}
	self.roots = {}
	
	--Load all object types
	self.class = {}
	for _, v in pairs(script:GetChildren()) do
		if v:IsA("ModuleScript") then
			self.class[v.Name] = require(v)
		end
	end
	
	--Initial object connection
	ConnectFolder(self, workspace:WaitForChild("Level"):WaitForChild("Objects"))
	
	--Initialize state
	self.update_osc_time = 0
	
	return self
end

function object_class:Destroy()
	--Release classes
	self.class = nil
	
	--Destroy all objects
	if self.objects ~= nil then
		for _,v in pairs(self.objects) do
			v:Destroy()
		end
		self.objects = nil
	end
	
	--Destroy spatial partitioning
	if self.spatial_partitioning ~= nil then
		self.spatial_partitioning:Destroy()
		self.spatial_partitioning = nil
	end
	
	self.root_lut = nil
	self.roots = nil
	
	--Disconnect connections
	if self.connections ~= nil then
		for _, v in pairs(self.connections) do
			v:Disconnect()
		end
		self.connections = nil
	end
end

--Internal object interface
function object_class:GetObjectsInRegion(region, cond)
	debug.profilebegin("object_class:GetObjectsInRegion")
	
	local objs = {}
	if self.root_lut ~= nil then
		--Perform Region3 check for roots
		local hit_roots = self.spatial_partitioning:GetPartsInRegion(region)
		
		--Get list of objects from hit roots
		for _,v in pairs(hit_roots) do
			local obj = self.root_lut[v]
			if obj ~= nil and (cond == nil or cond(obj)) then
				table.insert(objs, obj)
			end
		end
	end
	
	debug.profileend()
	return objs
end

--Object interface
function object_class:Update()
	debug.profilebegin("object_class:Update")
	
	--Update all objects
	if self.objects ~= nil then
		local j = self.update_osc_time
		for i, v in pairs(self.objects) do
			if v.update ~= nil then
				--Update object
				v.update(v, j)
				j += 1
			end
		end
		self.update_osc_time += 1
	end
	
	debug.profileend()
end

function object_class:Draw(dt)
	debug.profilebegin("object_class:Draw")
	
	--Draw all objects
	if self.objects ~= nil then
		for _,v in pairs(self.objects) do
			if v.draw ~= nil then
				--Draw object
				v.draw(v, dt)
			end
		end
	end
	
	debug.profileend()
end

function object_class:GetNearest(pos, max_dist, cond_init, cond_dist)
	debug.profilebegin("object_class:GetNearest")
	
	local nearest_obj = nil
	if self.objects ~= nil then
		--Get objects that are rougly within the given distance
		local check_region = Region3.new(
			pos - Vector3.new(max_dist, max_dist, max_dist),
			pos + Vector3.new(max_dist, max_dist, max_dist)
		)
		
		local objects = self:GetObjectsInRegion(check_region, function(v)
			return (cond_init == nil or cond_init(v)) and v.root ~= nil
		end)
		
		--Get nearest object out of the found objects
		local nearest_dis = math.huge
		for _,v in pairs(objects) do
			local dis = (v.root.Position - pos).magnitude
			if dis <= max_dist and dis <= nearest_dis and (cond_dist == nil or cond_dist(v)) then
				nearest_dis = dis
				nearest_obj = v
			end
		end
	end
	
	debug.profileend()
	return nearest_obj
end

function object_class:GetNearestDot(pos, dir, max_dist, max_dot, w1, w2, cond_init, cond_dist)
	debug.profilebegin("object_class:GetNearestDot")
	
	local obj = nil
	if self.objects ~= nil then
		--Get objects that are rougly within the given distance
		local check_region = Region3.new(
			pos - Vector3.new(max_dist, max_dist, max_dist),
			pos + Vector3.new(max_dist, max_dist, max_dist)
		)
		
		local objects = self:GetObjectsInRegion(check_region, function(v)
			return (cond_init == nil or cond_init(v)) and v.root ~= nil
		end)
		
		--Get list of targetable objects that meet the general requirements
		local obj_list = {}
		
		for _,v in pairs(objects) do
			local dif = (v.root.Position - pos)
			local dis = dif.magnitude
			local dot = dif.unit:Dot(dir)
			if dis <= max_dist and dot >= max_dot and (cond_dist == nil or cond_dist(v)) then
				table.insert(obj_list, {
					obj = v,
					dis = 1 - (dis / max_dist),
					dot = dot,
				})
			end
		end
		
		--Sort object list
		table.sort(obj_list, function(a, b)
			return ((a.dis * w1) + (a.dot * w2)) > ((b.dis * w1) + (b.dot * w2))
		end)
		
		--Return nearest object
		if obj_list[1] ~= nil then
			obj = obj_list[1].obj
		end
	end
	
	debug.profileend()
	return obj
end

--Object collision
function object_class:TouchPlayer(player)
	debug.profilebegin("object_class:TouchPlayer")
	
	if self.objects ~= nil then
		--Get player sphere and region
		local player_sphere = player:GetSphere()
		local player_region = player:GetRegion()
		
		--Get list of objects to check
		local objects = self:GetObjectsInRegion(player_region, function(v)
			return (v.root ~= nil and v.touch_player ~= nil)
		end)
		
		--Check for collision with all objects
		for _,v in pairs(objects) do
			--Check if object collides
			if collision.TestSphereRotatedBox(player_sphere, {cframe = v.root.CFrame, size = v.root.Size}) then
				--Run object touch function
				v.touch_player(v, player)
			end
		end
	end
	
	debug.profileend()
end

return object_class