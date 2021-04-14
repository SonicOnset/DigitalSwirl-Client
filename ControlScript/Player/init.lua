--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player.lua
Purpose: Player class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player = {}

local assets = script.Parent:WaitForChild("Assets")
local global_sounds = assets:WaitForChild("Sounds")
local obj_assets = assets:WaitForChild("Objects")

local spilled_ring = obj_assets:WaitForChild("SpilledRing")

local speed_shoes_theme = global_sounds:WaitForChild("SpeedShoes")
local speed_shoes_theme_id = string.sub(speed_shoes_theme.SoundId, 14)
local speed_shoes_theme_volume = speed_shoes_theme.Volume

local invincibility_theme = global_sounds:WaitForChild("Invincibility")
local invincibility_theme_id = string.sub(invincibility_theme.SoundId, 14)
local invincibility_theme_volume = invincibility_theme.Volume

local extra_life_jingle = global_sounds:WaitForChild("ExtraLife")

local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")
local shared_assets = replicated_storage:WaitForChild("Assets")

local switch = require(common_modules:WaitForChild("Switch"))
local vector = require(common_modules:WaitForChild("Vector"))
local cframe = require(common_modules:WaitForChild("CFrame"))
local common_collision = require(common_modules:WaitForChild("Collision"))
local global_reference = require(common_modules:WaitForChild("GlobalReference"))

local player_draw = require(script.Parent:WaitForChild("PlayerDraw"))

local constants = require(script.Parent:WaitForChild("Constants"))
local input = require(script:WaitForChild("Input"))
local acceleration = require(script:WaitForChild("Acceleration"))
local movement = require(script:WaitForChild("Movement"))
local collision = require(script:WaitForChild("Collision"))
local rail = require(script:WaitForChild("Rail"))
local homing_attack = require(script:WaitForChild("HomingAttack"))
local lsd = require(script:WaitForChild("LSD"))
local ragdoll = require(script:WaitForChild("Ragdoll"))
local animation = require(script:WaitForChild("Animation"))
local sound = require(script:WaitForChild("Sound"))

local object_reference = global_reference:New(workspace, "Level/Objects")

local characters = shared_assets:WaitForChild("Characters")

--Common functions
local function lerp(x, y, z)
	return x + (y - x) * z
end

--Constructor and destructor
function player:New(character, cframe)
	--Initialize meta reference
	local self = setmetatable({}, {__index = player})
	
	--Initialize character
	self.player_draw = player_draw:New(character, game:GetService("Players").LocalPlayer.Name)
	self.character = self.player_draw.character
	self.character_id = character
	
	--Get character's info
	local info
	if character ~= nil then
		info = require(self.character:WaitForChild("CharacterInfo"))
	else
		error("Player can't be created without character")
		return nil
	end
	
	--Use character's info
	self.p = info.param
	self.assets = info.assets
	self.animations = info.animations
	self.portraits = info.portraits
	
	--Find common character references
	self.anim_controller = self.character:WaitForChild("AnimationController")
	self.hrp = self.character:WaitForChild("HumanoidRootPart")
	
	--Load animations and sounds
	sound.LoadSounds(self)
	animation.LoadAnimations(self)
	
	--Use character's position and angle
	self.pos = cframe.p
	self.ang = self:AngleFromRbx(cframe - cframe.p)
	self.vis_ang = self.ang
	
	--Initialize player state
	self.state = "Idle"
	self.spd = Vector3.new()
	self.gspd = Vector3.new()
	self.flag = {
		grounded = true,
	}
	
	--Power-up state
	self.shield = nil
	self.speed_shoes_time = 0
	self.invincibility_time = 0
	
	self.invulnerability_time = 0
	
	--Meme state
	self.v3 = false
	
	--Physics state
	self.gravity = Vector3.new(0, -1, 0)
	
	--Collision state
	self.floor_normal = Vector3.new(0, 1, 0)
	self.dotp = 1
	
	self.floor = nil
	self.floor_off = CFrame.new()
	self.floor_last = nil
	self.floor_move = nil
	
	--Movement state
	self.frict_mult = 1
	
	self.jump_timer = 0
	self.spring_timer = 0
	self.dashpanel_timer = 0
	self.dashring_timer = 0
	self.rail_debounce = 0
	
	self.rail_trick = 0
	
	self.spindash_speed = 0
	
	self.jump_action = nil
	self.roll_action = nil
	self.secondary_action = nil
	self.tertiary_action = nil
	
	--Animation state
	self.animation = nil
	self.prev_animation = nil
	self.reset_anim = false
	self.anim_speed = 0
	
	--Game state
	self.score = 0
	self.time = 0
	self.rings = 0
	
	self.item_cards = {}
	
	self.portrait = "Idle"
	
	--Initialize sub-systems
	input.Initialize(self)
	rail.Initialize(self)
	
	--Effects
	--self.speed_trail = self.hrp:WaitForChild("SpeedTrail")
	self.rail_speed_trail = self.hrp:WaitForChild("RailSpeedTrail")
	self.air_kick_trails = {
		self.hrp:WaitForChild("KickBeam1"),
		self.hrp:WaitForChild("KickBeam2"),
	}
	
	local bottom = self.hrp:WaitForChild("Bottom")
	self.skid_effect = bottom:WaitForChild("Skid")
	self.rail_sparks = bottom:WaitForChild("Sparks")
	
	--Get level music id and volume
	local music_id = workspace:WaitForChild("Level"):WaitForChild("MusicId")
	local music_volume = workspace:WaitForChild("Level"):WaitForChild("MusicVolume")
	
	self.level_music_id = music_id.Value
	self.level_music_volume = music_volume.Value
	
	self.level_music_id_conn = music_id:GetPropertyChangedSignal("Value"):Connect(function()
		self.level_music_id = music_id.Value
	end)
	self.level_music_volume_conn = music_volume:GetPropertyChangedSignal("Value"):Connect(function()
		self.level_music_volume = music_volume.Value
	end)
	
	--Music state
	self.music_id = self.level_music_id
	self.music_volume = self.level_music_volume
	self.music_reset = false
	
	workspace.CurrentCamera.CameraSubject = self.hrp
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	
	return self
