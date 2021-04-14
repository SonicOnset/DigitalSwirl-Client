--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Object/DashRamp.lua
Purpose: Dash Ramp object
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local dash_ramp = {}

local assets = script.Parent.Parent:WaitForChild("Assets")
local obj_assets = assets:WaitForChild("DashRamp")

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

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
	--Debounce check
	if self.debounce == nil or self.debounce <= 0 then
		--Align player with dash panel and set speed and state
		player.pos = self.root.CFrame.p
		player:SetAngle(player:AngleFromRbx(self.root.CFrame - self.root.CFrame.p))
		player:ResetObjectState()
		if player.v3 ~= true then
			player.spd = Vector3.new((self.power / 60) / player.p.scale, (self.power / 60) / player.p.scale / 1.5, 0)
			player.dashpanel_timer = self.nocon_time * constants.framerate
		else
			player.spd = player:PosToSpd(player:ToLocal(vector.Flatten(player:ToGlobal(player.spd), self.root.CFrame.UpVector)) + (self.root.CFrame.UpVector * (self.power / 60) / player.p.scale / 1.5))
		end
		player.state = "Airborne"
		player:ExitBall()
		player.animation = "DashRamp"
		
		--Play touch sound
		self.touch_sound:Play()
		
		--Set debounce
		self.debounce = 12
		self.update = Update
	end
end


--Constructor and destructor
function dash_ramp:New(object)
	--Initialize meta reference
	local self = setmetatable({}, {__index = dash_ramp})
	
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

function dash_ramp:Destroy()
	--Destroy sound
	if self.touch_sound ~= nil then
		self.touch_sound:Destroy()
		self.touch_sound = nil
	end
end

return dash_ramp