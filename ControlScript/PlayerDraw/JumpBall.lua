--[[

= Sonic Onset Adventure Client =

Source: ControlScript/PlayerDraw/JumpBall.lua
Purpose: Player Draw Jump Ball class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local draw_jump_ball = {}

--Constructor and destructor
function draw_jump_ball:New(holder, models)
	--Initialize meta reference
	local self = setmetatable({}, {__index = draw_jump_ball})
	
	--Create model instance
	self.holder = holder
	
	self.jump_ball = models:WaitForChild("JumpBall"):clone()
	self.jump_ball_smear = self.jump_ball:WaitForChild("Smear")
	
	--Initialize state
	self.spin = 0
	self.hrp_cf = nil
	
	return self
end

function draw_jump_ball:Destroy()
	--Destroy model instance
	self.jump_ball:Destroy()
end

--Interface
function draw_jump_ball:Enable()
	--Set parent
	self.jump_ball.Parent = self.holder
end

function draw_jump_ball:Disable()
	--Set parent
	self.jump_ball.Parent = nil
end

function draw_jump_ball:Draw(dt, hrp_cf, spin)
	if hrp_cf ~= self.hrp_cf then
		--Modify jump ball smear transparency
		local smear = math.clamp((math.abs(spin) - 20) / 50, 0, 1)
		self.jump_ball_smear.Transparency = 1 - smear
		
		--Set jump ball CFrame
		self.spin += spin * dt
		self.jump_ball:SetPrimaryPartCFrame(hrp_cf * CFrame.Angles(-self.spin, 0, 0))
		self.hrp_cf = hrp_cf
	end
end

function draw_jump_ball:LazyDraw(dt, hrp_cf, spin)
	if hrp_cf ~= self.hrp_cf then
		--Set jump ball CFrame
		self.jump_ball:SetPrimaryPartCFrame(hrp_cf)
		self.hrp_cf = hrp_cf
	end
end

return draw_jump_ball