end

function player:Destroy()
	--Disconnect level music events
	if self.level_music_id_conn ~= nil then
		self.level_music_id_conn:Disconnect()
		self.level_music_id_conn = nil
	end
	if self.level_music_volume_conn ~= nil then
		self.level_music_volume_conn:Disconnect()
		self.level_music_volume_conn = nil
	end
	
	--Quit sub-systems
	input.Quit(self)
	rail.Quit(self)
	
	--Destroy player draw
	if self.player_draw ~= nil then
		self.player_draw:Destroy()
		self.player_draw = nil
	end
	
	--Unload animations and sounds
	animation.UnloadAnimations(self)
	sound.UnloadSounds(self)
end

--Physics setter
local phys_dump_map = {
	"jump2_timer",
	"pos_error",
	"lim_h_spd",
	"lim_v_spd",
	"max_x_spd",
	"max_psh_spd",
	"jmp_y_spd",
	"nocon_speed",
	"slide_speed",
	"jog_speed",
	"run_speed",
	"rush_speed",
	"crash_speed",
	"dash_speed",
	"jmp_addit",
	"run_accel",
	"air_accel",
	"slow_down",
	"run_break",
	"air_break",
	"air_resist_air",
	"air_resist",
	"air_resist_y",
	"air_resist_z",
	"grd_frict",
	"grd_frict_z",
	"lim_frict",
	"rat_bound",
	"rad",
	"height",
	"weight",
	"eyes_height",
	"center_height",
}

local physics = script:WaitForChild("Physics")

function player:SetPhysics(game, char)
	local game_mod = physics:FindFirstChild(game)
	if game_mod ~= nil and game_mod:IsA("ModuleScript") then
		local game_pack = require(game_mod)
		local char_phys = game_pack[char]
		
		if char_phys ~= nil then
			for i, v in pairs(char_phys) do
				local map = phys_dump_map[i]
				self.p[map] = v
			end
			self.p.height /= 2
		end
	end
end

--Player space conversion
function player:ToGlobal(vec)
	return self.ang * vec
end

function player:ToLocal(vec)
	return self.ang:inverse() * vec
end

function player:GetLook()
	return self.ang.RightVector
end

function player:GetRight()
	return -self.ang.LookVector
end

function player:GetUp()
	return self.ang.UpVector
end

function player:AngleFromRbx(ang)
	return ang * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.pi / 2)
end

function player:AngleToRbx(ang)
	return ang * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.pi / -2)
end

function player:ToWorldCFrame()
	return self:AngleToRbx(self.ang) + self.pos
end

function player:PosToSpd(vec)
	return Vector3.new(-vec.Z, vec.Y, vec.X)
end

function player:SpdToPos(vec)
	return Vector3.new(vec.Z, vec.Y, -vec.X)
end

--Player collision functions
function player:GetMiddle()
	return self.pos + (self:GetUp() * (self.p.height * self.p.scale))
end

function player:GetSphereRadius()
	return ((self.p.height + self.p.rad) / 2) * self.p.scale
end

function player:GetSphere()
	return {
		center = self:GetMiddle(),
		radius = self:GetSphereRadius()
	}
end

function player:GetRegion()
	local mid = self:GetMiddle()
	local rad = self:GetSphereRadius()
	return Region3.new(
		mid - Vector3.new(rad, rad, rad),
		mid + Vector3.new(rad, rad, rad)
	)
end

--Player state functions
function player:IsBlinking()
	return self.invulnerability_time > 0 and self.state ~= "Hurt" and self.state ~= "Dead"
end

