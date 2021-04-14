--[[

= Sonic Onset Adventure Client =

Source: ControlScript/PlayerDraw/Invincibility.lua
Purpose: Player Draw Invincibility class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local draw_invincibility = {}

local assets = script.Parent.Parent:WaitForChild("Assets")
local models = assets:WaitForChild("Models")

--Constructor and destructor
function draw_invincibility:New(holder)
	--Initialize meta reference
	local self = setmetatable({}, {__index = draw_invincibility})
	
	--Create model instance
	self.holder = holder
	
	self.invincibility = models:WaitForChild("Invincibility"):clone()
	self.particles = self.invincibility:WaitForChild("RootPart"):WaitForChild("Invincibility"):GetChildren()
	self.invincibility.Parent = self.holder
	
	--Initialize state
	self.enabled = false
	self.hrp_cf = nil
	self.en_time = 0
	self.part_time = 0
	for _,v in pairs(self.particles) do
		self.part_time = math.max(self.part_time, v.Lifetime.Max)
	end
	
	return self
end

function draw_invincibility:Destroy()
	--Destroy model instance
	self.invincibility:Destroy()
end

--Interface
function draw_invincibility:Enable()
	--Enable trails
	for _,v in pairs(self.particles) do
		v.Enabled = true
	end
	self.en_time = self.part_time
	self.enabled = true
end

function draw_invincibility:Disable()
	--Disable trails
	for _,v in pairs(self.particles) do
		v.Enabled = false
	end
	self.enabled = false
end

function draw_invincibility:Draw(dt, hrp_cf)
	if not self.enabled then
		self.en_time -= dt
	end
	if self.en_time > 0 and hrp_cf ~= self.hrp_cf then
		--Set invincibility CFrame
		self.invincibility:SetPrimaryPartCFrame(hrp_cf)
		self.hrp_cf = hrp_cf
	end
end

function draw_invincibility:LazyDraw(dt, hrp_cf)
	if not self.enabled then
		self.en_time -= dt
	end
	if self.en_time > 0 and hrp_cf ~= self.hrp_cf then
		--Set invincibility CFrame
		self.invincibility:SetPrimaryPartCFrame(hrp_cf)
		self.hrp_cf = hrp_cf
	end
end

return draw_invincibility