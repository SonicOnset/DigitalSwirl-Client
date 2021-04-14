--[[

= Sonic Onset Adventure Client =

Source: ControlScript/PlayerDraw/BallTrail.lua
Purpose: Player Draw Ball Trail class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local draw_ball_trail = {}

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local cframe = require(common_modules:WaitForChild("CFrame"))

--Constructor and destructor
function draw_ball_trail:New(holder, models)
	--Initialize meta reference
	local self = setmetatable({}, {__index = draw_ball_trail})
	
	--Create model instance
	self.holder = holder
	
	self.ball_trail = models:WaitForChild("BallTrail"):clone()
	self.ball_trails = self.ball_trail:WaitForChild("Trail"):GetChildren()
	self.ball_trail.Parent = self.holder
	
	--Initialize state
	self.enabled = false
	self.hrp_cf = nil
	
	return self
end

function draw_ball_trail:Destroy()
	--Destroy model instance
	self.ball_trail:Destroy()
end

--Interface
function draw_ball_trail:Enable()
	--Enable trails
	self.enabled = true
	for _,v in pairs(self.ball_trails) do
		v.Enabled = true
	end
end

function draw_ball_trail:Disable()
	--Disable trails
	self.enabled = false
	for _,v in pairs(self.ball_trails) do
		v.Enabled = false
	end
end

function draw_ball_trail:Draw(hrp_cf)
	if hrp_cf ~= self.hrp_cf then
		--Handle position tracking
		local prev_pos = self.hrp_cf and self.hrp_cf.p or hrp_cf.p
		local new_pos = hrp_cf.p
		
		local trail_cf
		if enabled then
			trail_cf = self.ball_trail.CFrame
		else
			trail_cf = hrp_cf
		end
		
		if new_pos ~= prev_pos then
			local look_dir = trail_cf.LookVector
			local diff_dir = (new_pos - prev_pos).unit
			if look_dir:Dot(diff_dir) < 0 then
				diff_dir *= -1
			end
			local new_ang = cframe.FromToRotation(look_dir, diff_dir) * (trail_cf - trail_cf.p)
			trail_cf = new_ang + new_pos
		else
			trail_cf = (trail_cf - trail_cf.p) + new_pos
		end
		
		self.ball_trail.CFrame = trail_cf
		self.hrp_cf = hrp_cf
	end
end

function draw_ball_trail:LazyDraw(hrp_cf)
	self.hrp_cf = hrp_cf
end

return draw_ball_trail