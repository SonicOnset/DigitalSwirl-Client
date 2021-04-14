--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/Input.lua
Purpose: Player input functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_input = {}

local player = game:GetService("Players").LocalPlayer
local uis = game:GetService("UserInputService")
local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")

local vector = require(common_modules:WaitForChild("Vector"))
local cframe = require(common_modules:WaitForChild("CFrame"))

local touch_thumbstick = require(script:WaitForChild("TouchThumbstick"))
local touch_button = require(script:WaitForChild("TouchButton"))

--Constants
local button_ids = {
	["Jump"] = "rbxassetid://5999555026",
	["HomingAttack"] = "rbxassetid://5999555026",
	["Spindash"] = "rbxassetid://5999556527",
	["Crouch"] = "rbxassetid://5999555839",
	["Roll"] = "rbxassetid://5999556527",
	["Bounce"] = "rbxassetid://5999555611",
	["LightSpeedDash"] = "rbxassetid://5999556218",
	["AirKick"] = "rbxassetid://5999555261",
}


--Input bindings
local buttons = {
	"jump", "roll", "secondary_action", "tertiary_action", "dbg"
}

local keyboard_bind = {
	[Enum.KeyCode.Space] = "jump",
	[Enum.KeyCode.E] = "roll",
	[Enum.KeyCode.LeftShift] = "roll",
	[Enum.KeyCode.Q] = "secondary_action",
	[Enum.KeyCode.R] = "tertiary_action",
	[Enum.KeyCode.LeftAlt] = "dbg",
}

local gamepad_bind = {
	[Enum.KeyCode.ButtonA] = "jump",
	[Enum.KeyCode.ButtonB] = "roll",
	[Enum.KeyCode.ButtonX] = "roll",
	[Enum.KeyCode.ButtonY] = "secondary_action",
	[Enum.KeyCode.ButtonR1] = "tertiary_action",
}

--Internal interface
local function GetInputForDevice(inputs, bind)
	local res = {}
	for _,v in pairs(inputs) do
		local bind = bind[v]
		if bind then
			res[bind] = true
		end
	end
	return res
end

local function MergeInputs(...)
	local res = {}
	for _, v in pairs({...}) do
		for i, j in pairs(v) do
			res[i] = j
		end
	end
	return res
end

--Input interface
function player_input.Initialize(self)
	--Initialize input
	self.input = {
		--Analogue stick state
		stick_x = 0,
		stick_y = 0,
		stick_mag = 0,
		
		--Button state
		button = {},
		button_press = {},
		button_prev = {},
	}
	
	--Create mobile gui
	if uis.TouchEnabled then
		--Create containing ScreenGui
		self.touch_gui = Instance.new("ScreenGui")
		self.touch_gui.Name = "TouchGui"
		self.touch_gui.DisplayOrder = 5
		self.touch_gui.ResetOnSpawn = false
		self.touch_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		
		--Create left and right containers
		local touch_frame_left = Instance.new("Frame")
		touch_frame_left.Name = "FrameLeft"
		touch_frame_left.BackgroundTransparency = 1
		touch_frame_left.BorderSizePixel = 0
		touch_frame_left.Size = UDim2.new(1, 0, 1, 0)
		touch_frame_left.AnchorPoint = Vector2.new(0, 1)
		touch_frame_left.Position = UDim2.new(0, 0, 1, 0)
		touch_frame_left.Parent = self.touch_gui
		Instance.new("UIAspectRatioConstraint", touch_frame_left)
		
		local touch_frame_right = Instance.new("Frame")
		touch_frame_right.Name = "FrameRight"
		touch_frame_right.BackgroundTransparency = 1
		touch_frame_right.BorderSizePixel = 0
		touch_frame_right.Size = UDim2.new(1, 0, 1, 0)
		touch_frame_right.AnchorPoint = Vector2.new(1, 1)
		touch_frame_right.Position = UDim2.new(1, 0, 1, 0)
		touch_frame_right.Parent = self.touch_gui
		Instance.new("UIAspectRatioConstraint", touch_frame_right)
		
		--Get screen information
		local camera = workspace.CurrentCamera
		local min_axis = math.min(camera.ViewportSize.X, camera.ViewportSize.Y)
		local small_screen = min_axis <= 500
		
		--Create thumbstick
		local thumbstick_dim = small_screen and 90 or 120
		local thumbstick_size = UDim2.new(0, thumbstick_dim, 0, thumbstick_dim)
		local thumbstick_pos = UDim2.new(0, 50, 1, -40 - thumbstick_dim)
		self.touch_thumbstick = touch_thumbstick:New(touch_frame_left, thumbstick_pos, thumbstick_size)
		
		--Create jump button
		local jump_dim = small_screen and 90 or 120
		local jump_size = UDim2.new(0, jump_dim, 0, jump_dim)
		local jump_pos = UDim2.new(1, -50 - jump_dim, 1, -40 - jump_dim)
		self.touch_jump_button = touch_button:New(touch_frame_right, jump_pos, jump_size)
		
		--Create small buttons
		local small_dim = small_screen and 75 or 100
		local small_size = UDim2.new(0, small_dim, 0, small_dim)
		
		--Create roll button
		local roll_pos = UDim2.new(1, -50 - jump_dim - 15 - small_dim, 1, -40 - jump_dim + 15)
		self.touch_roll_button = touch_button:New(touch_frame_right, roll_pos, small_size)
		
		--Create secondary action button
		local secondary_pos = UDim2.new(1, -50 - jump_dim - small_dim + 10, 1, -40 - jump_dim - small_dim + 10)
		self.touch_secondary_button = touch_button:New(touch_frame_right, secondary_pos, small_size)
		
		--Create tertiary action button
		local tertiary_pos = UDim2.new(1, -50 - jump_dim + 10, 1, -40 - jump_dim - small_dim - 5)
		self.touch_tertiary_button = touch_button:New(touch_frame_right, tertiary_pos, small_size)
		
		--Parent touch gui
		self.touch_gui.Parent = player:WaitForChild("PlayerGui")
	end
