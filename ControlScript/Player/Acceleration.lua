--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/Acceleration.lua
Purpose: Player acceleration functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_acceleration = {}

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local vector = require(common_modules:WaitForChild("Vector"))

local input = require(script.Parent:WaitForChild("Input"))
local sound = require(script.Parent:WaitForChild("Sound"))
local movement = require(script.Parent:WaitForChild("Movement"))

--Ground movement interface
function player_acceleration.GetAcceleration(self)
	--Get physics values
	local weight = self:GetWeight()
	local max_x_spd = self:GetMaxXSpeed()
	local run_accel = self:GetRunAccel() * (self.v3 and 1.5 or 1)
	local frict_mult = self.flag.grounded and self.frict_mult or 1
	
	--Get gravity force
	local acc = self:ToLocal(self.gravity * weight)
	
	--Get cross product between our moving velocity and floor normal
	local tnorm_cross_velocity = self.floor_normal:Cross(self:ToGlobal(self.spd))
	
	--Amplify gravity
	if self.dotp < 0.875 then
		if self.dotp >= 0.1 or math.abs(tnorm_cross_velocity.Y) <= 0.6 or self.spd.X < 1.16 then
			if self.dotp >= -0.4 or self.spd.X <= 1.16 then
				if self.dotp < -0.3 and self.spd.X > 1.16 then
					--acc = vector.AddY(acc, weight * -0.8)
				elseif self.dotp < -0.1 and self.spd.X > 1.16 then
					--acc = vector.AddY(acc, weight * -0.4)
				elseif self.dotp < 0.5 and math.abs(self.spd.X) < self.p.run_speed then
					acc = vector.MulX(acc, 4.225)
					acc = vector.MulZ(acc, 4.225)
				elseif self.dotp >= 0.7 or math.abs(self.spd.X) > self.p.run_speed then
					if self.dotp >= 0.87 or self.p.jog_speed <= math.abs(self.spd.X) then
						--acc = acc
					else
						acc = vector.MulZ(acc, 1.4)
					end
				else
					acc = vector.MulZ(acc, 2)
				end
			else
				--acc = vector.AddY(acc, weight * -5)
			end
		else
			acc = Vector3.new(0, -weight, 0)
		end
	else
		acc = Vector3.new(0, -weight, 0)
	end
	
	--Get analogue state
	local has_control, analogue_turn, analogue_mag = input.GetAnalogue(self)
	
	--Air drag
	if self.v3 ~= true then
		--X air drag
		local spd_x = self.spd.X
		
		if has_control then
			if spd_x <= max_x_spd or self.dotp <= 0.96 then
				if spd_x > max_x_spd then
					acc = vector.AddX(acc, (spd_x - max_x_spd) * self.p.air_resist)
				elseif spd_x < 0 then
					acc = vector.AddX(acc, spd_x * self.p.air_resist)
				end
			else
				acc = vector.AddX(acc, (spd_x - max_x_spd) * (self.p.air_resist * 1.7))
			end
		else
			if spd_x > self.p.run_speed then
				acc = vector.AddX(acc, spd_x * self.p.air_resist)
			elseif spd_x > max_x_spd then
				acc = vector.AddX(acc, (spd_x - max_x_spd) * self.p.air_resist)
			elseif spd_x < 0 then
				acc = vector.AddX(acc, spd_x * self.p.air_resist)
			end
		end
		
		--Y and Z air drag
		self.spd += self.spd * Vector3.new(0, self:GetAirResistY(), self.p.air_resist_z)
	else
		self.spd = vector.AddZ(self.spd, self.spd.Z * self.p.air_resist_z)
	end
	
	--Movement
	if has_control then
		--Get acceleration
		if self.spd.X >= max_x_spd then
			--Use lower acceleration if above max speed
			if self.spd.X < max_x_spd or self.dotp >= 0 then
				move_accel = run_accel * analogue_mag * 0.4
			else
				move_accel = run_accel * analogue_mag
			end
		else
			--Get acceleration, stopping at intervals based on analogue stick magnitude
			move_accel = 0
			
			if self.spd.X >= self.p.jog_speed then
				if self.spd.X >= self.p.run_speed then
					if self.spd.X >= self.p.rush_speed then
						move_accel = run_accel * analogue_mag
					elseif analogue_mag <= 0.9 then
						move_accel = run_accel * analogue_mag * 0.3
					else
						move_accel = run_accel * analogue_mag
					end
				elseif analogue_mag <= 0.7 then
					if self.spd.X < self.p.run_speed then
						move_accel = run_accel * analogue_mag
					end
				else
					move_accel = run_accel * analogue_mag
				end
			elseif analogue_mag <= 0.5 then
				if self.spd.X < (self.p.jog_speed + self.p.run_speed) * 0.5 then
					move_accel = run_accel * analogue_mag
				end
			else
				move_accel = run_accel * analogue_mag
			end
		end
		
		--Turning
		local diff_angle = math.abs(analogue_turn)
		local forward_speed = self.spd.X
		
		if math.abs(forward_speed) < 0.001 and diff_angle > math.rad(22.5) then
			move_accel = 0
			self:AdjustAngleYQ(analogue_turn)
		else
			if forward_speed < (self.p.jog_speed + self.p.run_speed) * 0.5 or diff_angle <= math.rad(22.5) then
				if forward_speed < self.p.jog_speed or diff_angle >= math.rad(22.5) then
					if forward_speed < self.p.dash_speed or not self.flag.grounded then
						if forward_speed >= self.p.jog_speed and forward_speed <= self.p.rush_speed and diff_angle > math.rad(45) then
							move_accel *= 0.8
						end
						self:AdjustAngleY(analogue_turn)
					else
						self:AdjustAngleYS(analogue_turn)
					end
				else
					self:AdjustAngleYS(analogue_turn)
				end
			else
				move_accel = self.p.slow_down * (self.v3 and 0 or 1) / frict_mult
				self:AdjustAngleY(analogue_turn)
			end
		end
	else
		--Decelerate
		move_accel = movement.GetDecel(self.spd.X + acc.X, self.p.slow_down * (self.v3 and 4 or 1))
	end
	
	--Apply movement acceleration
	if self.v3 then
		if self.spd.X * math.sign(move_accel) > (self.flag.underwater and 2 or 4) then
			move_accel = 0
		end
	end
	acc = vector.AddX(acc, move_accel * frict_mult)
	
	--Apply acceleration
	self.spd += acc
