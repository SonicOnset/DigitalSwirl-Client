--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/Rail.lua
Purpose: Player Rail Grinding functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_rail = {}

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local input = require(script.Parent:WaitForChild("Input"))
local constants = require(script.Parent.Parent:WaitForChild("Constants"))
local vector = require(common_modules:WaitForChild("Vector"))
local collision = require(common_modules:WaitForChild("Collision"))
local spatial_partitioning = require(common_modules:WaitForChild("SpatialPartitioning"))
local sound = require(script.Parent:WaitForChild("Sound"))
local global_reference = require(common_modules:WaitForChild("GlobalReference"))

local rails_reference = global_reference:New(workspace, "Level/Rails")

--Common functions
local function lerp(x, y, z)
	return x + (y - x) * z
end

--Rail connection
local ChildAddedFunction = nil --prototype
local ChildRemovedFunction = nil --prototype

local function ConnectFolder(self, p)
	--Recursively connect subfolders and initialize already existing objects
	for _, v in pairs(p:GetChildren()) do
		ChildAddedFunction(self, v)
	end
	
	--Connect for child creation and deletion
	table.insert(self.rail_cons, p.ChildAdded:Connect(function(v)
		ChildAddedFunction(self, v)
	end))
	table.insert(self.rail_cons, p.ChildRemoved:Connect(function(v)
		ChildRemovedFunction(self, v)
	end))
end

--Connection functions
ChildAddedFunction = function(self, v)
	if v:IsA("Folder") or v:IsA("Model") then
		ConnectFolder(self, v)
	elseif v:IsA("Part") then
		self.rail_spatial_partitioning:Add(v)
	end
end

ChildRemovedFunction = function(self, v)
	if v:IsA("Part") then
		self.rail_spatial_partitioning:Remove(v)
	end
end

--Rail interface
function player_rail.Initialize(self)
	--Initialize spatial partitioning
	self.rail_cons = {}
	self.rail_spatial_partitioning = spatial_partitioning:New(16)
	ConnectFolder(self, workspace:WaitForChild("Level"):WaitForChild("Rails"))
end

function player_rail.Quit(self)
	--Destroy spatial partitioning
	if self.rail_spatial_partitioning ~= nil then
		self.rail_spatial_partitioning:Destroy()
		self.rail_spatial_partitioning = nil
	end
	
	--Disconnect connections
	if self.rail_cons ~= nil then
		for _, v in pairs(self.rail_cons) do
			v:Disconnect()
		end
		self.rail_cons = nil
	end
end

function player_rail.GetRailsInRegion(self, region)
	debug.profilebegin("player_rail.GetRailsInRegion")
	
	local hit_rails
	local rails = rails_reference:Get()
	if rails ~= nil then
		hit_rails = self.rail_spatial_partitioning:GetPartsInRegion(region)
	else
		hit_rails = {}
	end
	
	debug.profileend()
	return hit_rails
end

function player_rail.GetTouchingRail(self)
	debug.profilebegin("player_rail.GetTouchingRail")
	
	--Get player collision and get rails in region
	local radius = self.p.height * self.p.scale
	local center = self.pos + self:GetUp() * radius
	
	local sphere = {
		center = center,
		radius = radius,
	}
	
	local region = Region3.new(
		center - Vector3.new(radius, radius, radius),
		center + Vector3.new(radius, radius, radius)
	)
	
	local rails = player_rail.GetRailsInRegion(self, region)
	
	local hit = nil
	for _,v in pairs(rails) do
		--Check for collision
		if collision.TestSphereRotatedBox(sphere, {cframe = v.CFrame, size = v.Size}) then
			--Check if we should collide with this rail
			if self.flag.grounded then
				local up = v.CFrame.UpVector
				local top = v.Position + up * (v.Size.Y / 2)
				if (center - top):Dot(up) < 0 and not self.v3 then
					continue
				end
			end
			hit = v
			break
		end
	end
	
	debug.profileend()
	return hit
end

function player_rail.GetAngle(self)
	if self.rail ~= nil then
		return self:AngleFromRbx((self.rail.CFrame - self.rail.Position) * CFrame.Angles(0, (self.rail_dir >= 0) and 0 or math.pi, 0))
	end
	return self.ang
