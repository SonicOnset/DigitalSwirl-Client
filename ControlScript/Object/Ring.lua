--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Object/Ring.lua
Purpose: Ring object
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local ring = {}

local assets = script.Parent.Parent:WaitForChild("Assets")
local obj_assets = assets:WaitForChild("Ring")

--Object functions
local function Update(self, i)
	if self.collected then
		--Restore position once collect animation is over
		if self.draw == nil then
			self.object:SetPrimaryPartCFrame(self.og_cf)
			self.update = nil
		end
	elseif self.attract_player ~= nil then
		--Adjust speed
		local diff = self.attract_player:GetMiddle() - self.root.Position
		if diff.magnitude ~= 0 then
			local spd_accel = (self.spd * (0.925 + (self.attract_force * (1 - 0.925)))) + (diff.unit * 0.175 * self.attract_force)
			self.spd = spd_accel:Lerp(diff, self.attract_force)
		end
		
		--Increase attraction
		self.attract_force = math.min(self.attract_force + 0.005, 1)
		
		--Move
		self.object:SetPrimaryPartCFrame(self.root.CFrame + self.spd)
	end
end

local function Draw(self, dt)
	local done = true
	
	--Fade light
	if self.light.Brightness > 0 then
		self.light.Brightness = math.max(self.light.Brightness - (dt / 0.5), 0)
		done = false
	end
	
	--Destroy particle once lifetime is over
	if self.touch_particle ~= nil then
		self.touch_particle_life -= dt
		if self.touch_particle_life <= 0 then
			self.touch_particle:Destroy()
			self.touch_particle = nil
		else
			done = false
		end
	end
	
	--Stop running once done
	if done then
		self.draw = nil
	end
end

--Object contact
local function TouchPlayer(self, player)
	if player.v3 then
		return
	end
	
	--Change object state
	self.draw = Draw
	self.touch_player = nil
	
	--Give player ring and collect
	player:GiveScore(10)
	player:GiveRings(1)
	self.collected = true
	
	--Hide ring and destroy animation
	self.ring.LocalTransparencyModifier = 1
	if self.anim ~= nil then
		self.anim:Destroy()
		self.anim = nil
	end
	
	--Particle and sound
	if self.touch_particle ~= nil then
		self.touch_particle:Emit(20)
	end
	self.touch_sound:Play()
end

--Constructor and destructor
function ring:New(object)
	--Initialize meta reference
	local self = setmetatable({}, {__index = ring})
	
	--Use object information
	self.object = object
	self.root = object.PrimaryPart
	self.ring = object:WaitForChild("Ring")
	self.light = self.ring:WaitForChild("PointLight")
	self.light_brightness = self.light.Brightness
	self.anim_controller = object:WaitForChild("AnimationController")
	
	--Remember ring object position
	self.og_cf = self.ring.CFrame
	
	--Create touch sound and particle
	self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
	self.touch_sound.Parent = self.root
	self.particle_attachment = Instance.new("Attachment", self.root)
	self.touch_particle = obj_assets:WaitForChild("TouchParticle"):clone()
	self.touch_particle.Parent = self.particle_attachment
	self.touch_particle_life = self.touch_particle.Lifetime.Max
	
	--Create and play animation
	self.anim = self.anim_controller:LoadAnimation(obj_assets:WaitForChild("Anim"))
	self.anim:Play()
	
	--Attach functions
	self.touch_player = TouchPlayer
	
	--Set state
	self.spd = Vector3.new()
	self.attract_force = 0
	self.attract_player = nil
	self.collected = false
	
	return self
end

function ring:Destroy()
	--Restore ring visibility and light
	if self.collected then
		self.ring.LocalTransparencyModifier = 0
		if self.light ~= nil then
			self.light.Brightness = self.light_brightness
		end
	end
	
	--Destroy animation
	if self.anim ~= nil then
		self.anim:Destroy()
		self.anim = nil
	end
	
	--Destroy sound and particles
	if self.touch_sound ~= nil then
		self.touch_sound:Destroy()
		self.touch_sound = nil
	end
	if self.particle_attachment ~= nil then
		self.particle_attachment:Destroy()
		self.particle_attachment = nil
	end
	
	--Restore ring position
	if self.update ~= nil then
		self.object:SetPrimaryPartCFrame(self.og_cf)
	end
end

function ring:Attract(player)
	self.attract_player = player
	self.update = Update
end

return ring