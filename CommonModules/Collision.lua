--[[

= DigitalSwirl =

Source: CommonModules/Collision.lua
Purpose: Collision functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local collision_module = {}

--Raycasting collision
function collision_module.Raycast(wl, from, dir)
	local param = RaycastParams.new()
	param.FilterType = Enum.RaycastFilterType.Whitelist
	param.FilterDescendantsInstances = wl
	param.IgnoreWater = true
	local result = workspace:Raycast(from, dir, param)
	if result then
		return result.Instance, result.Position, result.Normal, result.Material
	else
		return nil, from + dir, nil, Enum.Material.Air
	end
end

--Sphere to box collision
function collision_module.SqDistPointAABB(point, box)
	local sq_dist = 0
	
	--X axis check
	local v = point.X
	if v < box.min.X then
		sq_dist += (box.min.X - v) * (box.min.X - v)
	end
	if v > box.max.X then
		sq_dist += (v - box.max.X) * (v - box.max.X)
	end
	
	--Y axis check
	local v = point.Y
	if v < box.min.Y then
		sq_dist += (box.min.Y - v) * (box.min.Y - v)
	end
	if v > box.max.Y then
		sq_dist += (v - box.max.Y) * (v - box.max.Y)
	end
	
	--Z axis check
	local v = point.Z
	if v < box.min.Z then
		sq_dist += (box.min.Z - v) * (box.min.Z - v)
	end
	if v > box.max.Z then
		sq_dist += (v - box.max.Z) * (v - box.max.Z)
	end
	
	return sq_dist
end

function collision_module.TestSphereAABB(sphere, box)
	local sq_dist = collision_module.SqDistPointAABB(sphere.center, box)
	return sq_dist <= (sphere.radius ^ 2)
end

function collision_module.TestSphereRotatedBox(sphere, rotated_box)
	local sq_dist = collision_module.SqDistPointAABB(rotated_box.cframe:inverse() * sphere.center, {min = rotated_box.size / -2, max = rotated_box.size / 2})
	return sq_dist <= (sphere.radius ^ 2)
end

return collision_module