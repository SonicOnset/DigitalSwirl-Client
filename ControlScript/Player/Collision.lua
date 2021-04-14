--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/Collision.lua
Purpose: Player collision functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_collision = {}

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local constants = require(script.Parent.Parent:WaitForChild("Constants"))
local vector = require(common_modules:WaitForChild("Vector"))
local cframe = require(common_modules:WaitForChild("CFrame"))
local collision = require(common_modules:WaitForChild("Collision"))
local global_reference = require(common_modules:WaitForChild("GlobalReference"))

local ragdoll = require(script.Parent:WaitForChild("Ragdoll"))

local collision_reference = global_reference:New(workspace, "Level/Map/Collision")
local water_reference = global_reference:New(workspace, "Level/Water")

--Common functions
local function lerp(x, y, z)
	return x + (y - x) * z
end

--Normal alignment
local function GetAligned(self, normal)
	if self.state == constants.state.ragdoll then
		return self.ang
	end
	if self:GetUp():Dot(normal) < -0.999 then
		return CFrame.Angles(math.pi, 0, 0) * self.ang
	end
	local rot = cframe.FromToRotation(self:GetUp(), normal)
	return rot * self.ang
end

local function AlignNormal(self, normal)
	self:SetAngle(GetAligned(self, normal))
end

--Velocity cancel for walls
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

local function LocalFlatten(self, vector, normal)
	return self:ToLocal(vector.Flatten(self:ToGlobal(vector), normal.unit))
end

--Wall collision
local function WallRay(self, wl, y, dir, vel)
	--Raycast
	local rdir = dir * self.p.rad * self.p.scale
	local from = self.pos + self:GetUp() * y
	local fdir = dir * (self.p.rad + vel) * self.p.scale
	local to = from + fdir
	
	local hit, pos, nor = collision.Raycast(wl, from, fdir)
	
	if hit then
		return (pos - rdir) - from, nor, pos
	end
	return nil, nil, nil
end

local function CheckWallAttach(self, dir, nor)
	local ddot = dir:Dot(nor)
	local sdot = self:ToGlobal(self.spd):Dot(nor)
	local udot = self:GetUp():Dot(nor)
	return (ddot < -0.35 and sdot < -1.16 and udot > 0.5)
end

local function WallAttach(self, wl, nor)
	local fup = self.p.height * self.p.scale
	local fdown = fup + (self.p.pos_error * self.p.scale)
	local hit, pos, hnor = collision.Raycast(wl, self.pos + self:GetUp() * fup, nor * -fdown)
	if hit then
		self.pos = pos
		self:SetAngle(GetAligned(self, hnor))
	end
end

local function WallHit(self, nor)
	self.spd = LocalVelCancel(self, self.spd, nor)
end

local function WallCollide(self, wl, y, dir, vel, fattach, battach)
	--Positive and negative wall collision
	local wf_pos, wf_nor, wf_tp = WallRay(self, wl, y, dir, math.max(vel, 0))
	local wb_pos, wb_nor, wb_tp = WallRay(self, wl, y, -dir, math.max(-vel, 0))
	
	--Clip with walls
	local move = true
	if wf_pos and wb_pos then
		self.pos += (wf_pos + wb_pos) / 2
		local mid = wf_nor + wb_nor
		if mid.magnitude ~= 0 then
			wf_nor = mid.unit
		else
			wf_nor = nil
		end
		wb_nor = nil
		move = false
	elseif wf_pos then
		self.pos += wf_pos
	elseif wb_pos then
		self.pos += wb_pos
	end
	
	--Velocity cancelling
	if wf_nor then
		if fattach and CheckWallAttach(self, dir, wf_nor) then
			WallAttach(self, wl, wf_nor)
			move = false
		else
			WallHit(self, wf_nor)
		end
	end
	if wb_nor then
		if battach and CheckWallAttach(self, -dir, wb_nor) then
			WallAttach(self, wl, wb_nor)
			move = false
		else
			WallHit(self, wb_nor)
		end
	end
	return move
end

