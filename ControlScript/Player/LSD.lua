--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/LSD.lua
Purpose: Player Light Speed Dash functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_lsd = {}

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local vector = require(common_modules:WaitForChild("Vector"))
local cframe = require(common_modules:WaitForChild("CFrame"))
local collision = require(common_modules:WaitForChild("Collision"))
local global_reference = require(common_modules:WaitForChild("GlobalReference"))

local collision_reference = global_reference:New(workspace, "Level/Map/Collision")

--Light speed dash object checks
local function LSD_Init(self, v)
	--Check if object is a ring
	return v.class == "Ring" and v.collected ~= true
end

local function LSD_Dist(self, v)
	--Check if there's collision between us and the object
	local mypos = self:GetMiddle()
	local hit = collision.Raycast({workspace.Terrain, collision_reference:Get()}, mypos, v.root.Position - mypos)
	return hit == nil
end

local function GetLSDObject(self, object_instance)
	local dis = (self.lsd_obj ~= nil) and 20 or 15
	local dot = -0.1
	return object_instance:GetNearestDot(self:GetMiddle(), self:GetLook(), 20, -0.1, 1, 0,
		function(v)
			return LSD_Init(self, v)
		end,
		function(v)
			return LSD_Dist(self, v)
		end
	)
end

local function ValidateStartLSD(self, object_instance)
	if self.lsd_obj ~= nil then
		--Get closest ring to target ring
		local look = self:GetLook()
		local dis = 20
		local near = object_instance:GetNearest(self.lsd_obj.root.Position, dis,
			function(v)
				return LSD_Init(self, v) and v ~= self.lsd_obj
			end,
			nil
		)
		if near == nil then
			return false
		end
		
		--Check if we can light dash these two rings
		local dir = near.root.Position - self.lsd_obj.root.Position
		if dir.magnitude == 0 then
			return false
		else
			dir = dir.unit
		end
		
		return math.abs(look:Dot(dir)) > 0.5
	else
		return false
	end
end

--Homing attack interface
function player_lsd.CheckStartLSD(self, object_instance)
	--Check for homing object and return if it was found
	self.lsd_obj = GetLSDObject(self, object_instance)
	return ValidateStartLSD(self, object_instance)
end

function player_lsd.RunLSD(self, object_instance)
	--Align to gravity
	self.flag.grounded = false
	self:SetAngle(cframe.FromToRotation(self:GetUp(), -self.gravity.unit) * self.ang)
	
	--Get next object
	self.lsd_obj = GetLSDObject(self, object_instance)
	if self.lsd_obj == nil then
		if self.v3 == true then
			self.spd = Vector3.new()
		elseif self.spd.magnitude ~= 0 then
			self.spd = self.spd.unit * 5
		end
		return true
	end
	
	--Get angle difference and turn
	local world_cf = self:ToWorldCFrame() + (self:GetUp() * (self.p.height * self.p.scale))
	local local_pos = world_cf:inverse() * self.lsd_obj.root.Position
	local local_turnpos = local_pos * Vector3.new(1, 0, 1)
	local local_dir = local_turnpos.magnitude ~= 0 and local_turnpos.unit or Vector3.new(0, 0, -1)
	
	local max_turn = math.rad(33.75)
	
	local turn = vector.SignedAngle(Vector3.new(0, 0, -1), local_dir, Vector3.new(0, 1, 0))
	self:Turn(math.clamp(turn, -max_turn, max_turn))
	
	--Get dash power and speed
	local world_cf = self:ToWorldCFrame() + (self:GetUp() * (self.p.height * self.p.scale))
	local local_pos = world_cf:inverse() * self.lsd_obj.root.Position
	local power = math.clamp(local_pos.magnitude / self.p.scale, 2, 8)
	
	if local_pos.magnitude ~= 0 then
		self.spd = self:PosToSpd(local_pos.unit * power)
	end
	
	return false
end

return player_lsd