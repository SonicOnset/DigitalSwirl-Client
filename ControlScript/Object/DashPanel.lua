--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Object/DashPanel.lua
Purpose: Dash Panel object
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local dash_panel = {}

local assets = script.Parent.Parent:WaitForChild("Assets")
local obj_assets = assets:WaitForChild("DashPanel")

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
	
	--Make sure player is grounded and perform debounce check
	if self.debounce == nil or self.debounce <= 0 then
		if player.flag.grounded == true then
			--Align player with dash panel and set speed and state
			player.pos = (self.root.CFrame * CFrame.new(0, self.root.Size.Y / -2, 0)).p
			player:SetAngle(player:AngleFromRbx(self.root.CFrame - self.root.CFrame.p))
			player.spd = Vector3.new((self.power / 60) / player.p.scale, player.spd.Y, 0)
			player:ResetObjectState()
			player.dashpanel_timer = self.nocon_time * 60
			
			--Play touch sound
			self.touch_sound:Play()
			
			--Set debounce
			self.debounce = 6
			self.update = Update
		end
	end
end

--Constructor and destructor
function dash_panel:New(object)
	--Initialize meta reference
	local self = setmetatable({}, {__index = dash_panel})
	
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

function dash_panel:Destroy()
	--Destroy sound
	if self.touch_sound ~= nil then
		self.touch_sound:Destroy()
		self.touch_sound = nil
	end
end

return dash_panel