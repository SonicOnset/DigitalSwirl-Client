--[[

= Sonic Onset Adventure Client =

Source: ControlScript/PlayerDraw/MagnetShield.lua
Purpose: Player Draw Magnet Shield class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local draw_magnet_shield = {}

local assets = script.Parent.Parent:WaitForChild("Assets")
local models = assets:WaitForChild("Models")

--Constructor and destructor
function draw_magnet_shield:New(holder)
	--Initialize meta reference
	local self = setmetatable({}, {__index = draw_magnet_shield})
	
	--Create model instance
	self.holder = holder
	
	self.shield = models:WaitForChild("MagnetShield"):clone()
	
	self.shield1 = self.shield:WaitForChild("Shield1")
	self.shield1b = self.shield1:WaitForChild("Beams"):GetChildren()
	self.shield1c = {}
	for _,v in pairs (self.shield1:GetChildren()) do
		if v:IsA("Decal") then
			table.insert(self.shield1c, v)
		end
	end
	
	self.shield2 = self.shield:WaitForChild("Shield2")
	self.shield2b = self.shield2:WaitForChild("Beams"):GetChildren()
	self.shield2c = {}
	for _,v in pairs (self.shield2:GetChildren()) do
		if v:IsA("Decal") then
			table.insert(self.shield2c, v)
		end
	end
	
	self.shield3 = self.shield:WaitForChild("Shield3")
	self.shield3b = self.shield3:WaitForChild("Beams"):GetChildren()
	self.shield3c = {}
	for _,v in pairs (self.shield3:GetChildren()) do
		if v:IsA("Decal") then
			table.insert(self.shield3c, v)
		end
	end
	
	--Initialize time
	self.time = 0
	self.rot = CFrame.new()
	
	return self
end

function draw_magnet_shield:Destroy()
	--Destroy model instance
	self.shield:Destroy()
end

--Interface
function draw_magnet_shield:Enable()
	--Set parent
	self.shield.Parent = self.holder
end

function draw_magnet_shield:Disable()
	--Set parent
	self.shield.Parent = nil
end

local function GetTransparency(tim, off)
	return 1 - (math.clamp(math.cos((tim * 1.4) + (math.pi * 2 * off)), 0, 1) ^ 2.5)
end

function draw_magnet_shield:Draw(dt, hrp_cf)
	--Get shield transparencies
	self.time += dt
	
	local trans1 = GetTransparency(self.time, 0.000)
	local trans2 = GetTransparency(self.time, 0.333)
	local trans3 = GetTransparency(self.time, 0.666)
	
	--Apply shield transparencies
	for _,v in pairs(self.shield1c) do
		v.Transparency = trans1
	end
	for _,v in pairs(self.shield1b) do
		v.Enabled = trans1 < 0.75
	end
	
	for _,v in pairs(self.shield2c) do
		v.Transparency = trans2
	end
	for _,v in pairs(self.shield2b) do
		v.Enabled = trans2 < 0.75
	end
	
	for _,v in pairs(self.shield3c) do
		v.Transparency = trans3
	end
	for _,v in pairs(self.shield3b) do
		v.Enabled = trans3 < 0.75
	end
	
	--Set shield CFrame
	self.rot *= CFrame.Angles(dt * 0.16, dt * 0.21, dt * 0.19)
	self.shield:SetPrimaryPartCFrame(CFrame.new(hrp_cf.p) * self.rot)
end

function draw_magnet_shield:LazyDraw(dt, hrp_cf)
	--Set shield CFrame
	self.shield:SetPrimaryPartCFrame(CFrame.new(hrp_cf.p))
end

return draw_magnet_shield