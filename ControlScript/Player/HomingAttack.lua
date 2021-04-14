--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/HomingAttack.lua
Purpose: Player Homing Attack functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_homing_attack = {}

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local vector = require(common_modules:WaitForChild("Vector"))
local cframe = require(common_modules:WaitForChild("CFrame"))
local collision = require(common_modules:WaitForChild("Collision"))
local global_reference = require(common_modules:WaitForChild("GlobalReference"))

local acceleration = require(script.Parent:WaitForChild("Acceleration"))

local collision_reference = global_reference:New(workspace, "Level/Map/Collision")

--Homing attack object checks
local function HomingCond_Init(self, v)
	--Check if object is homable
	return v.homing_target
end

local function HomingCond_Dist(self, v)
	--Check for upwards height difference
	local loc = (self.ang + self.pos):inverse() * v.root.Position
	if loc.Y > 20 * self.p.scale then
		return false
	end
	
	--Check if there's collision between us and the object
	local mypos = self:GetMiddle()
	local hit = collision.Raycast({workspace.Terrain, collision_reference:Get()}, mypos, v.root.Position - mypos)
	return hit == nil
end

local function GetHomingObject(self, object_instance)
	return object_instance:GetNearestDot(self.pos, self:GetLook(), 100 * self.p.scale, 0.3825, 1, 0.5,
		function(v)
			return HomingCond_Init(self, v)
		end,
		function(v)
			return HomingCond_Dist(self, v)
		end
	)
end

--Homing attack interface
function player_homing_attack.CheckStartHoming(self, object_instance)
	--Check for homing object and return if it was found
	self.homing_obj = GetHomingObject(self, object_instance)
	return self.homing_obj ~= nil
end

function player_homing_attack.RunHoming(self, object_instance)
	if self.homing_obj ~= nil then
		--Align to gravity
		self:SetAngle(cframe.FromToRotation(self:GetUp(), -self.gravity.unit) * self.ang)
		
		--Update homing object
		local next_homing_obj = GetHomingObject(self, object_instance)
		if next_homing_obj ~= nil then
			self.homing_obj = next_homing_obj
		end
		
		--Get angle difference and turn
		local world_cf = self:ToWorldCFrame() + (self:GetUp() * (self.p.height * self.p.scale))
		local local_pos = world_cf:inverse() * self.homing_obj.root.Position
		local local_turnpos = local_pos * Vector3.new(1, 0, 1)
		local local_dir = local_turnpos.magnitude ~= 0 and local_turnpos.unit or Vector3.new(0, 0, -1)
		
		local max_turn = math.rad(11.25) --22.5 when super
		max_turn *= 1 + (self.homing_timer / 40)
		
		local turn = vector.SignedAngle(Vector3.new(0, 0, -1), local_dir, Vector3.new(0, 1, 0))
		self:Turn(math.clamp(turn, -max_turn, max_turn))
		
		--Get power
		local power = 5 --10 if super sonic
		if self.homing_timer > 180 then
			power *= (0.7 + math.random() * 0.1) --Sputter power when we've been homing for 3 seconds
		end
		
		--Set speed
		local world_cf = self:ToWorldCFrame() + (self:GetUp() * (self.p.height * self.p.scale))
		local local_pos = world_cf:inverse() * self.homing_obj.root.Position
		
		if local_pos.magnitude ~= 0 then
			local local_spd = local_pos.unit
			local forward_mag = (local_spd * Vector3.new(1, 0, 1)).magnitude
			self.spd = Vector3.new(forward_mag * power, local_spd.Y * power, 0)
		end
		
		--Increment homing timer
		self.homing_timer += 1
		
		--Drop homing attack if we're gone by the object
		local pos_diff = self.homing_obj.root.Position - (self.pos + self:ToGlobal(self.spd) * self.p.scale)
		if pos_diff.magnitude ~= 0 then
			if pos_diff.unit:Dot(self:GetLook()) < 0 then
				return true
			end
		end
		return false
	else
		--Drag and do regular movement
		self.spd = vector.MulX(self.spd, 0.98)
		acceleration.GetAcceleration(self)
		
		--Increment homing timer
		self.homing_timer += 1
		return self.homing_timer >= 15
	end
end

return player_homing_attack