end

function player_rail.GetPosition(self)
	local local_pos = self.rail.CFrame:inverse() * self.pos
	return self.rail.CFrame * Vector3.new(0, self.rail.Size.Y / 2, local_pos.Z)
end

function player_rail.SetRail(self, rail)
	if rail ~= nil then
		--Get orientation to use
		local dir_dot = self:GetLook():Dot(rail.CFrame.LookVector)
		local spd_dot = self:ToGlobal(self.spd):Dot(rail.CFrame.LookVector)
		local rail_dir = (dir_dot ~= 0) and math.sign(dir_dot) or ((spd_dot ~= 0) and math.sign(spd_dot) or 1)
		
		if self.rail == nil then
			--Set player state
			self:ResetObjectState()
			self:Land()
			self.state = constants.state.rail
			
			--Set rail state
			self.rail = rail
			self.rail_dir = rail_dir
			self.rail_balance = 0
			self.rail_tgt_balance = 0
			self.rail_balance_fail = 0
			self.rail_off = Vector3.new()
			self.rail_trick = 0
			self.rail_snd = false
			self.rail_grace = nil
			self.rail_bonus_time = 0
			
			--Get angle and speed
			local prev_spd = self:ToGlobal(self.spd)
			self:SetAngle(player_rail.GetAngle(self))
			self.spd = self:ToLocal(prev_spd) * Vector3.new(1, 0, 0)
			
			--Set animation
			if math.abs(self.spd.X) < self.p.jog_speed and self:ToLocal(prev_spd).Y < -2 then
				self.animation = "RailLand"
			else
				self.animation = "Rail"
			end
			
			--Project position onto rail
			self.pos = player_rail.GetPosition(self)
		elseif self.rail ~= rail then
			--Set rail state
			local dot = math.clamp(self.rail.CFrame.RightVector:Dot(rail.CFrame.LookVector), -0.999, 0.999)
			self.rail = rail
			self.rail_dir = rail_dir
			local balance = math.asin(dot) * (self.spd.X / 10)
			self.rail_balance = math.clamp(self.rail_balance - balance * 1.625, math.rad(-80), math.rad(80))
			self.rail_tgt_balance = math.clamp(self.rail_tgt_balance + balance * 1.125, math.rad(-70), math.rad(70))
			
			--Get angle and project position
			self:SetAngle(player_rail.GetAngle(self))
			self.pos = player_rail.GetPosition(self)
		else
			return
		end
		
		--Use rail information
		if self.v3 ~= true and self.rail.Parent:FindFirstChild("Balance") then
			self.rail_do_balance = self.rail.Parent.Balance.Value
		else
			self.rail_do_balance = false
		end
	elseif self.rail ~= nil then
		--Release from rail state
		self.rail = nil
		self.rail_debounce = 10
		
		--Stop sound
		sound.StopSound(self, "Grind")
	end
end

function player_rail.CollideRails(self)
	debug.profilebegin("player_rail.CollideRails")
	
	if self.rail_debounce <= 0 then
		--Get touching rail and set player onto it if found
		local rail = player_rail.GetTouchingRail(self)
		if rail ~= nil then
			player_rail.SetRail(self, rail)
		end
	end
	
	debug.profileend()
	return self.state == constants.state.rail
end

function player_rail.GrindActive(self)
	return self.state == constants.state.rail and self.rail_off.magnitude < 0.5
end

function player_rail.CheckSwitch(self)
	if self.rail ~= nil and math.abs(self.input.stick_x) > 0.675 and self.spd.X ~= 0 then
		if self.v3 ~= true then
			--Get switch direction
			local dir = math.sign(self.input.stick_x) * math.sign(self.spd.X) * self.rail_dir
			
			--Get position along rail
			local local_pos = self.rail.CFrame:inverse() * self.pos
			local along_pos = self.rail.CFrame * (local_pos * Vector3.new(0, 0, 1))
			local switch_dir = self.rail.CFrame.RightVector * dir
			
			--Perform raycast
			local hit = collision.Raycast({rails_reference:Get()}, along_pos + switch_dir, switch_dir * 9)
			if hit ~= nil then
				--Switch to rail
				local prev_pos = self.pos
				player_rail.SetRail(self, hit)
				self.rail_grace = nil
				self.rail_off = prev_pos - self.pos
				
				--Give score bonus if at high speed
				if math.abs(self.spd.X) >= 8 then
					self:GiveScore(200)
				end
				return true
			end
		else
			self.spd = vector.SetZ(self.spd, self.input.stick_x * 8)
		end
	end
	return false