function player:Damage(hurt_origin)
	--Do not take damage if invulnerable to damage
	if self.invulnerability_time > 0 or self.invincibility_time > 0 then
		return false
	end
	
	--Set state
	self:ResetObjectState()
	self:ExitBall()
	self.hurt_time = 1.5 * constants.framerate
	self.invulnerability_time = 2.75 * constants.framerate
	self.state = "Hurt"
	self.flag.grounded = false
	
	--Play hurt animation
	if math.abs(self.spd.X) >= self.p.dash_speed then
		self.animation = "Hurt2"
	else
		self.animation = "Hurt1"
	end
	
	--Set speed and rotation
	local diff = vector.PlaneProject(((hurt_origin ~= nil) and (hurt_origin - self:GetMiddle()) or (self:GetLook())), -self.gravity.unit)
	
	if diff.magnitude ~= 0 then
		local factor = math.abs(self:ToGlobal(self.spd):Dot(diff.unit)) / 5
		self:SetAngle(cframe.FromToRotation(self:GetLook(), diff.unit) * self.ang)
		self.spd = self:ToLocal((diff.unit * -1.125 * (1 + factor)) + (-self.gravity.unit * 1.675 * (1 + factor / 4)))
	else
		self.spd = self:ToLocal(-self.gravity.unit * 2.125)
	end
	
	--Damage
	if self.shield ~= nil then
		--Lose shield
		self.shield = nil
	else
		if self.rings > 0 then
			--Prepare to spill rings
			local lose_rings = math.min(self.rings, 20)
			local objects = object_reference:Get()
			local look = self:GetLook()
			local look_ang = math.atan2(look.X, look.Z)
			
			sound.PlaySound(self, "RingLoss")
			
			if lose_rings > 0 then
				--Spill first 10 rings in a taller arc
				local circle_rings = math.min(lose_rings, 10)
				local ang_inc = math.pi * 2 / circle_rings
				local ang = look_ang
				
				for i = 1, circle_rings do
					--Spill ring
					local ring = spilled_ring:Clone()
					ring:SetPrimaryPartCFrame(CFrame.new(self:GetMiddle()))
					ring.PrimaryPart.Velocity = Vector3.new(-math.sin(ang) * 30, 90, -math.cos(ang) * 30)
					ring.Parent = objects
					
					--Increment angle
					ang += ang_inc
				end
			end
			
			if lose_rings > 10 then
				--Spill second 10 rings in a shorter arc
				local circle_rings = math.min(lose_rings - 10, 10)
				local ang_inc = math.pi * 2 / circle_rings
				local ang = look_ang
				
				for i = 1, circle_rings do
					--Spill ring
					local ring = spilled_ring:Clone()
					ring:SetPrimaryPartCFrame(CFrame.new(self:GetMiddle()))
					ring.PrimaryPart.Velocity = Vector3.new(-math.sin(ang) * 45, 60, -math.cos(ang) * 45)
					ring.Parent = objects
					
					--Increment angle
					ang += ang_inc
				end
			end
			
			--Lose rings
			self.rings = math.max(self.rings - 150, 0)
		else
			--TODO: die
		end
	end
	
	return true
end

function player:ResetObjectState()
	self.flag.scripted_spring = false
	self.spring_timer = 0
	self.dashpanel_timer = 0
	self.dashring_timer = 0
	self.rail_trick = 0
	rail.SetRail(self, nil)
end

function player:EnterBall()
	self.flag.ball_aura = true
end

function player:ExitBall()
	sound.StopSound(self, "SpindashCharge")
	self.flag.air_kick = false
	self.flag.ball_aura = false
	self.flag.dash_aura = false
end

function player:Land()
	self:ExitBall()
	self.flag.bounce2 = false
end

function player:TrailActive()
	if self.flag.grounded then
		return self.flag.ball_aura and self.state ~= "Spindash"
	else
		return self.flag.dash_aura or self.state == "Homing" or self.state == "Bounce"
	end
end

function player:BallActive()
	return self.flag.ball_aura or self.state == "AirKick"
end

function player:ObjectBounce()
	--Enter airborne state
	if self.state == "Homing" or self.state == "AirKick" then
		self.flag.air_kick = true
	end
	if self:BallActive() then
		self:EnterBall()
		self.animation = "Roll"
		self.flag.dash_aura = false
	end
	self.state = "Airborne"
	self.flag.grounded = false
	
	--Set speed
	self.spd = Vector3.new(0, 3, 0)
	self.anim_speed = self.spd.magnitude
end

function player:UseFloorMove()
	if self.floor_move ~= nil then
		self.spd += self:ToLocal(self.floor_move) / self.p.scale
		self.floor_move = nil
	end
end

function player:Scripted()
	return (self.flag.grounded and (false) or (self.spring_timer > 0 or self.dashring_timer > 0))
end

--Physics functions
function player:GetWeight()
	return self.p.weight * (self.flag.underwater and 0.45 or 1)
end

function player:GetAirResistY()
	return self.p.air_resist_y * (self.flag.underwater and 1.5 or 1)
end

function player:GetMaxXSpeed()
	return self.p.max_x_spd * ((self.speed_shoes_time > 0) and 2 or 1)
end

function player:GetRunAccel()
	return self.p.run_accel * (self.underwater and 0.65 or 1) * ((self.speed_shoes_time > 0) and 2 or 1)
end

--Game functions
function player:GiveScore(score)
	--Give score
	self.score += score
end

function player:GiveRings(rings)
	--Give ring and score bonus
	self.rings += rings
end

function player:GiveItem(item)
	--Handle item
	switch(item, {}, {
		["5Rings"] = function()
			self:GiveScore(10 * 5)
			self:GiveRings(5)
		end,
		["10Rings"] = function()
			self:GiveScore(10 * 10)
			self:GiveRings(10)
		end,
		["20Rings"] = function()
			self:GiveScore(10 * 20)
			self:GiveRings(20)
		end,
		["1Up"] = function()
			extra_life_jingle:Play()
		end,
		["Invincibility"] = function()
			self.invincibility_time = 20 * constants.framerate
			self.music_id = invincibility_theme_id
			self.music_volume = invincibility_theme_volume
			self.music_reset = true
		end,
		["SpeedShoes"] = function()
			self.speed_shoes_time = 15 * constants.framerate
			self.music_id = speed_shoes_theme_id
			self.music_volume = speed_shoes_theme_volume
			self.music_reset = true
		end,
		["Shield"] = function()
			self.shield = "Shield"
		end,
		["MagnetShield"] = function()
			self.shield = "MagnetShield"
		end,
	})
	
	--Process item for hud item cards
	table.insert(self.item_cards, item)