end

function player_input.Quit(self)
	--Delete mobile gui and inputs
	if self.touch_tertiary_button ~= nil then
		self.touch_tertiary_button:Destroy()
		self.touch_tertiary_button = nil
	end
	if self.touch_secondary_button ~= nil then
		self.touch_secondary_button:Destroy()
		self.touch_secondary_button = nil
	end
	if self.touch_roll_button ~= nil then
		self.touch_roll_button:Destroy()
		self.touch_roll_button = nil
	end
	if self.touch_jump_button ~= nil then
		self.touch_jump_button:Destroy()
		self.touch_jump_button = nil
	end
	if self.touch_thumbstick ~= nil then
		self.touch_thumbstick:Destroy()
		self.touch_thumbstick = nil
	end
	if self.touch_gui ~= nil then
		self.touch_gui:Destroy()
		self.touch_gui = nil
	end
end

function player_input.Update(self)
	--Get input state
	local stick_x, stick_y = 0, 0
	if uis:GetFocusedTextBox() then
		--Don't process any input
		self.input.button = {}
		
		--Disable mobile inputs
		if self.touch_thumbstick ~= nil then
			self.touch_thumbstick:Enable(false)
		end
		if self.touch_jump_button ~= nil then
			self.touch_jump_button:Enable(nil)
		end
		if self.touch_roll_button ~= nil then
			self.touch_roll_button:Enable(nil)
		end
		if self.touch_secondary_button ~= nil then
			self.touch_secondary_button:Enable(nil)
		end
		if self.touch_tertiary_button ~= nil then
			self.touch_tertiary_button:Enable(nil)
		end
	else
		--Get input state
		local key_input_state = uis:GetKeysPressed()
		local gamepad_input_state = uis:GetGamepadState(Enum.UserInputType.Gamepad1)
		
		--Process key input
		local key_input = {}
		local w, a, s, d = false, false, false, false
		for _,v in pairs(key_input_state) do
			if v.UserInputState == Enum.UserInputState.Begin then
				if v.KeyCode == Enum.KeyCode.W then
					w = true
				elseif v.KeyCode == Enum.KeyCode.A then
					a = true
				elseif v.KeyCode == Enum.KeyCode.S then
					s = true
				elseif v.KeyCode == Enum.KeyCode.D then
					d = true
				end
				table.insert(key_input, v.KeyCode)
			end
		end
		
		stick_x += (d and 1 or 0) - (a and 1 or 0)
		stick_y += (s and 1 or 0) - (w and 1 or 0)
		
		--Process gamepad input
		local gamepad_input = {}
		for _,v in pairs(gamepad_input_state) do
			if v.KeyCode == Enum.KeyCode.Thumbstick1 then
				stick_x += v.Position.X
				stick_y -= v.Position.Y
			elseif v.UserInputState == Enum.UserInputState.Begin then
				table.insert(gamepad_input, v.KeyCode)
			end
		end
		
		--Process button input
		self.input.button = MergeInputs(
			GetInputForDevice(key_input, keyboard_bind),
			GetInputForDevice(gamepad_input, gamepad_bind)
		)
		
		--Process mobile input
		if self.touch_thumbstick ~= nil then
			self.touch_thumbstick:Enable(true)
			stick_x += self.touch_thumbstick.move_vector.X
			stick_y += self.touch_thumbstick.move_vector.Y
		end
		
		if self.touch_jump_button ~= nil then
			if self.jump_action ~= nil then
				self.touch_jump_button:Enable(button_ids[self.jump_action])
			else
				self.touch_jump_button:Enable(nil)
			end
			self.input.button.jump = self.input.button.jump or self.touch_jump_button.pressed
		end
		
		if self.touch_roll_button ~= nil then
			if self.roll_action ~= nil then
				self.touch_roll_button:Enable(button_ids[self.roll_action])
			else
				self.touch_roll_button:Enable(nil)
			end
			self.input.button.roll = self.input.button.roll or self.touch_roll_button.pressed
		end
		
		if self.touch_secondary_button ~= nil then
			if self.secondary_action ~= nil then
				self.touch_secondary_button:Enable(button_ids[self.secondary_action])
			else
				self.touch_secondary_button:Enable(nil)
			end
			self.input.button.secondary_action = self.input.button.secondary_action or self.touch_secondary_button.pressed
		end
		
		if self.touch_tertiary_button ~= nil then
			if self.tertiary_action ~= nil then
				self.touch_tertiary_button:Enable(button_ids[self.tertiary_action])
			else
				self.touch_tertiary_button:Enable(nil)
			end
			self.input.button.tertiary_action = self.input.button.tertiary_action or self.touch_tertiary_button.pressed
		end
	end
	
	--Set stick state
	self.input.stick_mag = math.sqrt((stick_x ^ 2) + (stick_y ^ 2))
	if self.input.stick_mag > 0.15 then
		if self.input.stick_mag > 1 then
			self.input.stick_x = stick_x / self.input.stick_mag
			self.input.stick_y = stick_y / self.input.stick_mag
			self.input.stick_mag = 1
		else
			self.input.stick_x = stick_x
			self.input.stick_y = stick_y
		end
	else
		self.input.stick_x = 0
		self.input.stick_y = 0
		self.input.stick_mag = 0
	end
	
	--Get pressed buttons
	for _, v in pairs(buttons) do
		if self.input.button[v] == true then
			self.input.button_press[v] = self.input.button_prev[v] ~= true
			self.input.button_prev[v] = true
		else
			self.input.button[v] = false
			self.input.button_press[v] = false
			self.input.button_prev[v] = false
		end
	end