end

function player_rail.CheckTrick(self)
	if self.v3 ~= true and (self.spd.X * self.rail_dir) > 0 and self.rail ~= nil then
		--Get rail's trick value
		local trick = self.rail:FindFirstChild("Trick")
		if trick ~= nil then
			trick = trick.Value
		else
			return false
		end
		
		--Amplify trick based off speed
		trick = math.min((trick * math.abs(self.spd.X) / 15) - 0.5, 1)
		if trick < 0 then
			return false
		end
		
		--Give points bonus
		self:GiveScore(math.min(500 + math.floor(trick * 300) * 10, 3500))
		
		--Play trick animation and set state
		if trick > 0.675 then
			self.animation = "TrickRail1"
		elseif trick > 0.425 then
			self.animation = "TrickRail2"
		elseif trick > 0.1 then
			self.animation = "TrickRail3"
		else
			self.animation = "TrickRail4"
		end
		self.rail_trick = 0.35 + trick * 1.125
		
		--Jump off
		player_rail.SetRail(self, nil)
		self.rail_debounce = 30
		self.state = constants.state.airborne
		self.flag.air_kick = true
		if self.spd.X < 0 then
			self:Turn(math.pi)
			self.spd *= -1
		end
		self.spd *= (1 + self.rail_trick * 0.35)
		return true
	end
	return false
end