end

--Other player global functions
function player:SetAngle(ang)
	if self.flag.grounded and not self.v3 then
		--Set angle
		self.ang = ang
	else
		--Set angle, maintaining middle
		self.pos += self:GetUp() * self.p.height * self.p.scale
		self.ang = ang
		self.pos -= self:GetUp() * self.p.height * self.p.scale
	end
	
	--Set other angle information
	self.dotp = -self:GetUp():Dot(self.gravity.unit)
	self.floor_normal = self:GetUp()
end

--Player turn functions
function player:Turn(turn)
	if self.v3 and self.dotp < 0.95 then
		local fac = math.min(math.abs(self.spd.X) / self.p.max_x_spd, 1)
		turn *= fac
	end
	self.ang *= CFrame.fromAxisAngle(Vector3.new(0, 1, 0), turn)
	return turn
end

function player:AdjustAngleY(turn)
	--Get analogue state
	local has_control,_,_ = input.GetAnalogue(self)
	
	--Remember previous global speed
	local prev_spd = self:ToGlobal(self.spd)
	
	--Get max turn
	local max_turn = math.abs(turn)
	
	if max_turn <= math.rad(45) then
		if max_turn <= math.rad(22.5) then
			max_turn /= 8
		else
			max_turn /= 4
		end
	else
		max_turn = math.rad(11.25)
	end
	
	--Turn
	if not self.v3 then
		turn = math.clamp(turn, -max_turn, max_turn)
	end
	turn = self:Turn(turn)
	
	--Handle inertia
	if self.v3 ~= true then
		if not self.flag.grounded then
			--10% inertia
			self.spd = self.spd * 0.9 + self:ToLocal(prev_spd) * 0.1
		else
			local inertia
			if has_control then
				if self.dotp <= 0.4 then
					inertia = 0.5
				else
					inertia = 0.01
				end
			else
				inertia = 0.95
			end
			
			if self.frict_mult < 1 then
				inertia *= self.frict_mult
			end
			
			self.spd = self.spd * (1 - inertia) + self:ToLocal(prev_spd) * inertia
		end
	end
	
	return turn
end

function player:AdjustAngleYQ(turn)
	--Turn with full inertia
	local prev_spd = self:ToGlobal(self.spd)
	
	if not self.v3 then
		turn = math.clamp(turn, math.rad(-45), math.rad(45))
	end
	turn = self:Turn(turn)
	
	if self.v3 ~= true then
		self.spd = self:ToLocal(prev_spd)
	end
	
	return turn
end

function player:AdjustAngleYS(turn)
	--Remember previous global speed
	local prev_spd = self:ToGlobal(self.spd)
	
	--Get max turn
	local max_turn = math.rad(1.40625)
	if self.spd.X > self.p.dash_speed then
		max_turn = math.max(max_turn - (math.sqrt(((self.spd.X - self.p.dash_speed) * 0.0625)) * max_turn), 0)
	end
	
	--Turn
	if not self.v3 then
		turn = math.clamp(turn, -max_turn, max_turn)
	end
	turn = self:Turn(turn)
	
	--Handle inertia
	if self.v3 ~= true then
		local inertia
		if self.dotp <= 0.4 then
			inertia = 0.5
		else
			inertia = 0.01
		end
		
		self.spd = self.spd * (1 - inertia) + self:ToLocal(prev_spd) * inertia
	end
	
	return turn
end

--Moves
local function GetWalkState(self)
	if math.abs(self.spd.X) > 0.01 then
		return "Walk"
	else
		return "Idle"
	end
end

local function CheckJump(self)
	--Check for jumping
	self.jump_action = "Jump"
	if self.input.button_press.jump then
		--Enter jump state
		if self.dotp > 0.9 or not self.v3 then
			self.spd = vector.SetY(self.spd, self.p.jmp_y_spd)
		end
		self:UseFloorMove()
		self.jump_timer = self.p.jump2_timer
		self.flag.grounded = false
		
		rail.SetRail(self, nil)
		
		self.state = "Airborne"
		self:EnterBall()
		
		--Play jump animation and sound
		self.animation = "Roll"
		self.anim_speed = self.spd.X
		sound.PlaySound(self, "Jump")
		return true
	end
	return false
end

local function CheckSpindash(self)
	--Check for spindashing
	self.roll_action = "Spindash"
	if self.input.button_press.roll then
		--Start spindashing
		self.state = "Spindash"
		self:EnterBall()
		self.spindash_speed = math.max(self.spd.X, 2)
		sound.PlaySound(self, "SpindashCharge")
		return true
	end
	return false
end

local function CheckUncurl(self)
	--Check for uncurling
	self.roll_action = "Roll"
	if self.input.button_press.roll and not self.flag.ceiling_clip then
		--Uncurl
		self.state = "Walk"
		self:ExitBall()
		return true
	end
	return false
end

local function CheckLightSpeedDash(self, object_instance)
	--Check for light speed dash
	self.secondary_action = "LightSpeedDash"
	if self.input.button_press.secondary_action and lsd.CheckStartLSD(self, object_instance) then
		--Start light speed dash
		self.animation = "LSD"
		self.state = "LightSpeedDash"
		self:ExitBall()
		self:ResetObjectState()
		return true
	end
	return false
end

