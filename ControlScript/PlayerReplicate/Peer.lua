--[[

= DigitalSwirl Client =

Source: ControlScript/PlayerReplicate/Peer.lua
Purpose: Player Replication Peer class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local peer_class = {}

local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local common_modules = replicated_storage:WaitForChild("CommonModules")
local playerreplicate_modules = common_modules:WaitForChild("PlayerReplicate")

local constants = require(playerreplicate_modules:WaitForChild("Constants"))

local player_draw = require(script.Parent.Parent:WaitForChild("PlayerDraw"))

--Common functions
local function lerp(x, y, z)
	return x + (y - x) * z
end

--Constructor and destructor
function peer_class:New(player)
	--Initialize meta reference
	local self = setmetatable({}, {__index = peer_class})
	
	--Get player to connect to
	self.player = player
	self.name = player.Name
	local s, e = pcall(function()
		self.friend = players.LocalPlayer:IsFriendsWith(player.UserId)
	end)
	if not s then
		warn(e)
	end
	
	--Initialize peer position and other state stuff
	self.tick = nil
	self.rate = constants.packet_rate
	
	--Initialize render state
	self.character_id = nil
	self.ball = nil
	self.shield = nil
	self.invincible = false
	self.ball_spin = 0
	self.ball_draw_spin = 0
	self.trail_active = false
	
	return self
end

function peer_class:Destroy()
	--Destroy player draw
	if self.player_draw ~= nil then
		self.player_draw:Destroy()
		self.player_draw = nil
	end
end

--Peer interface
function peer_class:SendData(data)
	debug.profilebegin("peer_class:SendData")
	
	--Process data
	if typeof(data.cframe) == "CFrame" then
		if data.character_id ~= self.character_id or data.tween == false then
			self.prev_cf = data.cframe
			self.cur_cf = data.cframe
		elseif data.tween == true then
			self.prev_cf = self.cur_cf
			self.cur_cf = data.cframe
		end
	else
		self.prev_cf = nil
		self.cur_cf = nil
	end
	
	if typeof(data.ball) == "string" then
		self.ball = data.ball
	else
		self.ball = nil
	end
	
	if typeof(data.ball_spin) == "number" then
		self.ball_spin = data.ball_spin
	else
		self.ball_spin = 0
	end
	
	if typeof(data.trail_active) == "boolean" then
		self.trail_active = data.trail_active
	else
		self.trail_active = false
	end
	
	if typeof(data.shield) == "string" then
		self.shield = data.shield
	else
		self.shield = nil
	end
	
	if typeof(data.invincible) == "boolean" then
		self.invincible = data.invincible
	else
		self.invincible = false
	end
	
	--Handle character and HumanoidRootPart updates
	if data.character_id ~= self.character_id then
		--Create new player draw
		if self.player_draw ~= nil then
			self.player_draw:Destroy()
		end
		self.player_draw = player_draw:New(data.character_id, self.name)
		self.character_id = data.character_id
	end
	
	--Handle tick and rate calculation
	local now = tick()
	if self.tick ~= nil then
		local dt = now - self.tick
		self.rate = lerp(self.rate, dt, 0.25)
	end
	self.tick = now
	
	debug.profileend()
end

function peer_class:Update(dt)
	debug.profilebegin("peer_class:Update")
	
	if self.player_draw ~= nil and self.prev_cf ~= nil and self.cur_cf ~= nil and self.tick ~= nil then
		--Calculate interpolated CFrame
		local now = tick()
		local interp = math.min((now - self.tick) / self.rate, 1)
		local cframe = self.prev_cf:Lerp(self.cur_cf, interp)
		
		--Draw player draw
		self.player_draw:Draw(dt, cframe, self.ball, self.ball_spin, self.trail_active, self.shield, self.invincible)
	end
	
	debug.profileend()
end

return peer_class