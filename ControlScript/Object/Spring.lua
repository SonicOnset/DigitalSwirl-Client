--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Object/Spring.lua
Purpose: Spring object
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local spring = {}

local assets = script.Parent.Parent:WaitForChild("Assets")
local obj_assets = assets:WaitForChild("Spring")

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local cframe = require(common_modules:WaitForChild("CFrame"))
local vector = require(common_modules:WaitForChild("Vector"))
local constants = require(script.Parent.Parent:WaitForChild("Constants"))

local object_common = require(script.Parent.Parent:WaitForChild("ObjectCommon"))

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
	--Perform debounce check
	if self.debounce == nil or self.debounce <= 0 then
		--Set player angle
		if player.v3 ~= true then
			if math.abs(self.root.CFrame.UpVector:Dot(player.gravity.unit)) < 0.95 then
				player:SetAngle(player:AngleFromRbx(CFrame.lookAt(Vector3.new(), self.root.CFrame.UpVector, -player.gravity.unit) * CFrame.Angles(math.pi / -2, 0, 0)))
			else
				player:SetAngle(cframe.FromToRotation(player:GetUp(), self.root.CFrame.UpVector) * player.ang)
			end
		end
		
		--Align player with spring and set speed
		player.pos = self.root.Position
		if player.v3 ~= true then
			player.spd = Vector3.new(0, (self.power / 60) / player.p.scale, 0)
		else
			player.spd = player:ToLocal(Vector3.new(0, (self.power / 60) / player.p.scale, 0))
		end
		
		--Set spring state and make airborne
		player.state = constants.state.airborne
		player.flag.grounded = false
		player:ExitBall()
		player:ResetObjectState()
		player.flag.air_kick = true
		if player.v3 ~= true then
			player.spring_timer = self.nocon_time * 60
			player.flag.scripted_spring = self.scripted
		end
		player.animation = "SpringStart"
		player.reset_anim = true
		
		--Play touch sound and animation
		self.touch_sound:Play()
		self.touch_anim:Play()
		
		--Set debounce
		self.debounce = 6
		self.update = Update
	end
end

--Constructor and destructor
function spring:New(object)
	--Initialize meta reference
	local self = setmetatable({}, {__index = spring})
	
	--Use object information
	self.object = object
	self.root = object.PrimaryPart
	self.anim_controller = self.object:WaitForChild("AnimationController")
	self.nocon_time = self.object:WaitForChild("Nocon").Value
	self.power = self.object:WaitForChild("Power").Value
	
	if self.power < 0 then
		--Scripted
		self.power *= -1
		self.scripted = true
	else
		--Not scripted
		self.scripted = false
	end
	
	--Create touch sound
	self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
	self.touch_sound.Parent = self.root
	
	--Load touch animation
	self.touch_anim = self.anim_controller:LoadAnimation(obj_assets:WaitForChild("TouchAnim"))
	
	--Attach functions
	self.touch_player = TouchPlayer
	
	--Set other specifications
	self.homing_target = true
	
	return self
end

function spring:Destroy()
	--Destroy sound and animation
	if self.touch_sound ~= nil then
		self.touch_sound:Destroy()
		self.touch_sound = nil
	end
	if self.touch_anim ~= nil then
		self.touch_anim:Destroy()
		self.touch_anim = nil
	end
end

return spring