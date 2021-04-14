--[[

= DigitalSwirl =

Source: CommonModules/Switch.lua
Purpose: Switch case implementation
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

return function(v, a, cases)
	if cases[v] ~= nil then
		return cases[v](unpack(a))
	end
end