local function CheckHomingAttack(self, object_instance)
	--Check for homing attack
	if self.flag.ball_aura then
		self.jump_action = "HomingAttack"
		if self.input.button_press.jump then
			if homing_attack.CheckStartHoming(self, object_instance) then
				--Homing attack
				self.animation = "Roll"
				self:EnterBall()
			else
				--Jump dash
				self.spd = vector.SetX(self.spd, 5)
				self.animation = "Fall"
				self:ExitBall()
				self.flag.dash_aura = true
				sound.PlaySound(self, "Dash")
			end
			
			--Enter homing attack state
			self.state = "Homing"
			self.homing_timer = 0
			sound.PlaySound(self, "Dash")
			return true
		end
	end
	return false
end

local function CheckBounce(self)
	--Check for bounce
	if self.flag.ball_aura then
		self.roll_action = "Bounce"
		if self.input.button_press.roll then
			--Bounce
			self.state = "Bounce"
			self.animation = "Roll"
			self.spd = vector.MulX(self.spd, 0.75)
			if self.flag.bounce2 == true then
				self.spd = vector.SetY(self.spd, -7)
			else
				self.spd = vector.SetY(self.spd, -5)
			end
			self.anim_speed = -self.spd.Y
			return true
		end
	end
	return false
end

local function CheckAirKick(self)
	--Check for air kick
	if self.flag.air_kick then
		self.tertiary_action = "AirKick"
		if self.input.button_press.tertiary_action then
			--Air kick
			self:GiveScore(200)
			self.state = "AirKick"
			self:ExitBall()
			if input.GetAnalogue_Mag(self) <= 0 then
				self.animation = "AirKickUp"
				self.spd = Vector3.new(0.2, 2.65, 0)
				self.air_kick_timer = 60
			else
				self.animation = "AirKick"
				self.spd = Vector3.new(4.5, 1.425, 0)
				self.air_kick_timer = 120
			end
			return true
		end
	end
	return false
end

local function CheckSkid(self)
	local has_control, analogue_turn, _ = input.GetAnalogue(self)
	if has_control then
		return math.abs(analogue_turn) > math.rad(135)
	end
	return false
end

local function CheckStopSkid(self)
	if self.spd.X <= 0.01 then
		--We've stopped, stop skidding
		self.spd = vector.SetX(self.spd, 0)
		return true
	else
		--If holding forward, stop skidding
		local has_control, analogue_turn, _ = input.GetAnalogue(self)
		if has_control then
			return math.abs(analogue_turn) <= math.rad(135)
		end
		return false
	end
end

local function CheckStartWalk(self)
	local has_control, _, _ = input.GetAnalogue(self)
	if has_control or math.abs(self.spd.X) > self.p.slide_speed then
		self.state = "Walk"
		return true
	end
	return false
end

local function CheckStopWalk(self)
	local has_control, _, _ = input.GetAnalogue(self)
	if has_control or math.abs(self.spd.X) > 0.01 then
		return false
	end
	
	self.state = "Idle"
	return true
end

local function CheckMoves(self, object_instance)
	if self.do_ragdoll then
		self.state = "Ragdoll"
		self.do_ragdoll = false
		return true
	end
	
	return switch(self.state, {}, {
		["Idle"] = function()
			return CheckLightSpeedDash(self, object_instance) or CheckJump(self) or CheckSpindash(self) or CheckStartWalk(self)
		end,
		["Walk"] = function()
			if CheckLightSpeedDash(self, object_instance) or CheckJump(self) or CheckSpindash(self) or CheckStopWalk(self) then
				return true
			else
				--Check if we should start skidding
				if self.spd.X > self.p.jog_speed and CheckSkid(self) then
					--Start skidding
					self.state = "Skid"
					sound.PlaySound(self, "Skid")
					return true
				end
			end
			return false
		end,
		["Skid"] = function()
			if CheckLightSpeedDash(self, object_instance) or CheckJump(self) or CheckSpindash(self) then
				return true
			else
				--Check if we should stop skidding
				if CheckStopSkid(self) then
					--Stop skidding
					self.state = GetWalkState(self)
					return true
				end
			end
			return false
		end,
		["Roll"] = function()
			if CheckLightSpeedDash(self, object_instance) or CheckJump(self) or CheckUncurl(self) then
				return true
			else
				if self.spd.X < self.p.run_speed then
					if self.flag.ceiling_clip then
						--Force us to keep rolling
						self.spd = vector.SetX(self.spd, self.p.run_speed)
					else
						--Uncurl if moving too slow
						self.state = GetWalkState(self)
						self:ExitBall()
						return true
					end
				end
			end
			return false
		end,
		["Spindash"] = function()
			if CheckLightSpeedDash(self, object_instance) then
				return true
			else
				self.roll_action = "Spindash"
				if self.input.button.roll then
					--Increase spindash speed
					if self.spindash_speed < 10 or self.v3 == true then
						self.spindash_speed += ((self.v3 == true) and 0.1 or 0.4)
					end
				else
					--Release spindash
					self.state = "Roll"
					self:EnterBall()
					self.spd = vector.SetX(self.spd, self.spindash_speed)
					sound.StopSound(self, "SpindashCharge")
					sound.PlaySound(self, "SpindashRelease")
					return true
				end
			end
			return false
		end,
		["Airborne"] = function()
			return CheckLightSpeedDash(self, object_instance) or CheckHomingAttack(self, object_instance) or CheckBounce(self) or CheckAirKick(self)
		end,
		["Homing"] = function()
			if self.homing_obj == nil then
				if CheckLightSpeedDash(self, object_instance) then
					return true
				end
			else
				self.jump_action = "Jump"
			end
			return false
		end,
		["Bounce"] = function()
			self.roll_action = "Bounce"
			return CheckLightSpeedDash(self, object_instance) or CheckHomingAttack(self, object_instance)
		end,
		["LightSpeedDash"] = function()
			self.secondary_action = "LightSpeedDash"
			return false
		end,
		["AirKick"] = function()
			return CheckLightSpeedDash(self, object_instance)
		end,
		["Rail"] = function()
			self.jump_action = "Jump"
			self.roll_action = "Crouch"
			if self.input.button_press.jump then
				if rail.CheckSwitch(self) then
					--Rail switch jump
					sound.PlaySound(self, "Jump")
					return true
				elseif rail.CheckTrick(self) then
					--Trick jump
					sound.PlaySound(self, "Jump")
					return true
				else
					--Normal jump
					return CheckJump(self)
				end
			end
			return false
		end,
	}) or false
