--[[

= DigitalSwirl Client =

Source: ControlScript/ObjectCommon.lua
Purpose: Common functions for game objects
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local object_common = {}

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local vector = require(common_modules:WaitForChild("Vector"))
local cframe = require(common_modules:WaitForChild("CFrame"))
local collision = require(common_modules:WaitForChild("Collision"))
local global_reference = require(common_modules:WaitForChild("GlobalReference"))

local collision_reference = global_reference:New(workspace, "Level/Map/Collision")

--Common functions
local function VelCancel(vel, normal)
	local dot = vel:Dot(normal.unit)
	if dot < 0 then
		return vel - (normal.unit) * dot
	end
	return vel
end

local function LocalVelCancel(self, vel, normal)
	return self:ToLocal(VelCancel(self:ToGlobal(vel), normal.unit))
end

--Common object to player collision
function object_common.PushPlayerCylinder(root, player, power)
	--Get pos local to root
	local player_sphere = player:GetSphere()
	local loc_pos = root.CFrame:inverse() * player_sphere.center
	local loc_prj = vector.SetY(loc_pos, 0)
	
	if loc_prj.magnitude ~= 0 then
		--Check if we should clip out of the cylinder
		local tgt_clip = loc_prj.unit * Vector3.new(root.Size.X / 2, 0, root.Size.Z / 2)
		local clip = loc_prj.magnitude - (tgt_clip.magnitude + player_sphere.radius)
		
		if clip < 0 then
			--Attempt to clip out, but don't go through collision
			local root_rot = root.CFrame - root.Position
			local clip_world = root_rot * loc_prj.unit
			local from = player.pos
			local to = player.pos - clip_world * clip
			local hit, pos, _ = collision.Raycast({workspace.Terrain, collision_reference:Get()}, from, (to - from) + clip_world * player_sphere.radius)
			if hit == nil then
				player.pos = player.pos:Lerp(to, power)
			end
			
			--Kill velocity clipping into the object
			player.spd = player.spd:Lerp(LocalVelCancel(player, player.spd, clip_world), power)
		end
	end
end

return object_common