end

function player_input.HasControl(self)
	return true
end

function player_input.GetAnalogue_Turn(self)
	if player_input.HasControl(self) then
		if self.spring_timer > 0 or self.dashpanel_timer > 0 or self.dashring_timer > 0 then
			self.last_turn = 0
			return self.last_turn
		elseif self.input.stick_mag ~= 0 then
			--Get character vectors
			local tgt_up = Vector3.new(0, 1, 0)
			local look = self:GetLook()
			local up = self:GetUp()
			
			--Get camera angle, aligned to our target up vector
			local cam_look = vector.PlaneProject(workspace.CurrentCamera.CFrame.LookVector, tgt_up)
			if cam_look.magnitude ~= 0 then
				cam_look = cam_look.unit
			else
				cam_look = look
			end
			
			--Get move vector in world space, aligned to our target up vector
			local cam_move = CFrame.fromAxisAngle(tgt_up, math.atan2(-self.input.stick_x, -self.input.stick_y)) * cam_look
			
			--Update last up
			if self.last_up == nil or tgt_up:Dot(up) >= -0.999 then
				self.last_up = up
			end
			
			--Get final rotation and move vector
			local final_rotation = cframe.FromToRotation(tgt_up, self.last_up)
			
			local final_move = vector.PlaneProject(final_rotation * cam_move, up)
			if final_move.magnitude ~= 0 then
				final_move = final_move.unit
			else
				final_move = look
			end
			
			--Get turn amount
			self.last_turn = vector.SignedAngle(look, final_move, up)
			return self.last_turn
		end
	end
	
	self.last_turn = 0
	return self.last_turn
end

function player_input.GetAnalogue_Mag(self)
	if player_input.HasControl(self) then
		if self.spring_timer > 0 then
			return 0
		elseif self.dashpanel_timer > 0 or self.dashring_timer > 0 then
			return 1
		else
			return self.input.stick_mag
		end
	else
		return 0
	end
end

function player_input.GetAnalogue(self)
	local turn = player_input.GetAnalogue_Turn(self)
	local mag = player_input.GetAnalogue_Mag(self)
	return (player_input.HasControl(self) and mag ~= 0), turn, mag
end

return player_input