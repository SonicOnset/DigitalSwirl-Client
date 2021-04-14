--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/Animation.lua
Purpose: Player animation functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_animation = {}

local footstep_sounds = script.Parent:WaitForChild("FootstepSounds")

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local constants = require(script.Parent.Parent:WaitForChild("Constants"))
local collision = require(common_modules:WaitForChild("Collision"))
local switch = require(common_modules:WaitForChild("Switch"))
local rail = require(script.Parent:WaitForChild("Rail"))
local global_reference = require(common_modules:WaitForChild("GlobalReference"))

local collision_reference = global_reference:New(workspace, "Level/Map/Collision")

--Common functions
local function lerp(x, y, z)
	return x + (y - x) * z
end

local function psign(x)
	return (x < 0) and -1 or 1
end

local function StringSplit(s, delimiter)
	local spl = {}
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(spl, match)
	end
	return spl
end

--Animation events
local footstep_mats = {
	[Enum.Material.Plastic] = "Plastic",
	[Enum.Material.Wood] = "Wood",
	[Enum.Material.Slate] = "Stone",
	[Enum.Material.Concrete] = "Stone",
	[Enum.Material.CorrodedMetal] = "Metal",
	[Enum.Material.DiamondPlate] = "Metal",
	[Enum.Material.Foil] = "Metal",
	[Enum.Material.Grass] = "Grass",
	[Enum.Material.Ice] = "Metal",
	[Enum.Material.Marble] = "Stone",
	[Enum.Material.Granite] = "Stone",
	[Enum.Material.Brick] = "Stone",
	[Enum.Material.Pebble] = "Stone",
	[Enum.Material.Sand] = "Sand",
	[Enum.Material.Fabric] = "Dirt",
	[Enum.Material.SmoothPlastic] = "Plastic",
	[Enum.Material.Metal] = "Metal",
	[Enum.Material.WoodPlanks] = "Wood",
	[Enum.Material.Cobblestone] = "Stone",
	[Enum.Material.Air] = nil,
	[Enum.Material.Water] = "Water",
	[Enum.Material.Rock] = "Stone",
	[Enum.Material.Glacier] = "Metal",
	[Enum.Material.Snow] = "Snow",
	[Enum.Material.Sandstone] = "Stone",
	[Enum.Material.Mud] = "Dirt",
	[Enum.Material.Basalt] = "Stone",
	[Enum.Material.Ground] = "Dirt",
	[Enum.Material.CrackedLava] = "Stone",
	[Enum.Material.Neon] = "Metal",
	[Enum.Material.Glass] = "Metal",
	[Enum.Material.Asphalt] = "Stone",
	[Enum.Material.LeafyGrass] = "Grass",
	[Enum.Material.Salt] = "Stone",
	[Enum.Material.Limestone] = "Stone",
	[Enum.Material.Pavement] = "Stone",
	[Enum.Material.ForceField] = "Metal",
}

local facial_assets = {
	["Mouth"] = {
		["DefaultSmile"] = "rbxassetid://5961059446",
		["OpenSmile"] = "rbxassetid://5961060028",
		["AdventureSmile"] = "rbxassetid://5961059112",
		["AngrySmile"] = "rbxassetid://5961059315",
		["Frown"] = "rbxassetid://5961059731",
		["MouthOpen"] = "rbxassetid://5961059833",
		["MouthOpenConcern"] = "rbxassetid://5961059938",
	},
	["LEye"] = {
		["DefaultEyes"] = "rbxassetid://5961059553",
		["RedEyes"] = "rbxassetid://5961060113",
		["Wink"] = "rbxassetid://5961060175",
	},
	["REye"] = {
		["DefaultEyes"] = "rbxassetid://5961059553",
		["RedEyes"] = "rbxassetid://5961060113",
		["Wink"] = "rbxassetid://5961060175",
	},
}

