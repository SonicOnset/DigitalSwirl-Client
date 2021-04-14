--[[

= DigitalSwirl =

Source: CommonModules/CameraUtil.lua
Purpose: Camera utility functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local camera_util = {}

--Camera frustum check
local last_camera_res = nil
local last_camera_fov = nil
local cam_planes = nil
function camera_util.CheckFrustum(point, rad)
	--Update camera planes if FOV or resolution changed
	local camera = workspace.CurrentCamera
	if cam_planes == nil or camera.ViewportSize ~= last_camera_res or camera.FieldOfView ~= last_camera_fov then
		--Get camera factors
		last_camera_res = camera.ViewportSize
		last_camera_fov = camera.FieldOfView
		
		local aspectRatio = last_camera_res.X / last_camera_res.Y
		local hFactor = math.tan(math.rad(last_camera_fov) / 2)
		local wFactor = aspectRatio * hFactor
		
		--Get planes
		cam_planes = {
			Vector3.new(hFactor, 0, 1).unit,
			Vector3.new(0, wFactor, 1).unit,
			Vector3.new(-hFactor, 0, 1).unit,
			Vector3.new(0, -wFactor, 1).unit,
		}
	end
	
	--Test against camera planes
	local cframe = camera.CFrame
	local local_pos = cframe:inverse() * point
	
	for _,v in pairs(cam_planes) do
		if v:Dot(local_pos) > rad then
			return false
		end
	end
	
	return true
end

return camera_util