end

--Player update
local admins = {
	[34801411] = true, --DigiPurgatory
	[53427446] = true, --TheGreenDeveloper
	[212784509] = true, --MrMacTtey3
	[1935825706] = true, --SOAPushBurner
}

function player:Update(object_instance)
	debug.profilebegin("player:Update")
	
	--Update input
	input.Update(self)
	
	--Debug input
	if admins[game:GetService("Players").LocalPlayer.UserId] then
		if self.input.button_press.dbg then
			self.gravity = -self.gravity
			self.flag.grounded = false
			self:SetAngle(self.ang * CFrame.Angles(math.pi, 0, 0))
			self.spd *= Vector3.new(1, -1, 0)
		end
	end
	
	--Handle power-ups
	self.invincibility_time = math.max(self.invincibility_time - 1, 0)
	self.speed_shoes_time = math.max(self.speed_shoes_time - 1, 0)
	
	if self.invincibility_time > 0 then
		self.music_id = string.sub(invincibility_theme.SoundId, 14)
		self.music_volume = invincibility_theme.Volume
	elseif self.speed_shoes_time > 0 then
		self.music_id = string.sub(speed_shoes_theme.SoundId, 14)
		self.music_volume = speed_shoes_theme.Volume
	else
		self.music_id = self.level_music_id
		self.music_volume = self.level_music_volume
	end
	
	--Shield idle abilities
	switch(self.shield, {}, {
		["Shield"] = function()
			
		end,
		["MagnetShield"] = function()
			--Get attracting rings
			local attract_range = 35
			local attract_region = Region3.new(self.pos - Vector3.new(attract_range, attract_range, attract_range), self.pos + Vector3.new(attract_range, attract_range, attract_range))
			local rings = object_instance:GetObjectsInRegion(attract_region, function(v)
				return v.class == "Ring" and v.collected ~= true and v.attract_player == nil
			end)
			
			--Attract rings
			for _,v in pairs(rings) do
				if (v.root.Position - self.pos).magnitude < attract_range then
					v:Attract(self)
				end
			end
			
			--Disappear when underwater
			if self.flag.underwater then
				self.shield = nil
			end
		end,
	})
	
	--Reset per frame state
	self.last_turn = 0
	
	--Handle player moves
	self.jump_action = nil
	self.roll_action = nil
	self.secondary_action = nil
	self.tertiary_action = nil
	
	if not self:Scripted() then
		CheckMoves(self, object_instance)
	end
	
	--Water drag
	if self.v3 ~= true and self.flag.underwater then
		if self.state == "Roll" then
			self.spd = vector.AddX(self.spd, self.spd.X * -0.06)
		else
			self.spd = vector.AddX(self.spd, self.spd.X * -0.03)
		end
	end
	
	--Handle timers
	if self.spring_timer > 0 then
		self.spring_timer -= 1
		if self.spring_timer <= 0 then
			self.spring_timer = 0
			self.flag.scripted_spring = false
		end
	end
	
	if self.invulnerability_time > 0 and self:IsBlinking() then
		self.invulnerability_time = math.max(self.invulnerability_time - 1, 0)
	end
	
	if self.dashpanel_timer > 0 then
		self.dashpanel_timer = math.max(self.dashpanel_timer - 1, 0)
	end
	
	if self.dashring_timer > 0 then
		self.dashring_timer = math.max(self.dashring_timer - 1, 0)
	end
	
	if self.rail_debounce > 0 then
		self.rail_debounce = math.max(self.rail_debounce - 1, 0)
	end
	
	if self.rail_trick > 0 then
		self.rail_trick = math.max(self.rail_trick - 0.015, 0)
	end
	
	--Run character state
	switch(self.state, {}, {
		["Idle"] = function()
			--Movement and collision
			movement.GetRotation(self)
			movement.RotatedByGravity(self)
			acceleration.GetAcceleration(self)
			collision.Run(self)
			
			if not rail.CollideRails(self) then
				if not self.flag.grounded then
					--Ungrounded
					self.state = "Airborne"
					self.animation = "Fall"
				else
					--Set animation
					if self.animation ~= "Land" then
						self.animation = "Idle"
					end
				end
			end
		end,
		["Walk"] = function()
			--Movement and collision
			acceleration.GetAcceleration(self)
			collision.Run(self)
			
			if not rail.CollideRails(self) then
				if not self.flag.grounded then
					--Ungrounded
					self.state = "Airborne"
					self.animation = "Fall"
				else
					--Set animation
					self.animation = "Run"
					
					local slip_factor = math.sqrt(self.frict_mult)
					local acc_factor = math.min(math.abs(self.spd.X) / self.p.crash_speed, 1)
					self.anim_speed = lerp(self.spd.X / slip_factor + (1 - slip_factor) * 2, self.spd.X, acc_factor)
				end
			end
		end,
		["Skid"] = function()
			--Movement and collision
			movement.GetSkidSpeed(self)
			collision.Run(self)
			
			if not rail.CollideRails(self) then
				if not self.flag.grounded then
					--Ungrounded
					self.state = "Airborne"
					self.animation = "Fall"
				else
					--Set animation and check if should stop skidding
					self.animation = "Skid"
				end
			end
		end,
		["Spindash"] = function()
			--Movement and collision
			movement.GetRotation(self)
			movement.GetSkidSpeed(self)
			collision.Run(self)
			
			if not rail.CollideRails(self) then
				if not self.flag.grounded then
					--Ungrounded
					self.state = "Airborne"
					sound.StopSound(self, "SpindashCharge")
					
					--Set animation
					self.animation = "Roll"
					self.anim_speed = self.spd.magnitude
				else
					--Set animation
					self.animation = "Spindash"
					self.anim_speed = self.spindash_speed
				end
			end
		end,
		["Roll"] = function()
			--Movement and collision
			movement.GetRotation(self)
			movement.GetInertia(self)
			collision.Run(self)
			
			if not rail.CollideRails(self) then
				if not self.flag.grounded then
					--Ungrounded
					self.state = "Airborne"
				end
				
				--Set animation
				self.animation = "Roll"
				if self.flag.grounded then
					self.anim_speed = self.spd.X
				else
					self.anim_speed = self.spd.magnitude
				end
			end
		end,
		["Airborne"] = function()
			--Movement
			acceleration.GetAirAcceleration(self)
			if self.spring_timer <= 0 and self.dashring_timer <= 0 then
				movement.AlignToGravity(self)
			end
			
			--Handle collision
			local fall_ysp = -self.spd.Y
			self.flag.grounded = false
			collision.Run(self)
			
			if not rail.CollideRails(self) then
				if self.flag.grounded then
					--Landed
					if math.abs(self.spd.X) < self.p.jog_speed then
						if fall_ysp > 2 then
							self.animation = "Land"
						else
							self.animation = "Idle"
						end
						self.spd = vector.SetX(self.spd, 0)
						self.state = "Idle"
					else
						self.state = GetWalkState(self)
					end
					self:Land()
					
					--Play land sound
					if fall_ysp > 0 then
						sound.SetSoundVolume(self, "Land", fall_ysp / 5)
						sound.PlaySound(self, "Land")
					end
				end
			end
		end,
		["Homing"] = function()
			--Handle homing
			local stop_homing = homing_attack.RunHoming(self, object_instance)
			self.anim_speed = self.spd.X
			
			--Handle collision
			self.flag.grounded = false
			movement.AlignToGravity(self)
			collision.Run(self)
			
			if not rail.CollideRails(self) then
				--Check for homing attack to be cancelled
				if self.flag.grounded then
					--Land on the ground
					self.state = GetWalkState(self)
					self:Land()
				else
					--Stop homing attack if wall is hit or was told to stop
					if stop_homing or (self.homing_obj ~= nil and self.spd.magnitude < 2.5) then
						self.state = "Airborne"
						self:ExitBall()
						self.animation = "Fall"
					end
				end
			end
		end,
		["Bounce"] = function()
			--Movement
			acceleration.GetAirAcceleration(self)
			
			--Handle collision
			self.flag.grounded = false
			movement.AlignToGravity(self)
			collision.Run(self)
			
			if not rail.CollideRails(self) then
				--Bounce off floor once we hit one
				if self.flag.grounded then
					--Unground and play sound
					self.state = "Airborne"
					sound.PlaySound(self, "Bounce")
					
					--Set upwards velocity
					self.jump_timer = 0
					if self.v3 ~= true or (math.random() < 0.5) then
						local fac = 1 + (math.abs(self.spd.X) / 16)
						if self.flag.bounce2 == true then
							self.spd = vector.SetY(self.spd, 3.575 * fac)
						else
							self.spd = vector.SetY(self.spd, 2.825 * fac)
							self.flag.bounce2 = true
						end
						self:UseFloorMove()
					end
				end
			end
		end,
		["Rail"] = function()
			--Perform rail movement
			if rail.Movement(self) then
				--Become airborne in fall animation (came off rail)
				self.state = "Airborne"
				self.animation = "Fall"
			end
		end,
		["LightSpeedDash"] = function()
			--Run light speed dash
			if lsd.RunLSD(self, object_instance) then
				--Stop light speed dash
				self.state = "Airborne"
				self.animation = "Fall"
			end
			
			--Handle collision
			self.flag.grounded = false
			collision.Run(self)
			
			if not rail.CollideRails(self) then
				--Stop light speed dash if wall is hit
				if self.spd.magnitude < 1 then
					self.state = "Airborne"
					self.animation = "Fall"
				end
			end
		end,
		["AirKick"] = function()
			--Handle movement
			local has_control, analogue_turn, analogue_mag = input.GetAnalogue(self)
			self.spd += self.spd * Vector3.new(self.p.air_resist_air * (0.285 - analogue_mag * 0.1), self:GetAirResistY(), self.p.air_resist_z)
			self.spd += self:ToLocal(self.gravity) * self:GetWeight() * 0.4
			self:AdjustAngleYS(analogue_turn)
			
			--Handle collision
			local fall_ysp = -self.spd.Y
			self.flag.grounded = false
			movement.AlignToGravity(self)
			collision.Run(self)
			
			if not rail.CollideRails(self) then
				if self.flag.grounded then
					--Landed
					self.state = GetWalkState(self)
					self:Land()
					
					--Play land sound
					if fall_ysp > 0 then
						sound.SetSoundVolume(self, "Land", fall_ysp / 5)
						sound.PlaySound(self, "Land")
					end
				else
					--Stop air kick after timer's run out or we've lost all our speed
					self.air_kick_timer -= 1
					if self.air_kick_timer <= 0 or self.spd.magnitude < 0.35 then
						self.state = "Airborne"
						self.animation = "Fall"
					end
				end
			end
		end,
		["Ragdoll"] = function()
			--Run ragdoll
			if ragdoll.Physics(self) then
				self.state = "Airborne"
				self.animation = "Fall"
				return
			end
			
			--Handle collision
			self.flag.grounded = false
			collision.Run(self)
		end,
		["Hurt"] = function()
			--Handle movement
			movement.GetInertia(self)
			
			--Handle collision
			self.flag.grounded = false
			movement.AlignToGravity(self)
			collision.Run(self)
			
			if not rail.CollideRails(self) then
				if self.flag.grounded then
					--Land on the ground
					self.state = GetWalkState(self)
					self:Land()
					self.animation = "Land"
					self.spd = self.spd:Lerp(Vector3.new(), math.abs(self.dotp))
				elseif self.hurt_time > 0 then
					--Exit hurt state after cooldown
					self.hurt_time = math.max(self.hurt_time - 1, 0)
					if self.hurt_time <= 0 then
						self.state = "Airborne"
						self.animation = "Fall"
					end
				end
			end
		end,
		["Dead"] = function()
			
		end,
		["Drown"] = function()
			
		end,
	})
	
	--Get portrait to use
	if self.state == "Hurt" or self.state == "Dead" then
		self.portrait = "Hurt"
	else
		self.portrait = "Idle"
	end
	
	--Increment game time
	self.time += 1 / constants.framerate
	
	debug.profileend()
