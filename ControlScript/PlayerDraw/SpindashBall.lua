--[[

= Sonic Onset Adventure Client =

Source: ControlScript/PlayerDraw/SpindashBall.lua
Purpose: Player Draw Spindash Ball class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local draw_spindash_ball = {}

--Constructor and destructor
function draw_spindash_ball:New(holder, models)
	--Initialize meta reference
	local self = setmetatable({}, {__index = draw_spindash_ball})
	
	--Create model instance
	self.holder = holder
	
	self.spindash_ball = models:WaitForChild("SpindashBall"):clone()
	self.frames = {}
	for i = 1, 5 do
		self.frames[i] = self.spindash_ball:WaitForChild("Frame"..tostring(i))
	end
	
	--Initialize state
	self.spin = 0
	self.frame = 1
	self.hrp_cf = nil
	
	return self
end

function draw_spindash_ball:Destroy()
	--Destroy model instance
	self.spindash_ball:Destroy()
end

--Interface
function draw_spindash_ball:Enable()
	--Set parent
	self.spindash_ball.Parent = self.holder
end

function draw_spindash_ball:Disable()
	--Set parent
	self.spindash_ball.Parent = nil
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
	
	if hrp_cf ~= self.hrp_cf then
		--Set spindash ball CFrame
		self.spindash_ball:SetPrimaryPartCFrame(hrp_cf)
		self.hrp_cf = hrp_cf
	end
end

function draw_spindash_ball:LazyDraw(dt, hrp_cf, spin)
	if hrp_cf ~= self.hrp_cf then
		--Set spindash ball CFrame
		self.spindash_ball:SetPrimaryPartCFrame(hrp_cf)
		self.hrp_cf = hrp_cf
	end
end

return draw_spindash_ball