end

function player_acceleration.GetAirAcceleration(self)
	--Get analogue state
	local has_control, analogue_turn, analogue_mag = input.GetAnalogue(self)
	
	--Gravity
	local weight
	if (self.dashring_timer > 0) or (self.spring_timer > 0 and self.flag.scripted_spring == true) then
		weight = 0
	else
		weight = self:GetWeight()
	end
	
	self.spd += self:ToLocal(self.gravity) * weight
	
	--Air drag
	if self.v3 ~= true then
		self.spd += self.spd * Vector3.new(
			self.p.air_resist_air,
			self:GetAirResistY(),
			self.p.air_resist_z
		) / (1 + self.rail_trick)
	else
		self.spd = vector.AddZ(self.spd, self.spd.Z * self.p.air_resist_z)
	end
	
	--Use lighter gravity if A is held or doing a rail trick
	if (self.rail_trick > 0) or (self.jump_timer > 0 and self.flag.ball_aura and self.input.button.jump) then
		self.jump_timer = math.max(self.jump_timer - 1, 0)
		self.spd = vector.AddY(self.spd, self.p.jmp_addit * 0.8 * (1 + self.rail_trick / 2))
	end
	
	--Get our acceleration
	local accel
	if self.rail_trick > 0 then
		--Constant acceleration
		accel = self.p.air_accel * (1 + self.rail_trick / 2.5)
		self.last_turn = 0
	elseif not has_control then
		--No acceleration
		if self.v3 then
			accel = movement.GetDecel(self.spd.X, self.p.slow_down * 2)
		else
			accel = 0
		end
	else
		--Check if we should "skid"
		if (self.spd.X <= self.p.run_speed) or (math.abs(analogue_turn) <= math.rad(135)) then
			if math.abs(analogue_turn) <= math.rad(22.5) then
				if self.spd.Y >= 0 then
					accel = self.p.air_accel * analogue_mag
				else
					accel = self.p.air_accel * 2 * analogue_mag
				end
			else
				accel = 0
			end

			self:AdjustAngleY(analogue_turn)
		else
			--Air brake
			accel = self.p.air_break * analogue_mag
		end
	end
	
	--Accelerate
	if self.v3 and accel > 0 then
		accel *= 2
	end
	self.spd = vector.AddX(self.spd, accel)
end

return player_acceleration