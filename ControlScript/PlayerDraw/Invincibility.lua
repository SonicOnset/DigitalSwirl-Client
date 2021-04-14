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
function draw_invincibility:New(hrp, holder)
	--Initialize meta reference
	local self = setmetatable({}, {__index = draw_invincibility})
	
	--Create model instance
	self.holder = holder
	
	self.invincibility = models:WaitForChild("Invincibility"):clone()
	self.particles = self.invincibility:WaitForChild("RootPart"):WaitForChild("Invincibility"):GetChildren()
	self.invincibility.Parent = self.holder
	
	--Weld
	local weld = Instance.new("Weld")
	weld.Part0 = hrp
	weld.Part1 = self.invincibility.PrimaryPart
	weld.Parent = self.invincibility.PrimaryPart
	
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
end

function draw_invincibility:Disable()
	--Disable trails
	for _,v in pairs(self.particles) do
		v.Enabled = false
	end
end

function draw_invincibility:Draw(dt, hrp_cf)
	
end

function draw_invincibility:LazyDraw(dt, hrp_cf)
	
end

return draw_invincibility