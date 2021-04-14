--[[

= Sonic Onset Adventure Client =

Source: ControlScript/Player/Sound.lua
Purpose: Player sound functions
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local player_sound = {}

local sounds = script.Parent:WaitForChild("Sounds")

--Sound interface
function player_sound.LoadSounds(self)
	--Unload previous sounds
	player_sound.UnloadSounds(self)
	
	--Load sounds
	self.sounds = {}
	self.sound_volume = {}
	
	for _,v in pairs(sounds:GetChildren()) do
		if v:IsA("Sound") then
			--Create new sound object and parent to sound source
			local new_snd = v:Clone()
			new_snd.Parent = self.hrp
			
			--Register new sound
			self.sounds[v.Name] = new_snd
			self.sound_volume[v.Name] = v.Volume
		end
	end
end

function player_sound.UnloadSounds(self)
	--Unload sounds
	if self.sounds ~= nil then
		for _,v in pairs(self.sounds) do
			v:Destroy()
		end
		self.sounds = nil
	end
end

function player_sound.PlaySound(self, name)
	--Play sound if exists
	if self.sounds[name] ~= nil then
		self.sounds[name]:Play()
	end
end

function player_sound.StopSound(self, name)
	--Stop sound if exists
	if self.sounds[name] ~= nil then
		self.sounds[name]:Stop()
	end
end

function player_sound.SetSoundVolume(self, name, vol)
	--Set sound's volume if exists
	if self.sounds[name] ~= nil then
		self.sounds[name].Volume = self.sound_volume[name] * vol
	end
end

function player_sound.SetSoundPitch(self, name, pitch)
	--Set sound's pitch if exists
	if self.sounds[name] ~= nil then
		self.sounds[name].Pitch = pitch
	end
end

return player_sound