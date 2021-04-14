--[[

= Sonic Onset Adventure Client =

Source: ControlScript/PlayerDraw/SpindashBall.lua
Purpose: Player Draw Spindash Ball class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local draw_spindash_ball = {}

--Constructor and destructor
function draw_spindash_ball:New(hrp, holder, models)
	--Initialize meta reference
	local self = setmetatable({}, {__index = draw_spindash_ball})
	
	--Create model instance
	self.holder = holder
	
	self.spindash_ball = models:WaitForChild("SpindashBall"):clone()
	self.spindash_ball.Parent = self.holder
	self.frames = {}
	for i = 1, 5 do
		self.frames[i] = self.spindash_ball:WaitForChild("Frame"..tostring(i))
		self.frames[i].Transparency = 1
	end
	
	--Weld
	local weld = Instance.new("Weld")
	weld.Part0 = hrp
	weld.Part1 = self.spindash_ball.PrimaryPart
	weld.Parent = self.spindash_ball.PrimaryPart
	
	--Initialize state
	self.spin = 0
	self.frame = 1
	
	return self
end

function draw_spindash_ball:Destroy()
	--Destroy model instance
	self.spindash_ball:Destroy()
end

--Interface
function draw_spindash_ball:Enable()
	--Show current frame
	if self.frames[self.frame] ~= nil then
		self.frames[self.frame].Transparency = 0
	end
end

function draw_spindash_ball:Disable()
	--Hide current frame
	if self.frames[self.frame] ~= nil then
		self.frames[self.frame].Transparency = 1
	end
end

function draw_spindash_ball:Draw(dt, hrp_cf, spin)
	--Change shown spindash ball frame
	self.spin += spin * dt
	
	local frame = 1 + math.floor(((self.spin / (math.pi * 2)) % 1) * 5)
	if frame ~= self.frame then
		if self.frames[self.frame] ~= nil then
			self.frames[self.frame].Transparency = 1
		end
		if self.frames[frame] ~= nil then
			self.frames[frame].Transparency = 0
		end
		self.frame = frame
	end
end

function draw_spindash_ball:LazyDraw(dt, hrp_cf, spin)
	
end

return draw_spindash_ball