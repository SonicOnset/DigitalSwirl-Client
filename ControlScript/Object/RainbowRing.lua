--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Object/RainbowRing.lua
Purpose: Rainbow Ring object
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local rainbow_ring = {}

local assets = script.Parent.Parent:WaitForChild("Assets")
local obj_assets = assets:WaitForChild("RainbowRing")

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local cframe = require(common_modules:WaitForChild("CFrame"))
local vector = require(common_modules:WaitForChild("Vector"))
local constants = require(script.Parent.Parent:WaitForChild("Constants"))

--Object functions
local function Update(self, i)
	--Decrement debounce
	if self.debounce > 0 then
		self.debounce = math.max(self.debounce - 1, 0)
	else
		self.update = nil
	end
end

--Object contact
local function TouchPlayer(self, player)
	--Disable dash panels for SEO v3
	if player.v3 then
		return
	end
	
	--Perform debounce check
	if self.debounce == nil or self.debounce <= 0 then
		--Move player to rainbow ring and set speed
		player:SetAngle(player:AngleFromRbx(self.og_cf - self.og_cf.p))
		player.pos = self.root.Position - (player:GetUp() * (player.p.height * player.p.scale))
		player.spd = Vector3.new((self.power / 60) / player.p.scale, 0, 0)
		
		--Set rainbow ring state and make airborne
		player.state = constants.state.airborne
		player.flag.grounded = false
		player:ExitBall()
		player:ResetObjectState()
		player.dashring_timer = self.nocon_time * 60
		player.animation = "RainbowRing"
		player.reset_anim = true
		
		--Play touch sound
		self.touch_sound:Play()
		
		--Set debounce
		self.debounce = 6
		self.update = Update
	end
end

--Object functions
local function Update(self, i)
	--Decrement debounce
	if self.debounce == nil then
		self.debounce = 0
	elseif self.debounce > 0 then
		self.debounce = math.max(self.debounce - 1, 0)
	end
end

--Constructor and destructor
function rainbow_ring:New(object)
	--Initialize meta reference
	local self = setmetatable({}, {__index = rainbow_ring})
	
	--Use object information
	self.object = object
	self.root = object.PrimaryPart
	self.nocon_time = self.object:WaitForChild("Nocon").Value
	self.power = self.object:WaitForChild("Power").Value
	self.anim_controller = self.object:WaitForChild("AnimationController")
	
	--Remember original object position
	self.og_cf = self.root.CFrame
	
	--Create touch sound
	self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
	self.touch_sound.Parent = self.root
	
	--Create and play animation
	self.anim = self.anim_controller:LoadAnimation(obj_assets:WaitForChild("Anim"))
	self.anim:Play()
	
	--Attach functions
	self.touch_player = TouchPlayer
	
	return self
end

function rainbow_ring:Destroy()
	--Destroy animation
	if self.anim ~= nil then
		self.anim:Destroy()
		self.anim = nil
	end
	
	--Destroy sound
	if self.touch_sound ~= nil then
		self.touch_sound:Destroy()
		self.touch_sound = nil
	end
	
	--Restore object position
	if self.object ~= nil then
		self.object:SetPrimaryPartCFrame(self.og_cf)
	end
end

return rainbow_ring