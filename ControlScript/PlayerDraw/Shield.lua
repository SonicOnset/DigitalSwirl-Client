--[[

= Sonic Onset Adventure Client =

Source: ControlScript/PlayerDraw/Shield.lua
Purpose: Player Draw Shield class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local draw_shield = {}

local assets = script.Parent.Parent:WaitForChild("Assets")
local models = assets:WaitForChild("Models")

--Constructor and destructor
function draw_shield:New(holder)
	--Initialize meta reference
	local self = setmetatable({}, {__index = draw_shield})
	
	--Create model instance
	self.holder = holder
	
	self.shield = models:WaitForChild("Shield"):clone()
	
	self.shield1 = self.shield:WaitForChild("Shield1")
	self.shield1c = {}
	for _,v in pairs (self.shield1:GetChildren()) do
		if v:IsA("Decal") then
			table.insert(self.shield1c, v)
		end
	end
	
	self.shield2 = self.shield:WaitForChild("Shield2")
	self.shield2c = {}
	for _,v in pairs (self.shield2:GetChildren()) do
		if v:IsA("Decal") then
			table.insert(self.shield2c, v)
		end
	end
	
	self.shield3 = self.shield:WaitForChild("Shield3")
	self.shield3c = {}
	for _,v in pairs (self.shield3:GetChildren()) do
		if v:IsA("Decal") then
			table.insert(self.shield3c, v)
		end
	end
	
	--Initialize time
	self.time = 0
	self.rot = CFrame.new()
	self.hrp_cf = nil
	
	return self
end

function draw_shield:Destroy()
	--Destroy model instance
	self.shield:Destroy()
end

--Interface
function draw_shield:Enable()
	--Set parent
	self.shield.Parent = self.holder
end

function draw_shield:Disable()
	--Set parent
	self.shield.Parent = nil
end

local function GetTransparency(tim, off)
	return 1 - (math.clamp(math.cos((tim * 1.4) + (math.pi * 2 * off)), 0, 1) ^ 3)
end

function draw_shield:Draw(dt, hrp_cf)
	--Get shield transparencies
	self.time += dt
	
	local trans1 = GetTransparency(self.time, 0.000)
	local trans2 = GetTransparency(self.time, 0.333)
	local trans3 = GetTransparency(self.time, 0.666)
	
	--Apply shield transparencies
	for _,v in pairs(self.shield1c) do
		v.Transparency = trans1
	end
	
	for _,v in pairs(self.shield2c) do
		v.Transparency = trans2
	end
	
	for _,v in pairs(self.shield3c) do
		v.Transparency = trans3
	end
	
	--Set shield CFrame
	self.rot *= CFrame.Angles(dt * 0.16, dt * 0.21, dt * 0.19)
	self.shield:SetPrimaryPartCFrame(CFrame.new(hrp_cf.p) * self.rot)
	self.hrp_cf = hrp_cf
end

function draw_shield:LazyDraw(dt, hrp_cf)
	if hrp_cf ~= self.hrp_cf then
		--Set shield CFrame
		self.shield:SetPrimaryPartCFrame(CFrame.new(hrp_cf.p))
		self.hrp_cf = hrp_cf
	end
end

return draw_shield