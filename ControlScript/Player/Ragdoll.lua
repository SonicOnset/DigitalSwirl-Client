--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/Ragdoll.lua
Purpose: Player ragdoll functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_ragdoll = {}

local sound = require(script.Parent:WaitForChild("Sound"))

function player_ragdoll.Bounce(self, pspd, nspd)
	--Bounce
	local diff = nspd - pspd
	self.spd = self:ToLocal(nspd + diff * (0.5 + math.random() * 0.35))
	
	--Enter ragdoll if bounced hard
	if diff.magnitude > 6 and self.state ~= "Ragdoll" then
		--Enter ragdoll state
		self.do_ragdoll = true--self.state = "Ragdoll"
		self.ragdoll_time = 0
		sound.PlaySound(self, "Trip")
	end
	
	if diff.magnitude > 1 then
		--Angle speed
		local ang_force = self.spd.magnitude / 20
		self.ragdoll_ang_spd = CFrame.Angles((math.random() * 2 - 1) * ang_force, (math.random() * 2 - 1) * ang_force, (math.random() * 2 - 1) * ang_force)
	end
end

function player_ragdoll.Physics(self)
	--Gravity and air drag
	self.spd += self:ToLocal(self.gravity) * self.p.weight
	self.spd *= 0.995
	
	--Rotate
	local gspd = self:ToGlobal(self.spd)
	self.flag.grounded = false
	self:SetAngle(self.ang * self.ragdoll_ang_spd)
	self.spd = self:ToLocal(gspd)
	
	--Check if we should stop
	if self.spd.magnitude < 1 then
		self.ragdoll_time += 1
		if self.ragdoll_time > 60 then
			sound.PlaySound(self, "GetUp")
			return true
		end
	else
		self.ragdoll_time = math.max(self.ragdoll_time - 1, 0)
	end
	return false
end

return player_ragdoll