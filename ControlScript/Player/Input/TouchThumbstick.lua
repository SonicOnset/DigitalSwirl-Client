--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/Input/TouchThumbstick.lua
Purpose: Mobile Touch Thumbstick class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]


local touch_thumbstick = {}

local gui_service = game:GetService("GuiService")
local uis = game:GetService("UserInputService")

--Sheet
local sheet_image = "rbxassetid://3505674311"
local sheet_outer_off = Vector2.new(0, 0)
local sheet_outer_size = Vector2.new(146, 146)
local sheet_stick_off = Vector2.new(146, 0)
local sheet_stick_size = Vector2.new(74, 74)

--Constants
local deadzone = 0.05

--Internal interface
local function OnInputEnded(self)
	--Reset stick positions
	self.frame.Position = self.orig_pos
	self.stick_image.Position = UDim2.new(0.5, 0, 0.5, 0)
	
	--Reset input state
	self.move_vector = Vector2.new()
	self.move_touch_input = nil
end

local function DoMove(self, direction)
	--Get move vector
	local current_move_vector = direction / (self.frame.AbsoluteSize / 2)
	
	--Scaled Radial Dead Zone
	local input_axis_magnitude = current_move_vector.magnitude
	if input_axis_magnitude < deadzone then
		current_move_vector = Vector3.new()
	elseif input_axis_magnitude < 1 then
		current_move_vector = current_move_vector.unit * ((input_axis_magnitude - deadzone) / (1 - deadzone))
		current_move_vector = Vector2.new(current_move_vector.X, current_move_vector.Y)
	else
		current_move_vector = current_move_vector.unit
	end
	
	--Set final move vector
	self.move_vector = current_move_vector
end

local function MoveStick(self, pos)
	--Get stick position
	local relative_position = pos - (self.frame.AbsolutePosition + self.frame.AbsoluteSize / 2)
	local max_length = math.max(self.frame.AbsoluteSize.X, self.frame.AbsoluteSize.Y) / 2
	if relative_position.magnitude > max_length then
		relative_position = relative_position.unit * max_length
	end
	self.stick_image.Position = UDim2.new(0.5, relative_position.X, 0.5, relative_position.Y)
end

--Constructor and destructor
function touch_thumbstick:New(parent_frame, pos, size)
	--Initialize meta reference
	local self = setmetatable({}, {__index = touch_thumbstick})
	
	--Remember given position
	self.orig_pos = pos
	self.orig_size = size
	
	--Create thumbstick container
	self.frame = Instance.new("Frame")
	self.frame.Name = "ThumbstickFrame"
	self.frame.Active = true
	self.frame.Visible = false
	self.frame.Size = size
	self.frame.Position = pos
	self.frame.BackgroundTransparency = 1
	self.frame.Parent = parent_frame
	
	--Create thumbstick outer image
	local outer_image = Instance.new("ImageLabel")
	outer_image.Name = "OuterImage"
	outer_image.Image = sheet_image
	outer_image.ImageRectOffset = sheet_outer_off
	outer_image.ImageRectSize = sheet_outer_size
	outer_image.BackgroundTransparency = 1
	outer_image.Size = UDim2.new(1, 0, 1, 0)
	outer_image.AnchorPoint = Vector2.new(0.5, 0.5)
	outer_image.Position = UDim2.new(0.5, 0, 0.5, 0)
	outer_image.Parent = self.frame
	
	self.stick_image = Instance.new("ImageLabel")
	self.stick_image.Name = "StickImage"
	self.stick_image.Image = sheet_image
	self.stick_image.ImageRectOffset = sheet_stick_off
	self.stick_image.ImageRectSize = sheet_stick_size
	self.stick_image.BackgroundTransparency = 1
	self.stick_image.Size = UDim2.new(0.5, 0, 0.5, 0)
	self.stick_image.AnchorPoint = Vector2.new(0.5, 0.5)
	self.stick_image.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.stick_image.ZIndex = 2
	self.stick_image.Parent = self.frame
	
	--Initial state
	self.move_vector = Vector2.new()
	self.move_touch_input = nil
	self.enabled = false
	
	--Input connections
	self.input_connections = {
		self.frame.InputBegan:Connect(function(input)
			--Make sure input is a valid state
			if self.move_touch_input ~= nil or input.UserInputType ~= Enum.UserInputType.Touch or input.UserInputState ~= Enum.UserInputState.Begin then
				return
			end
			
			--Start capturing input and set thumbstick position
			self.move_touch_input = input
			self.frame.Position = UDim2.new(0, input.Position.X - self.frame.AbsoluteSize.X / 2, 0, input.Position.Y - self.frame.AbsoluteSize.Y / 2)
		end),
		uis.TouchMoved:Connect(function(input, processed)
			--Make sure this is the current move input
			if input == self.move_touch_input then
				--Move stick
				local input_pos = Vector2.new(input.Position.X, input.Position.Y)
				local direction = input_pos - (self.frame.AbsolutePosition + self.frame.AbsoluteSize / 2)
				DoMove(self, direction)
				MoveStick(self, input_pos)
			end
		end),
		uis.TouchEnded:Connect(function(input, processed)
			if input == self.move_touch_input then
				OnInputEnded(self)
			end
		end),
		gui_service.MenuOpened:Connect(function()
			if self.move_touch_input ~= nil then
				OnInputEnded(self)
			end
		end),
	}
	
	return self
end

function touch_thumbstick:Destroy()
	--Disconnect connections
	if self.input_connections ~= nil then
		for _,v in pairs(self.input_connections) do
			v:Disconnect()
		end
		self.input_connections = nil
	end
	
	--Destroy thumbstick frame
	if self.frame ~= nil then
		self.frame:Destroy()
		self.frame = nil
	end
end

--Thumbstick interface
function touch_thumbstick:Enable(enabled)
	if self.enabled ~= enabled then
		self.frame.Visible = enabled
		self.enabled = enabled
	end
end

return touch_thumbstick