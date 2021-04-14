--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Hud.lua
Purpose: Heads Up Display
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local hud_class = {}

local assets = script.Parent:WaitForChild("Assets")
local guis = assets:WaitForChild("Guis")

local text = require(script:WaitForChild("Text"))
local ring_flash = require(script:WaitForChild("RingFlash"))
local item_card = require(script:WaitForChild("ItemCard"))

--Constructor and destructor
function hud_class:New(parent_gui)
	--Initialize meta reference
	local self = setmetatable({}, {__index = hud_class})
	
	--Create new Hud Gui
	self.gui = guis:WaitForChild("HudGui"):Clone()
	self.gui.Parent = parent_gui
	
	self.hud_left = self.gui:WaitForChild("Left")
	self.hud_frame = self.hud_left:WaitForChild("HudFrame")
	
	self.lives_frame = self.hud_frame:WaitForChild("LivesFrame")
	self.portrait_image = self.lives_frame:WaitForChild("Portrait")
	
	self.ring_icon = self.hud_frame:WaitForChild("RingIcon")
	
	--Create text objects
	self.score_text = text:New(self.hud_frame, UDim2.new(0.96, 0, 0.325, 0))
	--self.score_text:SetText('000000000')
	self.time_text = text:New(self.hud_frame, UDim2.new(0.8, 0, 0.66, 0))
	--self.time_text:SetText('00:00"00')
	self.ring_text = text:New(self.hud_frame, UDim2.new(0.525, 0, 0.995, 0))
	--self.ring_text:SetText('000')
	
	--Create item card frame
	self.item_card_frame = Instance.new("Frame")
	self.item_card_frame.BackgroundTransparency = 1
	self.item_card_frame.BorderSizePixel = 0
	self.item_card_frame.AnchorPoint = Vector2.new(0.5, 1)
	self.item_card_frame.Position = UDim2.new(0.5, 0, 0.9, 0)
	self.item_card_frame.Size = UDim2.new(0.2, 0, 0.2, 0)
	self.item_card_frame.SizeConstraint = Enum.SizeConstraint.RelativeYY
	self.item_card_frame.Parent = self.gui
	
	--Initialize Hud state
	self.ring_flashes = {}
	self.ring_blink = 0
	self.ring_blinkt = 0
	
	self.item_cards = {}
	self.item_card_x = 0
	self.item_card_shift = 0
	
	self.portrait = nil
	self.hurt_shake = 0
	
	return self
end

function hud_class:Destroy()
	--Destroy ring flashes
	if self.ring_flashes ~= nil then
		for _,v in pairs(self.ring_flashes) do
			v:Destroy()
		end
		self.ring_flashes = nil
	end
	
	--Destroy text objects
	if self.ring_text ~= nil then
		self.ring_text:Destroy()
		self.ring_text = nil
	end
	if self.time_text ~= nil then
		self.time_text:Destroy()
		self.time_text = nil
	end
	if self.score_text ~= nil then
		self.score_text:Destroy()
		self.score_text = nil
	end
	
	--Destroy Hud Gui
	if self.gui ~= nil then
		self.gui:Destroy()
	end
end

--Hud interface
local function ZeroPad(str, length)
	return string.rep("0", length - str:len())..str
end

