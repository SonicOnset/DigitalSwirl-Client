--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Object/ItemBox.lua
Purpose: Item Box object
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local item_box = {}

local object_common = require(script.Parent.Parent:WaitForChild("ObjectCommon"))

local assets = script.Parent.Parent:WaitForChild("Assets")
local obj_assets = assets:WaitForChild("ItemBox")

--Object functions
local function Draw(self, dt)
	--Destroy particle once lifetime is over
	if self.touch_particle ~= nil then
		self.touch_particle_life -= dt
		if self.touch_particle_life <= 0 then
			self.touch_particle:Destroy()
			self.touch_particle = nil
			self.draw = nil
		end
	end
end

--Object contact
local function TouchPlayer(self, player)
	if player.v3 then
		return
	end
	
	if not self.opened then
		if player:BallActive() or not (player.flag.grounded and self.grounded) then
			--Bounce player
			if not player.flag.grounded then
				player:ObjectBounce()
			end
			
			--Open item box
			self.homing_target = false
			self.opened = true
			
			--Hide item box and destroy animation
			for _,v in pairs(self.hide) do
				v.LocalTransparencyModifier = 1
			end
			if self.anim ~= nil then
				self.anim:Destroy()
				self.anim = nil
			end
			
			--Emit particles and play sound
			if self.touch_particle ~= nil then
				self.touch_particle:Emit(20)
			end
			self.touch_sound:Play()
			
			--Change object state
			self.draw = Draw
			
			--Give player item and score
			player:GiveItem(self.contents)
			player:GiveScore(200)
		else
			--Push out of item box
			object_common.PushPlayerCylinder(self.root, player, 0.375)
		end
	elseif self.grounded then
		--Push out of item box if in lower half
		local loc_pos = self.root.CFrame:inverse() * player.pos
		if loc_pos.Y < 0 then
			object_common.PushPlayerCylinder(self.root, player, 0.25)
		end
	end
end

--Constructor and destructor
function item_box:New(object)
	--Initialize meta reference
	local self = setmetatable({}, {__index = item_box})
	
	--Use object information
	self.object = object
	self.root = object.PrimaryPart
	if object:FindFirstChild("Ground") then
		self.grounded = object.Ground.Value
	else
		self.grounded = false
	end
	self.contents = object:WaitForChild("Contents").Value
	self.anim_controller = object:WaitForChild("AnimationController")
	
	--Create touch sound and particle
	self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
	self.touch_sound.Parent = self.root
	self.particle_attachment = Instance.new("Attachment", self.root)
	self.touch_particle = obj_assets:WaitForChild("TouchParticle"):clone()
	self.touch_particle.Parent = self.particle_attachment
	self.touch_particle_life = self.touch_particle.Lifetime.Max
	
	--Create and play animation
	self.anim = self.anim_controller:LoadAnimation(obj_assets:WaitForChild("Anim"))
	self.anim:Play()
	
	--Get parts that should be hidden when box is opened
	self.hide = {
		object:WaitForChild("ItemBox"),
		object.ItemBox:WaitForChild("Ext"),
	}
	
	--Setup contents textures
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
	local contents_coord = (sheet_coord[self.contents] or Vector2.new(0, 0)) * 2.34
	
	for _,v in pairs(object:WaitForChild("Content"):GetChildren()) do
		if v:IsA("Texture") then
			v.OffsetStudsU = contents_coord.X
			v.OffsetStudsV = contents_coord.Y
			table.insert(self.hide, v)
		end
	end
	
	--Attach functions
	self.touch_player = TouchPlayer
	
	--Set other specifications
	self.homing_target = true
	
	--Set state
	self.opened = false
	
	return self
end

function item_box:Destroy()
	--Restore hidden parts if opened
	if self.opened then
		for _,v in pairs(self.hide) do
			v.LocalTransparencyModifier = 0
		end
	end
	
	--Destroy animation
	if self.anim ~= nil then
		self.anim:Destroy()
		self.anim = nil
	end
	
	--Destroy sound and particle
	if self.touch_sound ~= nil then
		self.touch_sound:Destroy()
		self.touch_sound = nil
	end
	if self.particle_attachment ~= nil then
		self.particle_attachment:Destroy()
		self.particle_attachment = nil
	end
end

return item_box