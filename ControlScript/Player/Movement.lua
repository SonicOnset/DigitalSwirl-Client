--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/Movement.lua
Purpose: Player movement functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_movement = {}

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local vector = require(common_modules:WaitForChild("Vector"))
local cframe = require(common_modules:WaitForChild("CFrame"))

local input = require(script.Parent:WaitForChild("Input"))

--Acceleration functions
function player_movement.GetDecel(spd, dec)
	if spd > 0 then
		return -math.min(spd, -dec)
	elseif spd < 0 then
		return math.min(-spd, -dec)
	end
	return 0
end

--Rotation / turning
function player_movement.RotatedByGravity(self)
	local a1a = self:ToGlobal(self.spd)
	local dotp = (a1a.unit):Dot(self.gravity.unit)
	
	if a1a.magnitude <= self.p.jog_speed or dotp >= -0.86 then
		local a2a = self:ToLocal(self.gravity.unit)
		
		if a2a.Y <= 0 and a2a.y > -0.87 then
			--Get turn
			if a2a.X < 0 then
				a2a = vector.MulX(a2a, -1)
			end
			
			local turn = -math.atan2(a2a.Z, a2a.X)
			
			--Get max turn
			if a2a.Z < 0 then
				a2a = vector.MulZ(a2a, -1)
			end
			
			local max_turn
			if self.flag.ball_aura then
				max_turn = a2a.Z * math.rad(16.875)
			else
				max_turn = a2a.Z * math.rad(8.4375)
			end
			
			--Turn
			turn = math.clamp(turn, -max_turn, max_turn)
			return self:Turn(turn)
		end
	end
	return 0
end

function player_movement.RotatedByGravityS(self)
	local a1a = self:ToGlobal(self.spd)
	
	if a1a.magnitude > self.p.jog_Speed then
		local dotp = (a1a.unit):Dot(self.gravity.unit)
		
		if dotp > -0.86 then
			local a2a = self:ToLocal(self.gravity.unit)
			
			if a2a.Y > -0.87 then
				--Get turn
				if a2a.X < 0 then
					a2a = vector.MulX(a2a, -1)
				end
				
				local turn = -math.atan2(a2a.Z, a2a.X)
				
				--Get max turn
				if a2a.Z < 0 then
					a2a = vector.MulZ(a2a, -1)
				end
				
				local max_turn
				if self.flag.ball_aura then
					max_turn = math.abs((self.spd.X / self.p.jog_speed) * a2a.Z * math.rad(22.5))
				else
					max_turn = a2a.Z * math.rad(11.25)
				end
				
				--Turn
				turn = math.clamp(turn, -max_turn, max_turn)
				return self:Turn(turn)
			end
		end
	end
	return 0
end

function player_movement.GetRotation(self)
	--Get analogue state
	local has_control, analogue_turn, analogue_mag = input.GetAnalogue(self)
	
	if has_control then
		--Turn
		if self.v3 then
			self:Turn(analogue_turn)
		else
			self:AdjustAngleY(analogue_turn)
		end
	end
end

function player_movement.AlignToGravity(self)
	if self.spd.magnitude < self.p.dash_speed then
		--Remember previous speed
		local prev_spd = self:ToGlobal(self.spd)
		
		--Get next angle
		local from = self:GetUp()
		local to = -self.gravity.unit
		local turn = vector.Angle(from, to)
		
		if turn ~= 0 then
			local max_turn = math.rad(11.25)
			local lim_turn = math.clamp(turn, -max_turn, max_turn)
			
			local next_ang = cframe.FromToRotation(from, to) * self.ang
			
			self:SetAngle(self.ang:Lerp(next_ang, lim_turn / turn))
		end
		
		--Keep using previous speed
		self.spd = self:ToLocal(prev_spd)
	end
end

--Acceleration / friction
function player_movement.GetSkidSpeed(self)
	--Get physics values
	local weight = self:GetWeight()
	
	--Get gravity force
	local acc = self:ToLocal(self.gravity * weight)
	
	--Air drag
	if self.v3 ~= true then
		self.spd += self.spd * Vector3.new(
			self.p.air_resist,
			self:GetAirResistY(),
			self.p.air_resist_z
		)
	else
		self.spd += self.spd * Vector3.new(
			-1,
			0,
			self.p.air_resist_z
		)
	end
	
	--Friction
	local x_frict = self.p.run_break * self.frict_mult
	local z_frict = self.p.grd_frict_z * self.frict_mult
	local x_accel = player_movement.GetDecel(self.spd.X + acc.X, x_frict)
	local z_accel = player_movement.GetDecel(self.spd.Z + acc.Z, z_frict)
	
	--Apply acceleration
	acc += Vector3.new(x_accel, 0, z_accel)
	self.spd += acc
end

function player_movement.GetInertia(self)
	--Gravity
	local weight = self:GetWeight()
	local acc = self:ToLocal(self.gravity) * weight
	
	--Amplify gravity
	if self.flag.grounded and self.spd.X > self.p.run_speed and self.dotp < 0 then
		acc = vector.MulY(acc, -8)
	end
	
	--Air drag
	if self.flag.ball_aura and self.dotp < 0.98 then
		acc = vector.AddX(acc, self.spd.X * -0.0002)
	else
		acc = vector.AddX(acc, self.spd.X * self.p.air_resist)
	end
	acc = vector.AddY(acc, self.spd.Y * self.p.air_resist_y)
	acc = vector.AddZ(acc, self.spd.Z * self.p.air_resist_z)
	
	--Apply acceleration
	self.spd += acc
end

return player_movement