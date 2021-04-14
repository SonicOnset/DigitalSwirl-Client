--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Hud/RingFlash.lua
Purpose: HUD Ring Flash for when you collect a ring
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local ring_flash = {}

--Common functions
local function lerp(x, y, z)
	return x + (y - x) * z
end

--Constructor and destructor
function ring_flash:New(gui)
	--Initialize meta reference
	local self = setmetatable({}, {__index = ring_flash})
	
	--Initialize ring flash state
	self.flash_t = 0
	self.flash_len = 0.4
	self.flash_from = 1.05
	self.flash_to = 1.8
	
	--Create flash
	self.flash = Instance.new("ImageLabel")
	self.flash.BackgroundTransparency = 1
	self.flash.BorderSizePixel = 0
	self.flash.AnchorPoint = Vector2.new(0.5, 0.5)
	self.flash.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.flash.Size = UDim2.new(self.flash_from, 0, self.flash_from, 0)
	self.flash.Image = "rbxassetid://5781543083"
	self.flash.Parent = gui
	
	return self
end

function ring_flash:Destroy()
	--Destroy flash
	self.flash:Destroy()
end

--Ring flash interface
function ring_flash:Update(dt)
	--Increment ring flash time
	self.flash_t += dt
	if self.flash_t >= self.flash_len then
		return true
	end
	
	--Update flash
	local per = math.sqrt(self.flash_t / self.flash_len)
	local dia = lerp(self.flash_from, self.flash_to, per)
	self.flash.Size = UDim2.new(dia, 0, dia, 0)
	self.flash.ImageTransparency = per
	return false
end

return ring_flash