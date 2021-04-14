--[[

= Sonic Onset Adventure Client =

Source: ControlScript/PlayerDraw.lua
Purpose: Player Draw class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_draw = {}

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")
local assets = replicated_storage:WaitForChild("Assets")

local switch = require(common_modules:WaitForChild("Switch"))
local camera_util = require(common_modules:WaitForChild("CameraUtil"))

local jump_ball = require(script:WaitForChild("JumpBall"))
local spindash_ball = require(script:WaitForChild("SpindashBall"))
local ball_trail = require(script:WaitForChild("BallTrail"))
local shield_model = require(script:WaitForChild("Shield"))
local magnet_shield_model = require(script:WaitForChild("MagnetShield"))
local invincibility = require(script:WaitForChild("Invincibility"))

local characters = assets:WaitForChild("Characters")

--Constants
local draw_rad = 10

--Constructor and destructor
function player_draw:New(character, name)
	--Initialize meta reference
	local self = setmetatable({}, {__index = player_draw})
	
	--Create character
	local char_folder = characters:FindFirstChild(character)
	if char_folder ~= nil then
		local char_model = char_folder:FindFirstChild("Character")
		if char_model ~= nil then
			self.character = char_model:Clone()
			self.character.Name = name
			self.character.Parent = workspace
		end
	end
	
	--Get character's info
	local info
	if character ~= nil then
		info = require(self.character:WaitForChild("CharacterInfo"))
	else
		error("Player can't be created without character")
		return nil
	end
	
	--Find common character references
	self.hrp = self.character:WaitForChild("HumanoidRootPart")
	
	--Get parts to hide when in a ball
	self.parts = {}
	for _,v in pairs(self.character:GetChildren()) do
		if v:IsA("BasePart") then
			table.insert(self.parts, v)
		end
	end
	
	--Create model instances
	local models = info.assets:WaitForChild("Models")
	
	self.jump_ball = jump_ball:New(self.hrp, self.character, models)
	self.spindash_ball = spindash_ball:New(self.hrp, self.character, models)
	self.ball_trail = ball_trail:New(self.hrp, self.character, models)
	
	self.shield_model = shield_model:New(self.hrp, self.character)
	self.magnet_shield_model = magnet_shield_model:New(self.hrp, self.character)
	self.invincibility = invincibility:New(self.hrp, self.character)
	
	--Initialize draw state
	self.cframe = self.hrp.CFrame
	self.ball = nil
	self.shield = nil
	self.invincible = false
	self.trail_active = false
	self.blink = 0
	self.blinking = false
	
	return self
end

function player_draw:Destroy()
	--Destroy model instances
	if self.jump_ball ~= nil then
		self.jump_ball:Destroy()
		self.jump_ball = nil
	end
	if self.spindash_ball ~= nil then
		self.spindash_ball:Destroy()
		self.spindash_ball = nil
	end
	if self.ball_trail ~= nil then
		self.ball_trail:Destroy()
		self.ball_trail = nil
	end
	if self.shield_model ~= nil then
		self.shield_model:Destroy()
		self.shield_model = nil
	end
	if self.magnet_shield_model ~= nil then
		self.magnet_shield_model:Destroy()
		self.magnet_shield_model = nil
	end
	if self.invincibility ~= nil then
		self.invincibility:Destroy()
		self.invincibility = nil
	end
	
	--Destroy character model
	if self.character ~= nil then
		self.character:Destroy()
		self.character = nil
	end
end

--Player draw interface
local function ApplyVisible(self, vis)
	if vis ~= self.last_vis then
		for _,v in pairs(self.parts) do
			v.LocalTransparencyModifier = vis
		end
		self.last_vis = vis
	end
end

function player_draw:Draw(dt, hrp_cf, ball, ball_spin, trail_active, shield, invincible, blinking)
	debug.profilebegin("player_draw:Draw")
	
	if self.hrp ~= nil then
		--Don't render player if not in frustum
		local not_cull = camera_util.CheckFrustum(hrp_cf.p, draw_rad)
		
		--Blink character
		local force_ball = nil
		if ball ~= nil then
			if blinking then
				self.blink = (self.blink < 0.5) and 1 or 0
				ApplyVisible(self, 1)
				force_ball = self.blink < 0.5
			elseif self.blinking then
				ApplyVisible(self, 1)
				force_ball = true
			end
		else
			if blinking then
				self.blink = 1 - self.blink
				ApplyVisible(self, self.blink)
			elseif self.blinking then
				ApplyVisible(self, 0)
			end
		end
		self.blinking = blinking
		
		--Update ball
		if ball ~= self.ball or force_ball ~= nil then
			--Disable previous ball
			if self.ball ~= nil or force_ball == false then
				switch(self.ball, {}, {
					["JumpBall"] = function()
						self.jump_ball:Disable()
					end,
					["SpindashBall"] = function()
						self.spindash_ball:Disable()
					end,
				})
			end
			
			--Enable new ball
			if ball ~= nil and force_ball ~= false then
				--Enable new ball
				switch(ball, {}, {
					["JumpBall"] = function()
						self.jump_ball:Enable()
					end,
					["SpindashBall"] = function()
						self.spindash_ball:Enable()
					end,
				})
			end
			
			--Hide character
			if force_ball == nil then
				--Make character visible
				ApplyVisible(self, (ball ~= nil) and 1 or 0)
			end
			
			self.ball = ball
		end
		
		if ball ~= nil and force_ball ~= false then
			switch(ball, {}, {
				["JumpBall"] = function()
					if not_cull then
						self.jump_ball:Draw(dt, hrp_cf, ball_spin)
					else
						self.jump_ball:LazyDraw(dt, hrp_cf, ball_spin)
					end
				end,
				["SpindashBall"] = function()
					if not_cull then
						self.spindash_ball:Draw(dt, hrp_cf, ball_spin)
					else
						self.spindash_ball:LazyDraw(dt, hrp_cf, ball_spin)
					end
				end,
			})
		end
		
		--Update ball trail
		if trail_active ~= self.trail_active then
			if trail_active then
				self.ball_trail:Enable()
			else
				self.ball_trail:Disable()
			end
			self.trail_active = trail_active
		end
		
		if not_cull then
			self.ball_trail:Draw(hrp_cf)
		else
			self.ball_trail:LazyDraw(hrp_cf)
		end
		
		--Update shield
		if shield ~= self.shield then
			--Disable previous shield
			if self.shield ~= nil then
				switch(self.shield, {}, {
					["Shield"] = function()
						self.shield_model:Disable()
					end,
					["MagnetShield"] = function()
						self.magnet_shield_model:Disable()
					end,
				})
			end
			
			--Enable new shield
			if shield ~= nil then
				switch(shield, {}, {
					["Shield"] = function()
						self.shield_model:Enable()
					end,
					["MagnetShield"] = function()
						self.magnet_shield_model:Enable()
					end,
				})
			end
			self.shield = shield
		end
		
		if shield ~= nil then
			if not_cull then
				switch(shield, {}, {
					["Shield"] = function()
						self.shield_model:Draw(dt, hrp_cf)
					end,
					["MagnetShield"] = function()
						self.magnet_shield_model:Draw(dt, hrp_cf)
					end,
				})
			else
				switch(shield, {}, {
					["Shield"] = function()
						self.shield_model:LazyDraw(dt, hrp_cf)
					end,
					["MagnetShield"] = function()
						self.magnet_shield_model:LazyDraw(dt, hrp_cf)
					end,
				})
			end
		end
		
		--Update ball trail
		if invincible ~= self.invincible then
			if invincible then
				self.invincibility:Enable()
			else
				self.invincibility:Disable()
			end
			self.invincible = invincible
		end
		
		if not_cull then
			self.invincibility:Draw(dt, hrp_cf)
		else
			self.invincibility:LazyDraw(dt, hrp_cf)
		end
		
		--Update character CFrame
		if hrp_cf ~= self.cframe then
			self.hrp.CFrame = hrp_cf
			self.cframe = hrp_cf
		end
	end
	
	debug.profileend()
end

return player_draw