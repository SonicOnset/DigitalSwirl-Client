--[[

= Sonic Onset Adventure Client =

Source: ControlScript/PlayerDraw/JumpBall.lua
Purpose: Player Draw Jump Ball class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local draw_jump_ball = {}

--Constructor and destructor
function draw_jump_ball:New(hrp, holder, models)
	--Initialize meta reference
	local self = setmetatable({}, {__index = draw_jump_ball})
	
	--Create model instance
	self.holder = holder
	
	self.jump_ball = models:WaitForChild("JumpBall"):clone()
	self.jump_ball.Parent = holder
	
	self.jump_ball_char = self.jump_ball:WaitForChild("Character")
	self.jump_ball_smear = self.jump_ball:WaitForChild("Smear")
	self.jump_ball_char.Transparency = 1
	self.jump_ball_smear.Transparency = 1
	
	--Weld
	self.weld = Instance.new("Weld")
	self.weld.Part0 = hrp
	self.weld.Part1 = self.jump_ball.PrimaryPart
	self.weld.Parent = self.jump_ball.PrimaryPart
	
	return self
end

function draw_jump_ball:Destroy()
	--Destroy model instance
	self.jump_ball:Destroy()
end

--Interface
function draw_jump_ball:Enable()
	--Show jump ball
	self.jump_ball_char.Transparency = 0
end

function draw_jump_ball:Disable()
	--Hide jump ball
	self.jump_ball_char.Transparency = 1
	self.jump_ball_smear.Transparency = 1
end

function draw_jump_ball:Draw(dt, hrp_cf, spin)
	--Modify jump ball smear transparency
	local smear = math.clamp((math.abs(spin) - 20) / 45, 0, 1)
	self.jump_ball_smear.Transparency = 1 - smear
	
	--Spin jumpball
	self.weld.C0 *= CFrame.fromAxisAngle(Vector3.new(-1, 0, 0), spin * dt)
end

function draw_jump_ball:LazyDraw(dt, hrp_cf, spin)
	
end

return draw_jump_ball