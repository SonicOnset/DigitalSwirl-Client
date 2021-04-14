--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/Input/TouchButton.lua
Purpose: Mobile Touch Button class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local touch_button = {}

local gui_service = game:GetService("GuiService")
local uis = game:GetService("UserInputService")

--Constants
local pressed_col = Color3.new(0.75, 0.75, 0.75)
local released_col = Color3.new(1, 1, 1)

--Internal interface
local function OnInputEnded(self)
	--Reset button
	self.button.ImageColor3 = released_col
	if not self.enabled then
		self.button.Active = false
	end
	
	--Reset input state
	self.pressed = false
	self.move_touch_input = nil
end

--Constructor and destructor
function touch_button:New(parent_frame, pos, size)
	--Initialize meta reference
	local self = setmetatable({}, {__index = touch_button})
	
	--Create button
	self.button = Instance.new("ImageButton")
	self.button.Name = "Button"
	self.button.BackgroundTransparency = 1
	self.button.ImageTransparency = 1
	self.button.ImageColor3 = released_col
	self.button.Active = false
	self.button.Size = size
	self.button.Position = pos
	self.button.Parent = parent_frame
	
	--Initialize state
	self.pressed = false
	self.move_touch_input = nil
	self.enabled = false
	
	--Input connections
	self.input_connections = {
		self.button.InputBegan:Connect(function(input)
			--Make sure input is a valid state
			if self.enabled == false or self.move_touch_input ~= nil or input.UserInputType ~= Enum.UserInputType.Touch or input.UserInputState ~= Enum.UserInputState.Begin then
				return
			end
			
			--Start holding button
			self.move_touch_input = input
			self.button.ImageColor3 = pressed_col
			self.pressed = true
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

function touch_button:Destroy()
	--Disconnect connections
	if self.input_connections ~= nil then
		for _,v in pairs(self.input_connections) do
			v:Disconnect()
		end
		self.input_connections = nil
	end
	
	--Destroy button
	if self.button ~= nil then
		self.button:Destroy()
		self.button = nil
	end
end

--Button interface
function touch_button:Enable(id)
	if id ~= nil then
		if not self.enabled then
			self.button.ImageTransparency = 0
			self.button.Active = true
			self.enabled = true
		end
		if self.button.Image ~= id then
			self.button.Image = id
		end
	elseif self.enabled then
		self.button.ImageTransparency = 1
		self.enabled = false
	end
end

return touch_button