local function AnimFootstep(self, anim, pos)
	if anim.WeightCurrent > 0.5 and self.hrp ~= nil then
		--Send a raycast down from the foot to find the floor material
		local up = self.hrp.CFrame.UpVector
		local hit, pos, nor, mat = collision.Raycast({workspace.Terrain, collision_reference:Get()}, (self.hrp.CFrame * pos) + up, up * -2)
		
		if hit ~= nil then
			--Get material
			local mapped_mat
			local mat_override = hit:FindFirstChild("Material")
			if mat_override and mat_override:IsA("StringValue") then
				mapped_mat = mat_override.Value
			else
				mapped_mat = footstep_mats[mat]
			end
			
			if mapped_mat ~= nil and self.footstep_sounds[mapped_mat] and #self.footstep_sounds[mapped_mat] > 0 then
				--Get random sound
				local f = self.footstep_sounds[mapped_mat]
				local snd = f[math.random(1, #f)]
				
				--Play sound
				snd.Volume = self.footstep_volumes[mapped_mat][snd.Name] * (0.55 + math.abs(anim.Speed) / 6.5)
				snd:Play()
			end
		end
	end
end

local function AttachEvents(self, anim)
	--Attach keyframe events
	local character = self.character
	if character ~= nil then
		--Footstep
		anim:GetMarkerReachedSignal("LStep"):Connect(function()
			AnimFootstep(self, anim, Vector3.new(-0.75, -self:GetCharacterYOff(), 0))
		end)
		anim:GetMarkerReachedSignal("RStep"):Connect(function()
			AnimFootstep(self, anim, Vector3.new(0.75, -self:GetCharacterYOff(), 0))
		end)
		
		--Facial
		local facial_parts = {
			["Mouth"] = self.mouth,
			["LEye"] = self.left_eye,
			["REye"] = self.right_eye,
		}
		
		for i, v in pairs(facial_parts) do
			for j, k in pairs(facial_assets[i]) do
				anim:GetMarkerReachedSignal(i.."-"..j):Connect(function()
					v.TextureID = k
				end)
			end
		end
	end
end

--Animation interface
function player_animation.LoadAnimations(self)
	--Get facial parts
	self.mouth = self.character:WaitForChild("Mouth_Geo")
	self.left_eye = self.character:WaitForChild("LeftIris_Geo")
	self.right_eye = self.character:WaitForChild("RightIris_Geo")
	
	--Load animation tracks from animations folder
	self.animation_tracks = {}
	
	local animations = self.assets:WaitForChild("Animations")
	for _,v in pairs(animations:GetChildren()) do
		if v:IsA("Animation") then
			--Load new animation track and attach footsteps if a running animation
			local new_anim = self.hum:LoadAnimation(v)
			AttachEvents(self, new_anim)
			
			--Register animation
			self.animation_tracks[v.Name] = new_anim
		end
	end
	
	--Load footsteps
	self.footstep_sounds = {}
	self.footstep_volumes = {}
	
	for _,f in pairs(footstep_sounds:GetChildren()) do
		--Load footstep folders
		if f:IsA("Folder") then
			--Register folder
			self.footstep_sounds[f.Name] = {}
			self.footstep_volumes[f.Name] = {}
			
			--Load sounds
			for _,v in pairs(f:GetChildren()) do
				--Create new sound object and parent to sound source
				local new_snd = v:Clone()
				new_snd.Parent = self.sound_source or self.hrp
				
				--Register new sound
				table.insert(self.footstep_sounds[f.Name], new_snd)
				self.footstep_volumes[f.Name][v.Name] = v.Volume
			end
		end
	end
	
	--Get dynamic tilt joints
	self.tilt_neck = self.hrp:WaitForChild("Root"):WaitForChild("LowerTorso"):WaitForChild("UpperTorso"):WaitForChild("Neck")
	self.tilt_neck_cf = self.tilt_neck.CFrame
	self.tilt_torso = self.hrp:WaitForChild("Root"):WaitForChild("LowerTorso")
	self.tilt_torso_cf = self.tilt_torso.CFrame
end

function player_animation.UnloadAnimations(self)
	--Unload animations
	if self.animation_tracks ~= nil then
		for _,v in pairs(self.animation_tracks) do
			v:Destroy()
		end
		self.animation_tracks = nil
	end
	
	--Unload sounds
	if self.footstep_sounds ~= nil then
		for _,f in pairs(self.footstep_sounds) do
			for _,v in pairs(f) do
				v:Destroy()
			end
		end
		self.footstep_sounds = nil
	end
end

function player_animation.GetAnimationTrack(self)
	local track = nil
	local track_weight = 0
	
	for _,v in pairs(self.animations[self.animation].tracks) do
		if self.animation_tracks[v.name].WeightCurrent >= track_weight then
			track = self.animation_tracks[v.name]
			track_weight = track.WeightCurrent
		end
	end
	
	return track
end

function player_animation.GetAnimationRate(self)
	local track = player_animation.GetAnimationTrack(self)
	if track ~= nil and track.Length > 0 then
		return track.Speed / track.Length
	end
	return 0
end

function player_animation.Animate(self)
	if self.animation ~= nil then
		if self.animation == self.prev_animation then
			--Handle animation end changes
			if self.animations[self.animation].end_anim ~= nil then
				local track = player_animation.GetAnimationTrack(self)
				if track ~= nil and (track.IsPlaying == false or track.TimePosition >= track.Length) then
					self.animation = self.animations[self.animation].end_anim
				end
			end
			
			--Handle animation specific changes
			switch(self.animation, {}, {
				["Spring"] = function()
					if self.spd.Y < 0 then
						self.animation = "Fall"
					end
				end,
				["DashRing"] = function()
					if self.dashring_timer <= 0 then
						self.animation = "Fall"
					end
				end,
				["RainbowRing"] = function()
					if self.dashring_timer <= 0 then
						self.animation = "Fall"
					end
				end,
				["DashRamp"] = function()
					if self.dashpanel_timer <= 0 then
						self.animation = "Fall"
					end
				end,
			})
		end
		
		--Animation changes
		if self.animation ~= self.prev_animation or self.reset_anim then
			--Reset facial state
			self.mouth.TextureID = facial_assets["Mouth"]["DefaultSmile"]
			self.left_eye.TextureID = facial_assets["LEye"]["DefaultEyes"]
			self.right_eye.TextureID = facial_assets["REye"]["DefaultEyes"]
			
			--Stop previous animation
			if self.prev_animation ~= nil then
				for _,v in pairs(self.animations[self.prev_animation].tracks) do
					self.animation_tracks[v.name]:Stop()
				end
			end
			
			--Play new animation
			self.prev_animation = self.animation
			for _,v in pairs(self.animations[self.animation].tracks) do
				self.animation_tracks[v.name]:Play()
			end
		end
		
		--Handle animation speed
		if self.animations[self.animation].spd_b and self.animations[self.animation].spd_i then
			--Get speed to set
			local spd = self.animations[self.animation].spd_b + math.abs(self.anim_speed) * self.animations[self.animation].spd_i
			if not self.animations[self.animation].spd_a then
				spd *= psign(self.anim_speed)
			end
			
			--Set track speeds
			for _,v in pairs(self.animations[self.animation].tracks) do
				self.animation_tracks[v.name]:AdjustSpeed(spd)
			end
		end
		
		--Handle animation weights
		if #self.animations[self.animation].tracks > 1 then
			--Get track to play
			local playing_track = self.animations[self.prev_animation].tracks[1].name
			local playing_pos = 0
			
			for _,v in pairs(self.animations[self.prev_animation].tracks) do
				if v.pos >= playing_pos and self.anim_speed >= v.pos then
					playing_track = v.name
					playing_pos = v.pos
				end
			end
			
			--Adjust weights accordingly
			for _,v in pairs(self.animations[self.prev_animation].tracks) do
				if v.name == playing_track then
					self.animation_tracks[v.name]:AdjustWeight(1)
				else
					self.animation_tracks[v.name]:AdjustWeight(0.01)
				end
			end
		end
	end
	
	--[[
	--Reset animation state
	if self.animation ~= self.prev_animation or self.reset_anim then
		--Reset facial state
		self.mouth.TextureID = facial_assets["Mouth"]["DefaultSmile"]
		self.left_eye.TextureID = facial_assets["LEye"]["DefaultEyes"]
		self.right_eye.TextureID = facial_assets["REye"]["DefaultEyes"]
	end
	
	--Animation changes
	if self.animation == "Spring" then
		if self.spd.Y < 0 then
			self.animation = "Fall"
		end
	elseif self.animation == "DashRing" or self.animation == "RainbowRing" then
		if self.dashring_timer <= 0 then
			self.animation = "Fall"
		end
	elseif self.animation == "DashRamp" then
		if self.dashpanel_timer <= 0 then
			self.animation = "Fall"
		end
	elseif self.animation == "SpringStart" then
		local anim = self.animation_tracks[self.animation]
		if anim ~= nil then
			if self.animation == self.prev_animation and (anim.IsPlaying == false or anim.TimePosition >= anim.Length) then
				self.animation = "Spring"
			end
		end
	elseif string.sub(self.animation, 1, 5) == "Trick" then
		local anim = self.animation_tracks[self.animation]
		if anim ~= nil then
			if self.animation == self.prev_animation and (anim.IsPlaying == false or anim.TimePosition >= anim.Length) then
				self.animation = "Fall"
			end
		end
	elseif self.animation == "Land" then
		local anim = self.animation_tracks[self.animation]
		if anim ~= nil then
			if self.animation == self.prev_animation and (anim.IsPlaying == false or anim.TimePosition >= anim.Length) then
				self.animation = "Idle"
			end
		end
	elseif self.animation == "RailLand" then
		local anim = self.animation_tracks[self.animation]
		if anim ~= nil then
			if self.animation == self.prev_animation and (anim.IsPlaying == false or anim.TimePosition >= anim.Length) then
				self.animation = "Rail"
			end
		end
	end
	
	--Run animation
	if self.animation == "Run" then
		--Get animation weights
		local trans_length = 0.35
		local run_start = ((self.p.run_speed + self.p.dash_speed) / 2) - (trans_length / 2)
		local speed = (0.25 + math.abs(self.anim_speed) / 0.95) * psign(self.anim_speed)
		local weight = math.clamp((self.spd.X - run_start) / trans_length, 0.001, 0.999)
		
		if self.reset_anim == true or self.prev_animation ~= "Run" then
			--Stop previous animation
			if self.prev_animation then
				self.animation_tracks[self.prev_animation]:Stop()
			end
			self.prev_animation = self.animation
			
			--Play new animations
			self.animation_tracks["Jog2"]:Play()
			self.animation_tracks["Run"]:Play()
		end
		
		--Adjust animation speeds and weights
		self.animation_tracks["Jog2"]:AdjustSpeed(speed)
		self.animation_tracks["Jog2"]:AdjustWeight(1 - weight)
		self.animation_tracks["Run"]:AdjustSpeed(speed)
		self.animation_tracks["Run"]:AdjustWeight(weight)
	elseif self.animation_tracks[self.animation] then
		if self.reset_anim == true or self.animation ~= self.prev_animation then
			--Stop previous animation
			if self.prev_animation == "Run" then
				self.animation_tracks["Jog2"]:Stop()
				self.animation_tracks["Run"]:Stop()
			elseif self.prev_animation then
				self.animation_tracks[self.prev_animation]:Stop()
			end
			self.prev_animation = self.animation
			
			--Play new animation
			self.animation_tracks[self.animation]:Play()
		end
		
		--Update animation speed
		if self.animation == "Roll" or self.animation == "Spindash" then
			self.animation_tracks[self.animation]:AdjustSpeed(1.5 + math.abs(self.anim_speed) / 1.55)
		elseif self.animation == "Rail" or self.animation == "RailCrouch" then
			self.animation_tracks[self.animation]:AdjustSpeed(0.125 + math.abs(self.anim_speed) / 2)
		end
	end
	--]]
	
	--Clear animation reset flag now that it's been processed
	self.reset_anim = false
end

--Dynamic tilt
local function TiltJoint(self, dt, joint, tilt)
	joint.CFrame = joint.CFrame:Lerp(tilt, (0.675 ^ 60) ^ dt)
end

function player_animation.DynTilt(self, dt)
	--Get how much player is trying to turn
	local turn = self.last_turn or 0
	if math.abs(turn) < math.rad(135) then
		turn = math.clamp(turn, math.rad(-80), math.rad(80))
	else
		turn = 0
	end
	self.anim_turn = self.anim_turn ~= nil and lerp(self.anim_turn, turn, (0.6275 ^ 60) ^ dt) or 0
	
	--Tilt head
	local tilt = math.clamp(self.anim_turn * -(1.125 + self.spd.X / 6), math.rad(-60), math.rad(60))
	TiltJoint(self, dt, self.tilt_neck, self.tilt_neck_cf *CFrame.Angles(0, -tilt, 0))
	
	--Tilt torso
	local tilt = math.clamp(self.anim_turn * (0.4 + self.spd.X / 4), math.rad(-30), math.rad(30))
	TiltJoint(self, dt, self.tilt_torso, self.tilt_torso_cf * CFrame.Angles(0, 0, tilt))
end

return player_animation