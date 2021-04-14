--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Object/Spiketrap.lua
Purpose: Spiketrap object
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local spiketrap = {}

--Object contact
local function TouchPlayer(self, player)
	if player.v3 then
		return
	end
	
	--Damage player
	player:Damage(self.root.Position)
end

--Constructor and destructor
function spiketrap:New(object)
	--Initialize meta reference
	local self = setmetatable({}, {__index = spiketrap})
	
	--Use object information
	self.object = object
	self.root = object.PrimaryPart
	
	--Attach functions
	self.touch_player = TouchPlayer
	
	return self
end

function spiketrap:Destroy()
	
end

return spiketrap