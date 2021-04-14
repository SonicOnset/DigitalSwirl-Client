--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Hud/Text.lua
Purpose: HUD Text for scores and timer
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local text = {}

--Font and character information
local font_image = "rbxassetid://5805079273"
local font_width = 1024
local font_height = 92
local font_char_width = 78

local char_width = 0.2
local char_height = 0.26
local char_off = 0.725

local font_charmap = {
	['0'] =  0,
	['1'] =  1,
	['2'] =  2,
	['3'] =  3,
	['4'] =  4,
	['5'] =  5,
	['6'] =  6,
	['7'] =  7,
	['8'] =  8,
	['9'] =  9,
	['"'] = 10,
	[':'] = 11,
	['x'] = 12,
}

--Constructor and destructor
function text:New(gui, position)
	--Initialize meta reference
	local self = setmetatable({}, {__index = text})
	
	--Create container
	self.container = Instance.new("Frame")
	self.container.BackgroundTransparency = 1
	self.container.BorderSizePixel = 0
	self.container.AnchorPoint = Vector2.new(1, 1)
	self.container.Position = position
	self.container.Size = UDim2.new(char_width, 0, char_height, 0)
	self.container.SizeConstraint = Enum.SizeConstraint.RelativeYY
	self.container.Parent = gui
	
	--Initialize text state
	self.colour = Color3.new(1, 1, 1)
	self.chars = {}
	
	return self
end

function text:Destroy()
	--Destroy container
	self.container:Destroy()
end

--Text interface
function text:SetText(txt)
	debug.profilebegin("text:SetText")
	
	--Get new characters to type
	local new_chars = {}
	
	--Write new characters
	for i = 1, txt:len() do
		--Insert character
		local c = txt:sub(i, i)
		local map = font_charmap[c]
		table.insert(new_chars, Vector2.new(font_char_width * map, 0))
	end
	
	--Destroy or allocate new characters
	if #new_chars < #self.chars then
		for i = #new_chars + 1, #self.chars do
			self.chars[i]:Destroy()
			self.chars[i] = nil
		end
	elseif #new_chars > #self.chars then
		for i = #self.chars + 1, #new_chars do
			local new_char = Instance.new("ImageLabel")
			new_char.BackgroundTransparency = 1
			new_char.BorderSizePixel = 0
			new_char.Position = UDim2.new((1 - i) * char_off, 0, 0, 0)
			new_char.Size = UDim2.new(1, 0, 1, 0)
			new_char.Image = font_image
			new_char.ImageRectSize = Vector2.new(font_char_width, font_height)
			new_char.ImageColor3 = self.colour
			new_char.Parent = self.container
			self.chars[i] = new_char
		end
	end
	
	--Write characters
	for i = 1, #new_chars do
		local v = #new_chars - i + 1
		self.chars[i].ImageRectOffset = new_chars[v]
	end
	
	debug.profileend()
end

function text:SetColour(colour)
	--Update existing characters and set colour for next
	for _,v in pairs(self.container:GetChildren()) do
		v.ImageColor3 = colour
	end
	self.colour = colour
end

return text