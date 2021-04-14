--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Hud/ItemCard.lua
Purpose: HUD Item Cards for when you collect an item
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local item_card = {}

--Item card sheet information
local sheet_l = 3
local sheet_t = 3
local sheet_w = 167
local sheet_h = 167
local sheet_ix = 170
local sheet_iy = 170

--Common functions
local function lerp(x, y, z)
	return x + (y - x) * z
end

--Constructor and destructor
function item_card:New(gui, x, sx, sy)
	--Initialize meta reference
	local self = setmetatable({}, {__index = item_card})
	
	--Initialize item card state
	self.x = x
	self.card_t = 0
	self.card_len = 2.375
	self.card_intrans = 0.375
	self.card_outtrans = 0.75
	
	--Create card
	self.card = Instance.new("ImageLabel")
	self.card.BackgroundTransparency = 1
	self.card.BorderSizePixel = 0
	self.card.AnchorPoint = Vector2.new(0.5, 0.5)
	self.card.Position = UDim2.new(0.5 + x, 0, 0.5, 0)
	self.card.Size = UDim2.new(0, 0, 0, 0)
	self.card.Image = "rbxassetid://5733228080"
	self.card.ImageRectOffset = Vector2.new(sheet_l + sheet_ix * sx, sheet_t + sheet_iy * sy)
	self.card.ImageRectSize = Vector2.new(sheet_w, sheet_h)
	self.card.Parent = gui
	
	return self
end

function item_card:Destroy()
	--Destroy card
	self.card:Destroy()
end

--Ring flash interface
function item_card:Update(dt, shift_x)
	--Increment item card time
	self.card_t += dt
	if self.card_t >= self.card_len then
		return true
	end
	
	--Get next card size
	local dia
	if self.card_t < self.card_intrans then
		dia = self.card_t / self.card_intrans
	elseif self.card_t > (self.card_len - self.card_outtrans) then
		dia = (self.card_len - self.card_t) / self.card_outtrans
	else
		dia = 1
	end
	dia = math.sin(dia * math.rad(90)) * 0.95
	
	--Move card
	self.card.Position = UDim2.new(0.5 + self.x + shift_x, 0, 0.5, 0)
	self.card.Size = UDim2.new(dia, 0, dia, 0)
	return false
end

function item_card:GetX()
	return self.card.Position.X.Scale - 0.5
end

function item_card:ShiftLeft()
	self.x -= 0.5
end

function item_card:ShiftRight()
	self.x += 0.5
end

return item_card