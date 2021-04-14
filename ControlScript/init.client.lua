--[[

= DigitalSwirl Client =

Source: ControlScript.client.lua
Purpose: Entry point to the DigitalSwirl client code
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player = game:GetService("Players").LocalPlayer
local run_service = game:GetService("RunService")
local replicated_storage = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")

local assets = script:WaitForChild("Assets")
local guis = assets:WaitForChild("Guis")

local constants = require(script:WaitForChild("Constants"))

--Debug display
local debug_gui = Instance.new("ScreenGui")
debug_gui.IgnoreGuiInset = false
debug_gui.ResetOnSpawn = false
debug_gui.Parent = player:WaitForChild("PlayerGui")

local debug_labels = {}

local fps_tick = tick() + 1
local fps_count = 0
local tps_count = 0
local cur_fps = 0
local cur_tps = 0

--Game classes
local player_class = require(script:WaitForChild("Player"))
local object_class = require(script:WaitForChild("Object"))
local hud_class = require(script:WaitForChild("Hud"))
local music_class = require(script:WaitForChild("Music"))
local player_replicate_class = require(script:WaitForChild("PlayerReplicate"))

--Game objects
local player_object = nil
local object_instance = nil
local hud_instance = nil
local music_instance = nil
local player_replicate_instance = nil

--SEO V3 command
local meme_seo_v3 = replicated_storage:WaitForChild("MemeSEOV3")
local v3_active = false

meme_seo_v3.OnClientEvent:Connect(function()
	v3_active = not v3_active
	if player_object ~= nil then
		player_object.v3 = v3_active
	end
end)

--Debug gravity command
local debug_gravity = replicated_storage:WaitForChild("DebugGravity")

debug_gravity.OnClientEvent:Connect(function(gravity)
	if player_object ~= nil then
		player_object.gravity = gravity
	end
end)

--Set physics command
local set_physics = replicated_storage:WaitForChild("SetPhysics")

local sp_game = nil
local sp_char = nil

set_physics.OnClientEvent:Connect(function(game, char)
	if player_object ~= nil then
		sp_game = game
		sp_char = char
		player_object:SetPhysics(game, char)
	end
end)

--Character added event
function CharacterAdded(character)
	--Destroy previous game objects
	if player_object then
		player_object:Destroy()
		player_object = nil
	end
	if object_instance then
		object_instance:Destroy()
		object_instance = nil
	end
	
	--Create new player object for our character
	player_object = player_class:New(character)
	if player_object == nil then
		error("Failed to create player object")
	end
	player_object.v3 = v3_active
	if sp_game ~= nil and sp_char ~= nil then
		player_object:SetPhysics(sp_game, sp_char)
	end
	
	--Create new object instance
	object_instance = object_class:New()
	if object_instance == nil then
		error("Failed to create object instance")
	end
	
	--Create new music instance
	music_instance = music_class:New(player:WaitForChild("PlayerScripts"))
	if music_instance == nil then
		error("Failed to create music instance")
	end
end

function CharacterRemoving(character)
	--Destroy previous game objects
	if music_instance ~= nil then
		music_instance:Destroy()
		music_instance = nil
	end
	if player_object ~= nil then
		player_object:Destroy()
		player_object = nil
	end
	if object_instance ~= nil then
		object_instance:Destroy()
		object_instance = nil
	end
end

--Game initialization
player_replicate_instance = player_replicate_class:New()
hud_instance = hud_class:New(player:WaitForChild("PlayerGui"))

--Attach character creation and destruction events
if player.Character then
	CharacterAdded(player.Character)
end
player.CharacterAdded:Connect(CharacterAdded)
player.CharacterRemoving:Connect(CharacterRemoving)

--Game update
local next_tick = tick()

local recycle_frames = 4
local recycle_time = 5
local next_recycle = next_tick + recycle_time

run_service:BindToRenderStep("ControlScript_CharacterUpdate", Enum.RenderPriority.Input.Value, function(dt)
	local now = tick()
	
	--Framerate count 
	fps_count += 1
	
	--Update game
	local framerate = 1 / constants.framerate
	
	if now >= (next_tick + (framerate * 10)) then
		next_tick = now
	end
	
	if now >= next_recycle and now >= (next_tick + (framerate * recycle_frames)) then
		next_tick = now
		next_recycle = now + recycle_time
	end
	
	while now >= next_tick do
		--Tickrate count
		tps_count += 1
		
		--Update player
		if player_object ~= nil then
			player_object:Update(object_instance)
		end
		
		--Update objects
		if object_instance ~= nil then
			object_instance:Update()
			if player_object ~= nil then
				object_instance:TouchPlayer(player_object)
			end
		end
		
		--Update music
		if music_instance ~= nil and player_object ~= nil then
			music_instance:Update(player_object.music_id, player_object.music_volume, player_object.music_reset)
			player_object.music_reset = false
		end
		
		--Increment tickrate counter
		next_tick += framerate
	end
	
	--Draw game
	if player_object ~= nil then
		--Draw player
		player_object:Draw(dt)
		
		--Update Hud display
		hud_instance:UpdateDisplay(dt, player_object)
	end
	
	if object_instance ~= nil then
		--Draw objects
		object_instance:Draw(dt)
	end
	
	--Handle player replication
	if player_replicate_instance ~= nil then
		if player_object ~= nil and player_object.player_draw ~= nil then
			player_replicate_instance:UpdateSelf(player_object.player_draw)
		end
		player_replicate_instance:UpdatePeers(dt)
	end
end)

--Debug display
local debug_enabled = false

local function NumberString(x)
	if typeof(x) == "number" then
		return tostring(math.floor(x * 100 + 0.5) / 100)
	end
	return "nil"
end

local function VectorString(x)
	if typeof(x) == "Vector3" then
		return NumberString(x.X)..", "..NumberString(x.Y)..", "..NumberString(x.Z)
	elseif typeof(x) == "Vector2" then
		return NumberString(x.X)..", "..NumberString(x.Y)
	end
	return "nil"
end

local function PointerString(x)
	if typeof(x) == "table" then
		return string.sub(tostring(x), 10)
	elseif typeof(x) == "function" then
		return string.sub(tostring(x), 13)
	end
	return "nil"
end

local function BoolString(x)
	if typeof(x) == "boolean" then
		return tostring(x)
	end
	return "nil"
end

local function RecPrint(p, t)
	local pt = string.rep("    ", t)
	for i, v in pairs(p) do
		if typeof(v) == "table" then
			print(pt..tostring(i)..": ("..tostring(v)..")")
			RecPrint(v, t + 1)
		elseif typeof(v) == "Instance" then
			print(pt..tostring(i)..": "..v:GetFullName())
		else
			print(pt..tostring(i)..": "..tostring(v))
		end
	end
end

uis.InputBegan:Connect(function(input, game_processed)
	if uis:GetFocusedTextBox() == nil and not game_processed then
		if input.UserInputType == Enum.UserInputType.Keyboard and uis:IsKeyDown(Enum.KeyCode.L) then
			if input.KeyCode == Enum.KeyCode.Zero then
				debug_enabled = not debug_enabled
			elseif input.KeyCode == Enum.KeyCode.One then
				if player_object ~= nil then
					RecPrint({player_object=player_object}, 0)
				end
			end
		end
	end
end)

run_service:BindToRenderStep("ControlScript_DebugDisplay", Enum.RenderPriority.Last.Value, function(dt)
	--Update framerate counters
	local now = tick()
	if now >= fps_tick then
		cur_fps = fps_count
		cur_tps = tps_count
		fps_count = 0
		tps_count = 0
		fps_tick = now + 1
	end
	
	--Get labels to show
	local labels = {}
	
	--Framerate display
	table.insert(labels, "-Framerate-")
	table.insert(labels, "  "..NumberString(cur_fps).." FPS")
	table.insert(labels, "  "..NumberString(cur_tps).." TPS")
	
	if debug_enabled then
		--Player display
		table.insert(labels, "-Player-")
		if player_object ~= nil then
			--Position and speed display
			table.insert(labels, "  Spd (u/f) "..VectorString(player_object.spd))
			table.insert(labels, "  Spd (s/s) "..VectorString((player_object.spd * constants.framerate) * player_object.p.scale))
			table.insert(labels, "  Pos "..VectorString(player_object.pos))
			
			--Angle display
			local ang = Vector3.new(player_object:AngleToRbx(player_object.ang):ToOrientation()) * 180 / math.pi
			table.insert(labels, "  Ang (Rbx Space Euler) "..VectorString(ang))
			
			--Normal display
			table.insert(labels, "  Normal "..VectorString(player_object.floor_normal))
			table.insert(labels, "  Gravity "..VectorString(player_object.gravity))
			table.insert(labels, "  Up Dot "..NumberString(player_object.dotp))
			
			--Power-up display
			table.insert(labels, "  - Power-up -")
			table.insert(labels, "    Speed Shoes Time "..NumberString(player_object.speed_shoes_time))
			table.insert(labels, "    Invincibility Time "..NumberString(player_object.invincibility_time))
			
			--Floor display
			if player_object.floor ~= nil then
				table.insert(labels, "  - Floor -")
				table.insert(labels, "    Floor "..player_object.floor:GetFullName())
				table.insert(labels, "    Floor Move (s/f) "..VectorString(player_object.floor_move))
			end
			
			--State display
			local state_name = "invalid"
			for i,v in pairs(constants.state) do
				if player_object.state == v then
					state_name = i
				end
			end
			table.insert(labels, "  -State "..state_name.."-")
			
			if player_object.state == constants.state.walk or player_object.state == constants.state.roll then
				--Walking / rolling display
				table.insert(labels, "    Dash Panel Timer "..NumberString(player_object.dashpanel_timer))
			elseif player_object.state == constants.state.airborne then
				--Airborne display
				table.insert(labels, "    Jump Timer "..NumberString(player_object.jump_timer))
				table.insert(labels, "    Spring Timer "..NumberString(player_object.spring_timer))
				table.insert(labels, "    Dash Ring Timer "..NumberString(player_object.dashring_timer))
				table.insert(labels, "    Rail Trick "..NumberString(player_object.rail_trick))
			elseif player_object.state == constants.state.spindash then
				--Spindash display
				table.insert(labels, "    Spindash Speed "..NumberString(player_object.spindash_speed))
			elseif player_object.state == constants.state.rail then
				--Rail display
				table.insert(labels, "    Rail Dir "..NumberString(player_object.rail_dir))
				table.insert(labels, "    Balance "..NumberString(math.deg(player_object.rail_balance)))
				table.insert(labels, "    Target Balance "..NumberString(math.deg(player_object.rail_tgt_balance)))
				table.insert(labels, "    Grace "..NumberString(player_object.rail_grace))
				table.insert(labels, "    Bonus Time "..NumberString(player_object.rail_bonus_time))
			elseif player_object.state == constants.state.bounce then
				--Bounce display
				table.insert(labels, "    Second Bounce "..BoolString(player_object.flag.bounce2))
			elseif player_object.state == constants.state.homing then
				--Homing attack display
				table.insert(labels, "    Target "..PointerString(player_object.homing_obj))
				table.insert(labels, "    Homing Timer "..NumberString(player_object.homing_timer))
			elseif player_object.state == constants.state.light_speed_dash then
				--Light speed dash display
				table.insert(labels, "    Target "..PointerString(player_object.lsd_obj))
			elseif player_object.state == constants.state.air_kick then
				--Air kick display
				table.insert(labels, "    Air Kick Timer "..NumberString(player_object.air_kick_timer))
			elseif player_object.state == constants.state.ragdoll then
				--Ragdoll display
				table.insert(labels, "    Ragdoll Timer "..NumberString(player_object.ragdoll_time))
			end
		end
	end
	
	--Destroy or allocate new labels
	if #labels < #debug_labels then
		for i = #labels + 1, #debug_labels do
			debug_labels[i]:Destroy()
			debug_labels[i] = nil
		end
	elseif #labels > #debug_labels then
		for i = #debug_labels + 1, #labels do
			local new_label = Instance.new("TextLabel")
			new_label.BackgroundTransparency = 1
			new_label.BorderSizePixel = 0
			new_label.AnchorPoint = Vector2.new(1, 1)
			new_label.Position = UDim2.new(1, 0, 1, (i * -20) - 8)
			new_label.Size = UDim2.new(0, 320, 0, 20)
			new_label.Font = Enum.Font.GothamBlack
			new_label.TextColor3 = Color3.new(1, 1, 1)
			new_label.TextStrokeTransparency = 0
			new_label.TextSize = 14
			new_label.TextXAlignment = Enum.TextXAlignment.Left
			new_label.Parent = debug_gui
			debug_labels[i] = new_label
		end
	end
	
	--Write label text
	for i = 1, #labels do
		local v = #labels - (i - 1)
		debug_labels[i].Text = labels[v]
	end
end)