--Water collision
local function PointInWater(pos)
	--Check for terrain water
	local voxel_pos = workspace.Terrain:WorldToCell(pos)
	local voxel_region = Region3.new(voxel_pos * 4, (voxel_pos + Vector3.new(1, 1, 1)) * 4)
	local material_map, occupancy_map = workspace.Terrain:ReadVoxels(voxel_region, 4)
	local voxel_material = material_map[1][1][1]
	if voxel_material == Enum.Material.Water then
		return true
	end
	
	--Check for part water
	local water = water_reference:Get()
	if water ~= nil then
		local near_water = workspace:FindPartsInRegion3WithWhiteList(voxel_region, water:GetChildren())
		
		for _, v in pairs(near_water) do
			local local_pos = v.CFrame:inverse() * pos
			if collision.SqDistPointAABB(local_pos, {min = v.Size / -2, max = v.Size / 2}) <= 0 then
				return true
			end
		end
	end
end

--Collision call
function player_collision.Run(self)
	debug.profilebegin("player_collision.Run")
	
	--Remember previous state
	local prev_spd = self:ToGlobal(self.spd)
	
	--Get collision whitelist
	local wl = {workspace.Terrain, collision_reference:Get()}
	
	--Stick to moving floors
	if self.flag.grounded and self.floor ~= nil and self.floor_last ~= nil then
		local prev_world = self.floor_last * self.floor_off
		local new_world = self.floor.CFrame * self.floor_off
		local rt_rot = cframe.FromToRotation(prev_world.RightVector, new_world.RightVector)
		local up_rot = cframe.FromToRotation(prev_world.UpVector, new_world.UpVector)
		self.floor_move = new_world.p - prev_world.p
		self.pos += self.floor_move
		self:SetAngle(rt_rot * self.ang)
	end
	
	for i = 1, 4 do
		--Remember previous position
		local prev_pos = self.pos
		local prev_mid = self:GetMiddle()
		
		--Wall collision heights
		local height_scale = (self.state == constants.state.roll) and 0.8 or 1
		local heights = {
			self.p.height * 0.85 * self.p.scale * height_scale,
			self.p.height * 1.25 * self.p.scale * height_scale,
			self.p.height * 1.95 * self.p.scale * height_scale,
		}
		
		--Wall collision and horizontal movement
		local xmove, zmove = true, true
		for i,v in pairs(heights) do
			if WallCollide(self, wl, v, self:GetLook(), self.spd.X, (self.flag.grounded or (self.spd.Y <= 0)) and (i == 1), false) == false then
				xmove = false
			end
			if WallCollide(self, wl, v, self:GetRight(), self.spd.Z, false, false) == false then
				zmove = false
			end
		end
		
		if xmove then
			self.pos += self:GetLook() * self.spd.X * self.p.scale
		end
		if zmove then
			self.pos += self:GetRight() * self.spd.Z * self.p.scale
		end
		
		--Ceiling collision
		local cup = self.p.height * self.p.scale
		local cdown = cup
		
		if self.spd.Y > 0 then
			cdown += self.spd.Y * self.p.scale --Moving upwards, extend raycast upwards
		elseif self.spd.Y < 0 then
			cup += self.spd.Y * self.p.scale --Moving downwards, move raycast downwards
		end
		
		local from = self.pos + self:GetUp() * cup
		local dir = self:GetUp() * cdown
		local hit, pos, nor = collision.Raycast(wl, from, dir)
		
		if hit then
			if self.flag.grounded then
				--Set ceiling clip flag
				self.flag.ceiling_clip = nor:Dot(self.gravity.unit) > 0.9
			else
				--Clip and cancel velocity
				self.pos = pos - (self:GetUp() * (self.p.height * 2 * self.p.scale))
				self.spd = LocalVelCancel(self, self.spd, nor)
				self.flag.ceiling_clip = false
			end
		else
			--Clear ceiling clip flag
			self.flag.ceiling_clip = false
		end
		
		--Floor collision
		local pos_error
		if self.v3 then
			pos_error = self.flag.grounded and (0.01) or ((self.spd.Y > 0) and 0 or (self.p.pos_error * self.p.scale))
		else
			pos_error = self.flag.grounded and (self.p.pos_error * self.p.scale) or 0
		end
		local fup = self.p.height * self.p.scale
		local fdown = -(fup + pos_error)
		
		if self.spd.Y < 0 then
			fdown += self.spd.Y * self.p.scale --Moving downwards, extend raycast downwards
		elseif self.spd.Y > 0 then
			fup += self.spd.Y * self.p.scale --Moving upwards, move raycast upwards
		end
		
		local from = self.pos + self:GetUp() * fup
		local dir = self:GetUp() * fdown
		local hit, pos, nor = collision.Raycast(wl, from, dir)
		
		--Do additional collision checks
		if hit then
			local drop = false
			
			if hit:FindFirstChild("NoFloor") then
				--Floor cannot be stood on under any conditions
				drop = true
			elseif self.flag.grounded then
				--Don't stay on the floor if we're going too slow on a steep floor
				if self:GetUp():Dot(nor) < 0.3 then
					drop = true
				elseif nor:Dot(-self.gravity.unit) < 0.4 then
					if ((self.spd.X ^ 2) + (self.spd.Z ^ 2)) < (1.16 ^ 2) then
						drop = true
					end
				end
			else
				--Don't collide with the floor if we won't land at a speed fast enough to stay on it
				local next_spd = vector.Flatten(self:ToGlobal(self.spd), nor)
				local next_ang = GetAligned(self, nor)
				local next_lspd = (next_ang:inverse() * next_spd) * Vector3.new(1, 0, 1)
				if nor:Dot(-self.gravity.unit) < 0.4 then
					if next_lspd.magnitude < 1.16 then
						drop = true
					end
				end
			end
			
			--Do simple collision
			if drop then
				self.spd = LocalVelCancel(self, self.spd, nor)
				self.pos = pos
				hit = nil
			end
		end
		
		--Do standard floor collision
		if hit then
			--Snap to ground
			self.pos = pos
			self.floor = hit
			
			--Align with ground
			if not (self.flag.grounded or self.v3) then
				self.spd = vector.Flatten(self:ToGlobal(self.spd), nor)
				
				self.flag.grounded = true
				AlignNormal(self, nor)
				
				self.spd = self:ToLocal(self.spd)
			else
				self.flag.grounded = true
				AlignNormal(self, nor)
			end
			
			--Kill any lingering vertical speed
			self.spd = vector.SetY(self.spd, 0)
		else
			--Move vertically and unground
			self.pos += self:GetUp() * self.spd.Y * self.p.scale
			self.flag.grounded = false
			self.floor = nil
		end
		
		--Check if we clipped through something from our previous position to our new position
		local new_mid = self:GetMiddle()
		if new_mid ~= prev_mid then
			local new_add = (new_mid - prev_mid).unit * (self.p.rad * self.p.scale)
			local new_end = new_mid-- + new_add
			local hit, pos, nor = collision.Raycast(wl, prev_mid, (new_end - prev_mid))
			if hit then
				--Clip us out
				self.pos += (pos - new_add) - new_mid
				self.spd = LocalVelCancel(self, self.spd * 0.8, nor)
			else
				break
			end
		else
			break
		end
	end
	
	--Check if we're submerged in water
	self.flag.underwater = PointInWater(self.pos + self:GetUp() * (self.p.height * self.p.scale))
	
	--Handle floor positioning
	if not self.v3 then
		if self.flag.grounded and self.floor ~= nil then
			self.floor_off = self.floor.CFrame:inverse() * (self.ang + self.pos)
			self.floor_last = self.floor.CFrame
			if self.floor_move == nil then
				self.floor_move = self.floor.Velocity / constants.framerate
			end
		else
			self.floor = nil
			self.floor_off = CFrame.new()
			self.floor_last = nil
			self:UseFloorMove()
		end
	else
		self.floor = nil
		self.floor_off = CFrame.new()
		self.floor_last = nil
		self.floor_move = nil
	end
	
	--Get final global speed
	self.gspd = self:ToGlobal(self.spd)
	
	--V3 ragdoll
	if self.v3 then
		ragdoll.Bounce(self, prev_spd, self.gspd)
	end
	
	debug.profileend()
end

return player_collision