--[[

= DigitalSwirl =

Source: CommonModules/Vector.lua
Purpose: Vector functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local vector = {}

function vector.Flatten(vector, normal)
	local dot = vector:Dot(normal.unit)
	return vector - (normal.unit) * dot
end

function vector.PlaneProject(point, nor)
	local ptpd = (nor.unit):Dot(point)
	return point - ((nor.unit) * ptpd), ptpd
end

function vector.Angle(from, to)
	local dot = (from.unit):Dot(to.unit)
	if dot >= 1 then
		return 0
	elseif dot <= -1 then
		return -math.pi
	end
	return math.acos(dot)
end

function vector.SignedAngle(from, to, up)
	local right = (up.unit):Cross(from).unit
	local dot = (from.unit):Dot(to.unit)
	local rdot = math.sign(right:Dot(to.unit))
	if rdot == 0 then
		rdot = 1
	end
	if dot >= 1 then
		return 0
	elseif dot <= -1 then
		return -math.pi * rdot
	end
	return math.acos(dot) * rdot
end

function vector.AddX(vector, x)
	return vector + Vector3.new(x, 0, 0)
end

function vector.AddY(vector, y)
	return vector + Vector3.new(0, y, 0)
end

function vector.AddZ(vector, z)
	return vector + Vector3.new(0, 0, z)
end

function vector.MulX(vector, x)
	return vector * Vector3.new(x, 1, 1)
end

function vector.MulY(vector, y)
	return vector * Vector3.new(1, y, 1)
end

function vector.MulZ(vector, z)
	return vector * Vector3.new(1, 1, z)
end

function vector.DivX(vector, x)
	return vector / Vector3.new(x, 1, 1)
end

function vector.DivY(vector, y)
	return vector / Vector3.new(1, y, 1)
end

function vector.DivZ(vector, z)
	return vector / Vector3.new(1, 1, z)
end

function vector.SetX(vector, x)
	return Vector3.new(x, vector.Y, vector.Z)
end

function vector.SetY(vector, y)
	return Vector3.new(vector.X, y, vector.Z)
end

function vector.SetZ(vector, z)
	return Vector3.new(vector.X, vector.Y, z)
end

return vector