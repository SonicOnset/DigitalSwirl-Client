--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Object/HomingTest.lua
Purpose: Homing Attack Test object
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local homing_test = {}

--Object functions
local function Update(self, i)
	--Decrement debounce
	if self.debounce > 0 then
		self.debounce = math.max(self.debounce - 1, 0)
	else
		self.update = nil
	end
end

--Object contact
local function TouchPlayer(self, player)
	--Perform debounce check
	if self.debounce == nil or self.debounce <= 0 then
		--Check if should interact
		if player.flag.grounded ~= true and player:BallActive() then
			--Bounce player
			player.pos += self.root.Position - player:GetMiddle()
			player:ObjectBounce()
			
			--Set debounce
			self.debounce = 6
			self.update = Update
		end
	end
end

--Constructor and destructor
function homing_test:New(object)
	--Initialize meta reference
	local self = setmetatable({}, {__index = homing_test})
	
	--Use object information
	self.object = object
	self.root = object.PrimaryPart
	
	--Attach functions
	self.touch_player = TouchPlayer
	
	--Set other specifications
	self.homing_target = true
	
	return self
end

function homing_test:Destroy()
	
end

return homing_test