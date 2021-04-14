--[[

= DigitalSwirl =

Source: CommonModules/CFrame.lua
Purpose: CFrame functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local cframe = {}

local vector = require(script.Parent:WaitForChild("Vector"))

function cframe.FromToRotation(from, to)
	--Get our axis and angle
	local axis = from:Cross(to)
	local angle = vector.Angle(from, to)
	
	--Create matrix from axis and angle
	if angle <= -math.pi then
		return CFrame.fromAxisAngle(Vector3.new(0, 0, 1), math.pi)
	elseif axis.magnitude ~= 0 then
		return CFrame.fromAxisAngle(axis, angle)
	else
		return CFrame.new()
	end
end

return cframe