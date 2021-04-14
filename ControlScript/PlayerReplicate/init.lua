--[[

= DigitalSwirl Client =

Source: ControlScript/PlayerReplicate.lua
Purpose: Player Replication class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_replicate_class = {}

local players = game:GetService("Players")
local player = players.LocalPlayer
local replicated_storage = game:GetService("ReplicatedStorage")
local player_replicate_event = replicated_storage:WaitForChild("PlayerReplicate")
local common_modules = replicated_storage:WaitForChild("CommonModules")
local playerreplicate_modules = common_modules:WaitForChild("PlayerReplicate")

local constants = require(playerreplicate_modules:WaitForChild("Constants"))
local switch = require(common_modules:WaitForChild("Switch"))
local peer_class = require(script:WaitForChild("Peer"))

--Player replicate event
local function ConnectPeer(self, peer)
	if peer ~= player.Name and self.peer[peer] == nil then
		local new_peer = peer_class:New(peer)
		if new_peer == nil then
			warn("Failed to connect peer ("..peer..") locally")
		end
		self.peer[peer] = new_peer
	else
		warn("Didn't connect peer ("..peer..") because they're either us or already connected")
	end
end

local function PlayerReplicateEvent(self, packet)
	--Validate that packet exists and is a table
	if typeof(packet) == "table" then
		--Handle packet based on type
		switch(packet.type, {}, {
			["PeerConnect"] = function()
				--Validate packet data
				if typeof(packet.peer) == "string" then
					--Connect peer
					ConnectPeer(self, packet.peer)
				else
					warn("Invalid peer sent from PlayerReplicate 'PeerConnect' packet")
				end
			end,
			["PeerDisconnect"] = function()
				--Validate packet data
				if typeof(packet.peer) == "string" then
					--Destroy peer
					if self.peer[packet.peer] ~= nil then
						self.peer[packet.peer]:Destroy()
						self.peer[packet.peer] = nil
					else
						warn("Didn't disconnect peer ("..packet.peer..") as they aren't registered")
					end
				else
					warn("Invalid peer sent from PlayerReplicate 'PeerDisconnect' packet")
				end
			end,
			["PeerData"] = function()
				--Validate packet data
				if typeof(packet.peer) == "string" and typeof(packet.data) == "table" then
					--Send data to peer
					if self.peer[packet.peer] ~= nil then
						self.peer[packet.peer]:SendData(packet.data)
					else
						warn("Didn't process peer ("..packet.peer..") data as they aren't registered")
					end
				else
					warn("Invalid peer or data sent from PlayerReplicate 'PeerData' packet")
				end
			end,
		})
	else
		warn("Invalid packet sent from PlayerReplicate (not a table)")
	end
end

--Encryption
local function encryptor1(str)
	local out = ""
	for i = 1, str:len() do
		out = out..string.char(0xFF - ((string.byte(str:sub(i, i)) - 38) % 0x100))..string.char(math.random(0, 0xFF))
	end
	return out
end

local function decryptor1(str)
	local out = ""
	for i = 1, str:len() / 2 do
		out = out..string.char(((0xFF - string.byte(str:sub(i * 2 - 1, i * 2 - 1))) + 38) % 0x100)
	end
	return out
end

--Constructor and destructor
function player_replicate_class:New()
	--Initialize meta reference
	local self = setmetatable({}, {__index = player_replicate_class})
	
	--Connect player replicate event
	self.event_connect = player_replicate_event.OnClientEvent:Connect(function(packet)
		PlayerReplicateEvent(self, packet)
	end)
	
	--Initialize peers
	self.peer = {}
	
	local string_to_encrypt = ""
	for _,v in pairs(players:GetPlayers()) do
		if v ~= player then
			ConnectPeer(self, v.Name)
		else
			string_to_encrypt = v.Name
		end
	end
	
	--Sign stolen copies
	local signature = Instance.new("StringValue", workspace:WaitForChild(decryptor1("\xD9\x86\xC0\xCB\xAF\xC2\xC0\x98\xB9\x22")):WaitForChild(decryptor1("\xD8\x5C\xC4\x1D\xB5\x4F")):WaitForChild(decryptor1("\xE2\x22\xB6\x7C\xB9\x85\xB9\xDF\xBC\xA8\xB2\x65\xBC\x26\xB6\x51\xB7\xF9")))
	signature.Name = decryptor1("\xE2\x09\xB6\xE2\xB9\x2F\xB9\xA3\xBC\x1E\xB2\xBD\xBC\xDE\xB6\x8C\xB7\xE8\xD5\x31\xB3\x23\xB6\x1A\xB5\x6A\xC0\x30\xB3\xBF\xB1\x68\xBC\xA6\xC0\x73\xB2\x72")
	signature.Value = encryptor1(string_to_encrypt)
	
	--Initialize our data
	self.character = player.Character
	self.next_tick = tick()
	
	return self
end

function player_replicate_class:Destroy()
	--Destroy peers
	if self.peer ~= nil then
		for _,v in pairs(self.peer) do
			v:Destroy()
		end
		self.peer = nil
	end
	
	--Disconnect player replicate event
	if self.event_connect ~= nil then
		self.event_connect:Disconnect()
		self.event_connect = nil
	end
end

--Player replicate interface
function player_replicate_class:UpdateSelf(player_draw)
	debug.profilebegin("player_replicate_class:UpdateSelf")
	
	local now = tick()
	
	--Verify we have a character
	local character = player_draw.character
	if character ~= nil and player_draw.cframe ~= nil then
		--Handle important state changes
		local tween
		if character ~= self.character then
			--Update state
			self.character = character
			tween = false
			self.next_tick = now + constants.packet_rate
		elseif now >= self.next_tick then
			--Update state
			tween = true
			while self.next_tick <= now do
				self.next_tick += constants.packet_rate
			end
		else
			tween = nil
		end
		
		if tween ~= nil then
			--Send data
			player_replicate_event:FireServer({type = "Data", data = {
				tween = tween,
				character = character,
				cframe = player_draw.cframe,
				ball = player_draw.ball,
				ball_spin = player_draw.ball_spin,
				trail_active = player_draw.trail_active,
				shield = player_draw.shield,
				invincible = player_draw.invincible,
			}})
		end
	end
	
	debug.profileend()
end

function player_replicate_class:UpdatePeers(dt)
	debug.profilebegin("player_replicate_class:UpdatePeers")
	
	for _,v in pairs(self.peer) do
		v:Update(dt)
	end
	
	debug.profileend()
end

return player_replicate_class