function player_rail.Movement(self)
	--Immediately quit if not on a rail
	if self.rail == nil then
		return true
	end
	
	--Get grinding state
	local crouch = self.input.button.roll
	
	--Gravity
	local weight
	if self.flag.underwater then
		weight = self.p.weight * 0.45
	else
		weight = self.p.weight
	end
	
	local gravity = (self:ToLocal(self.gravity) * weight).X
	
	--Amplify gravity
	if math.sign(gravity) == math.sign(self.spd.X) then
		--Have stronger gravity when gravity is working with us
		gravity *= (1.125 + (math.abs(self.spd.X) / 8))
	elseif self.v3 == true then
		--No gravity working against you in SEO v3 mode
		gravity = Vector3.new()
	else
		--Have weaker gravity when gravity is working against us
		gravity *= (0.5 / (1 + (math.abs(self.spd.X) / 3.5))) * (crouch and 0.75 or 1)
	end
	
	--Get drag factor
	local off = self.rail_balance - self.rail_tgt_balance
	self.rail_tgt_balance *= 0.875
	
	local drag_factor
	if self.v3 == true then
		drag_factor = 0
	elseif self.rail_do_balance then
		drag_factor = 0.5 + (1 - math.cos(math.clamp(off, -math.pi / 2, math.pi / 2))) * 3.125
	else
		drag_factor = 0.95
	end
	
	--Apply gravity and drag
	self.spd = vector.AddX(self.spd, gravity)
	self.spd = vector.AddX(self.spd, self.spd.X * self.p.air_resist * (crouch and 0.675 or 0.875) * drag_factor)
	
	--Make sure player is at a minimum speed
	if self.spd.X == 0 then
		self.spd = vector.SetX(self.spd, self.p.jog_speed)
	elseif math.abs(self.dotp) > 0.95 then
		self.spd = vector.SetX(self.spd, math.max(math.abs(self.spd.X), self.p.jog_speed) * math.sign(self.spd.X))
	end
	
	--Give rail bonus at high speed
	if math.abs(self.spd.X) >= 8 then
		self.rail_bonus_time += 1
		if self.rail_bonus_time >= 60 then
			self:GiveScore((self.spd.X < 0) and 1000 or 700)
			self.rail_bonus_time = 0
		end
	else
		self.rail_bonus_time = math.max(self.rail_bonus_time - 2, 0)
	end
	
	--Balancing
	local stick_x = self.input.stick_x * math.clamp(self.spd.X, -1, 1)
	if player_rail.GrindActive(self) and self.rail_do_balance then
		--Drag balance
		local drag_factor = lerp(math.cos(self.rail_tgt_balance), 1, 0.25)
		self.rail_balance *= lerp(1, crouch and 0.9675 or 0.825, drag_factor)
		
		--Adjust balance using analogue stick
		local adjust_force
		if math.sign(self.rail_balance) == math.sign(stick_x) then
			adjust_force = math.cos(self.rail_balance) * 1.2125
		else
			adjust_force = 1.6125 + math.abs(self.rail_balance / 1.35)
		end
		adjust_force *= crouch and 0.8975 or 1
		
		self.rail_balance += stick_x * adjust_force * math.rad(3.5 + math.abs(self.spd.X) / 2.825)
		if math.sign(stick_x) == math.sign(self.rail_tgt_balance) then
			local off = (self.rail_tgt_balance - self.rail_balance)
			self.rail_balance += off * math.abs(stick_x) * math.abs(math.sin(self.rail_tgt_balance)) * 0.15
		end
	else
		--Balancing disabled
		self.rail_balance *= 0.825
	end
	
	--Move
	self.pos += self:ToGlobal(self.spd) * self.p.scale
	self.rail_off *= 0.8
	
	--Balance failing
	if math.abs(self.rail_balance - self.rail_tgt_balance) >= math.rad(55) then
		self.rail_balance_fail = math.min(self.rail_balance_fail + 0.1, 1)
	else
		self.rail_balance_fail = math.max(self.rail_balance_fail - 0.04, 0)
	end
	
	--Run sound
	local new_snd = player_rail.GrindActive(self)
	if new_snd then
		if not self.rail_snd then
			sound.PlaySound(self, "GrindContact")
			sound.PlaySound(self, "Grind")
		end
		sound.SetSoundVolume(self, "Grind", math.sqrt(math.abs(self.spd.X) / 8))
	else
		if self.rail_snd then
			sound.StopSound(self, "GrindContact")
			sound.StopSound(self, "Grind")
		end
	end
	self.rail_snd = new_snd
	
	--Set animation
	if player_rail.GrindActive(self) then
		if self.animation ~= "RailLand" then
			if self.rail_balance_fail >= 0.3 then
				self.animation = "RailBalance"
			else
				self.animation = crouch and "RailCrouch" or "Rail"
				self.anim_speed = self.spd.X
			end
		end
	else
		local loc_off = self:AngleToRbx(self.ang):inverse() * self.rail_off
		if loc_off.X < 0 then
			self.animation = "RailSwitchLeft"
		elseif loc_off.X > 0 then
			self.animation = "RailSwitchRight"
		end
	end
	
	if self.rail_grace ~= nil then
		--Release from rail after grace period
		self.rail_grace = math.max(self.rail_grace - 1, 0)
		if self.rail_grace <= 0 then
			player_rail.SetRail(self, nil)
			return true
		end
	else
		--Handle keeping us on the rail (and subsequent rails)
		while true do
			--Project position onto rail
			self.pos = player_rail.GetPosition(self)
			self.ang = player_rail.GetAngle(self)
			
			--Check if we should go to next rail (or fly off with there being no rail to go to)
			local dir = self.rail_dir * math.sign(self.spd.X)
			local local_pos = self.rail.CFrame:inverse() * self.pos
			if self.spd.X ~= 0 and (local_pos.Z * -dir) > self.rail.Size.Z / 2 then
				--Do raycast
				local hit = collision.Raycast({rails_reference:Get()}, self.rail.Position, self.rail.CFrame.LookVector * ((self.rail.size.Z / 2) + 1) * dir)
				if hit == nil then
					self.rail_grace = 1 + math.floor(math.abs(self.spd.X) / 3.5)
					break
				else
					player_rail.SetRail(self, hit)
				end
			else
				break
			end
		end
	end
	return false
end

return player_rail