end

--Player draw
function player:Draw(dt)
	debug.profilebegin("player:Draw")
	
	--Update animation and dynamic tilt
	animation.Animate(self)
	animation.DynTilt(self, dt)
	
	--Get character position
	local balance = self.state == "Rail" and self.rail_balance or 0
	local off = self.state == "Rail" and self.rail_off or Vector3.new()
	self.vis_ang = (self:AngleToRbx(self.ang) * CFrame.Angles(0, 0, -balance)):Lerp(self.vis_ang, (0.675 ^ 60) ^ dt)
	
	local hrp_cframe = (self.vis_ang + self.pos + off) + (self.vis_ang.UpVector * self.p.hip_height)
	
	--Set Player Draw state
	local ball_form, ball_spin
	if self.animation == "Roll" then
		ball_form = "JumpBall"
		ball_spin = animation.GetAnimationRate(self) * math.pi * 2
	elseif self.animation == "Spindash" then
		ball_form = "SpindashBall"
		ball_spin = animation.GetAnimationRate(self) * math.pi * 2
	else
		ball_form = nil
		ball_spin = 0
	end
	
	self.player_draw:Draw(dt, hrp_cframe, ball_form, ball_spin, self:TrailActive(), self.shield, self.invincibility_time > 0, self:IsBlinking())
	
	--Speed trail
	--if math.abs(self.spd.X) >= (self.p.rush_speed + self.p.crash_speed) / 2 then
	--	self.speed_trail.Enabled = true
	--	self.speed_trail.TextureLength = math.abs(self.spd.X) * 0.875
	--else
	--	self.speed_trail.Enabled = false
	--end
	
	--Rail speed trail
	local rail_speed_trail_active = (rail.GrindActive(self) and math.abs(self.spd.X) >= self.p.crash_speed)
	if rail_speed_trail_active ~= self.rail_speed_trail_active then
		self.rail_speed_trail.Enabled = rail_speed_trail_active
		self.rail_speed_trail_active = rail_speed_trail_active
	end
	
	--Air kick trails
	local air_kick_trails_active = self.animation == "AirKick"
	if air_kick_trails_active ~= self.air_kick_trails_active then
		for _,v in pairs(self.air_kick_trails) do
			v.Enabled = air_kick_trails_active
		end
		self.air_kick_trails_active = air_kick_trails_active
	end
	
	--Skid trail
	local skid_effect_active = self.animation == "Skid"
	if skid_effect_active ~= self.skid_effect_active then
		self.skid_effect.Enabled = skid_effect_active
		self.skid_effect_active = skid_effect_active
	end
	
	--Rail sparks
	local rail_sparks_active = (rail.GrindActive(self) and math.abs(self.spd.X) >= self.p.run_speed)
	if rail_sparks_active ~= self.rail_sparks_active then
		self.rail_sparks.Enabled = rail_sparks_active
		self.rail_sparks_active = rail_sparks_active
	end
	if rail_sparks_active then
		self.rail_sparks.Rate = math.abs(self.spd.X) * 90
		self.rail_sparks.EmissionDirection = (self.spd.X >= 0) and Enum.NormalId.Back or Enum.NormalId.Front
	end
	
	debug.profileend()
end

return player