function hud_class:UpdateDisplay(dt, player)
	debug.profilebegin("hud_class:UpdateDisplay")
	
	--Update ring flashes
	for i, v in pairs(self.ring_flashes) do
		if v:Update(dt) then
			--Destroy ring flashes
			v:Destroy()
			self.ring_flashes[i] = nil
		end
	end
	
	--Update item cards
	local reset = true
	for i, v in pairs(self.item_cards) do
		if v:Update(dt, self.item_card_shift) then
			--Destroy item card
			v:Destroy()
			self.item_cards[i] = nil
			
			--Shift item cards left
			for _,j in pairs(self.item_cards) do
				j:ShiftLeft()
			end
			self.item_card_shift += 0.5
			self.item_card_x -= 0.5
		else
			reset = false
		end
	end
	
	if reset then
		self.item_card_x = 0
		self.item_card_shift = 0
	else
		self.item_card_shift *= 0.9
	end
	
	--Update Hud display
	--Hud
	if player.score ~= self.score then
		--Update score display
		self.score_text:SetText(ZeroPad(tostring(player.score), 9))
		self.score = player.score
	end
	
	--Time
	if player.time ~= self.time then
		--Get text to display
		local millis = ZeroPad(tostring(math.floor((player.time % 1) * 100)), 2)
		local seconds = ZeroPad(tostring(math.floor(player.time % 60)), 2)
		local minutes = ZeroPad(tostring(math.floor(player.time / 60)), 2)
		
		--Update time display
		self.time_text:SetText(minutes..':'..seconds..'"'..millis)
		self.time = player.time
	end
	
	--Rings
	if player.rings ~= self.rings then
		--If rings increased, create a ring flash
		if self.rings ~= nil and player.rings > self.rings then
			table.insert(self.ring_flashes, ring_flash:New(self.ring_icon))
		end
		
		--Update ring display
		self.ring_text:SetText(ZeroPad(tostring(player.rings), 3))
		self.rings = player.rings
	end
	
	--Item cards
	local sheet_coord = {
		["5Rings"] =        Vector2.new(0, 0),
		["10Rings"] =       Vector2.new(1, 0),
		["20Rings"] =       Vector2.new(2, 0),
		["1Up"] =           Vector2.new(0, 1),
		["Invincibility"] = Vector2.new(1, 1),
		["SpeedShoes"] =    Vector2.new(5, 0),
		["Shield"] =        Vector2.new(3, 0),
		["MagnetShield"] =  Vector2.new(4, 0),
	}
	
	if #player.item_cards > 0 then
		--If the player wants to display new item cards, create them
		for _,v in pairs(player.item_cards) do
			--Shift cards left
			for _,j in pairs(self.item_cards) do
				j:ShiftLeft()
			end
			for _,_ in pairs(self.item_cards) do
				self.item_card_shift += 0.5
				break
			end
			
			--Insert new card
			local contents_coord = (sheet_coord[v] or Vector2.new(0, 0))
			table.insert(self.item_cards, item_card:New(self.item_card_frame, self.item_card_x, contents_coord.X, contents_coord.Y))
			self.item_card_x += 0.5
		end
		player.item_cards = {}
	end
	
	--Blink ring counter
	if self.rings == 0 then
		self.ring_blinkt += dt
		self.ring_blink = 1 - (math.cos(self.ring_blinkt * 3) / 2 + 0.5)
	else
		self.ring_blink *= (0.9 ^ 60) ^ dt
		self.ring_blinkt = 0
	end
	self.ring_text:SetColour(Color3.new(1, 1, 1):Lerp(Color3.new(1, 0, 0), self.ring_blink))
	
	--Update portrait
	if player.portrait ~= self.portrait then
		--Update portrait display
		local portrait = player.portraits[player.portrait]
		self.portrait_image.Image = portrait.image
		self.portrait_image.Position = portrait.pos
		self.portrait_image.Size = portrait.size
		self.portrait = player.portrait
		
		--Shake display
		if player.portrait == "Hurt" then
			self.hurt_shake = 0.25
		end
	end
	
	--Shake HUD
	if self.hurt_shake > 0 then
		self.hurt_shake -= dt
		if self.hurt_shake < 0 then
			self.hud_left.Position = UDim2.new(0, 0, 0, 0)
		else
			self.hud_left.Position = UDim2.new(math.cos(self.hurt_shake * 50) * 0.003, 0, math.sin(self.hurt_shake * 32) * 0.003, 0)
		end
	end
	
	debug.profileend()
end

return hud_class