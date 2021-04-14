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
function draw_magnet_shield:New(hrp, holder)
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
	
	--Weld
	self.weld = Instance.new("Weld")
	self.weld.Part0 = hrp
	self.weld.Part1 = self.shield.PrimaryPart
	self.weld.Parent = self.shield.PrimaryPart
	
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
	if trans1 ~= self.trans1 then
		for _,v in pairs(self.shield1c) do
			v.Transparency = trans1
		end
		local beam1 = trans1 < 0.75
		if beam1 ~= self.beam1 then
			for _,v in pairs(self.shield1b) do
				v.Enabled = beam1
			end
			self.beam1 = beam1
		end
		self.trans1 = trans1
	end
	
	if trans2 ~= self.trans2 then
		for _,v in pairs(self.shield2c) do
			v.Transparency = trans2
		end
		local beam2 = trans2 < 0.75
		if beam2 ~= self.beam2 then
			for _,v in pairs(self.shield2b) do
				v.Enabled = beam2
			end
			self.beam2 = beam2
		end
		self.trans2 = trans2
	end
	
	if trans3 ~= self.trans3 then
		for _,v in pairs(self.shield3c) do
			v.Transparency = trans3
		end
		local beam3 = trans3 < 0.75
		if beam3 ~= self.beam3 then
			for _,v in pairs(self.shield3b) do
				v.Enabled = beam3
			end
			self.beam3 = beam3
		end
		self.trans3 = trans3
	end
	
	--Set shield CFrame
	self.rot *= CFrame.Angles(dt * 0.16, dt * 0.21, dt * 0.19)
	self.weld.C0 = (hrp_cf - hrp_cf.p):inverse() * self.rot
end

function draw_magnet_shield:LazyDraw(dt, hrp_cf)
	
end

return draw_magnet_shield