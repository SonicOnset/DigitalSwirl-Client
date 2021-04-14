--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Object/DashRing.lua
Purpose: Dash Ring object
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local dash_ring = {}

local assets = script.Parent.Parent:WaitForChild("Assets")
local obj_assets = assets:WaitForChild("DashRing")

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
		player:SetAngle(player:AngleFromRbx(self.root.CFrame - self.root.CFrame.p))
		player.pos = self.root.Position - (player:GetUp() * (player.p.height * player.p.scale))
		player.spd = Vector3.new((self.power / 60) / player.p.scale, 0, 0)
		
		--Set dash ring state and make airborne
		player.state = constants.state.airborne
		player.flag.grounded = false
		player:ExitBall()
		player:ResetObjectState()
		player.dashring_timer = self.nocon_time * 60
		player.animation = "DashRing"
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
function dash_ring:New(object)
	--Initialize meta reference
	local self = setmetatable({}, {__index = dash_ring})
	
	--Use object information
	self.object = object
	self.root = object.PrimaryPart
	self.nocon_time = self.object:WaitForChild("Nocon").Value
	self.power = self.object:WaitForChild("Power").Value
	
	--Create touch sound
	self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
	self.touch_sound.Parent = self.root
	
	--Attach functions
	self.touch_player = TouchPlayer
	
	return self
end

function dash_ring:Destroy()
	--Destroy sound
	if self.touch_sound ~= nil then
		self.touch_sound:Destroy()
		self.touch_sound = nil
	end
end

return dash_ring