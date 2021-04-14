--[[

= DigitalSwirl Client =

Source: ControlScript/Constants.lua
Purpose: Common game constants
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

return {
	--Game framerate
	framerate = 60,
	
	--Player states
	state = {
		idle = 0,
		walk = 1,
		skid = 2,
		spindash = 3,
		roll = 4,
		airborne = 5,
		homing = 6,
		bounce = 7,
		rail = 8,
		light_speed_dash = 9,
		air_kick = 10,
		ragdoll = 11,
		hurt = 12,
		dead = 13,
		drown = 14,
	},
}