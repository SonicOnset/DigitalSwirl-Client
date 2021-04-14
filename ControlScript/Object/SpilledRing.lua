--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Object/SpilledRing.lua
Purpose: Spilled Ring object
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local spilled_ring = {}

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local vector = require(common_modules:WaitForChild("Vector"))
local collision = require(common_modules:WaitForChild("Collision"))
local global_reference = require(common_modules:WaitForChild("GlobalReference"))

local constants = require(script.Parent.Parent:WaitForChild("Constants"))

local collision_reference = global_reference:New(workspace, "Level/Map/Collision")

local assets = script.Parent.Parent:WaitForChild("Assets")
local obj_assets = assets:WaitForChild("Ring")

--Constants
local drag = 0.98
local gravity = Vector3.new(0, 0.025, 0)
local tick_rate = 4
local collect_time = 60 * 0.75
local destroy_time = 60 * 10
local flicker_time = 60 * 8

--Object functions
local function GetNextPos(self, inc)
	if inc.magnitude > 0.01 then
		--Get collision whitelist
		local wl = {workspace.Terrain, collision_reference:Get()}
		
		--Perform collision raycasts
		local clip_off = Vector3.new(0, -1.125, 0)
		
		local elips = inc.unit * 0.01
		local hit, pos, nor = collision.Raycast(wl, (self.root.Position + clip_off) - elips, inc + elips)
		if hit then
			--Bounce
			local perp_spd = self.spd:Dot(nor)
			local surf_spd = vector.PlaneProject(self.spd, nor)
			self.spd = (surf_spd * 0.9) + (nor * perp_spd * -0.925)
		end
		
		--[[
		local hit2, pos2 = collision.Raycast(wl, pos - clip_off, clip_off)
		if hit2 then
			return pos2 - clip_off
		end
		--]]
		
		return pos - clip_off
	end
	return self.root.Position
end

local function Update(self, i)
	--Update ring appropriately
	local sub_tick = i % tick_rate
	
	if sub_tick == 0 then
		--Drag and fall
		self.spd *= drag ^ tick_rate
		self.spd -= gravity * tick_rate
		
		--Get next position and sub speed
		local next_pos = GetNextPos(self, self.spd * tick_rate)
		self.sub_spd = (next_pos - self.root.Position) / tick_rate
	elseif self.sub_spd == nil then
		--Get ticks to simulate
		local sim_ticks = tick_rate - sub_tick
		
		--Drag and fall
		self.spd *= drag ^ sim_ticks
		self.spd -= gravity * sim_ticks
		
		--Get next position and sub speed
		local next_pos = GetNextPos(self, self.spd * sim_ticks)
		self.sub_spd = (next_pos - self.root.Position) / sim_ticks
	end
	
	--Move
	self.object:SetPrimaryPartCFrame(self.root.CFrame + self.sub_spd)
	
	--Destroy object after timer runs out
	self.time += 1
	if self.time >= destroy_time then
		local object = self.object
		self.object = nil
		object:Destroy()
	end
end

local function Draw(self, dt)
	if self.collected then
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
		
		--Destroy once done
		if done then
			local object = self.object
			self.object = nil
			object:Destroy()
		end
	else
		--Flicker
		if self.time >= flicker_time then
			self.ring.LocalTransparencyModifier = 1 - self.ring.LocalTransparencyModifier
		end
	end
end

--Object contact
local function TouchPlayer(self, player)
	if player.v3 then
		return
	end
	
	if self.time >= collect_time then
		--Change object state
		self.update = nil
		self.touch_player = nil
		
		--Give player ring and collect
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
end

--Constructor and destructor
function spilled_ring:New(object)
	--Initialize meta reference
	local self = setmetatable({}, {__index = spilled_ring})
	
	--Use object information
	self.object = object
	self.root = object.PrimaryPart
	self.ring = object:WaitForChild("Ring")
	self.light = self.ring:WaitForChild("PointLight")
	self.light_brightness = self.light.Brightness
	self.anim_controller = object:WaitForChild("AnimationController")
	
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
	self.update = Update
	self.draw = Draw
	self.touch_player = TouchPlayer
	
	--Set state
	self.time = 0
	self.spd = self.root.Velocity / constants.framerate
	self.sub_spd = nil
	self.collected = false
	
	return self
end

function spilled_ring:Destroy()
	--Destroy object
	if self.object ~= nil then
		self.object:Destroy()
	end
end

return spilled_ring