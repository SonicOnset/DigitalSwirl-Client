--[[

= DigitalSwirl Client =

Source: ControlScript/Music.lua
Purpose: Provides music playback
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local music_class = {}

--Constructor and destructor
function music_class:New(parent)
	--Initialize meta reference
	local self = setmetatable({}, {__index = music_class})
	
	--Create music object
	self.music = Instance.new("Sound")
	self.music.Name = "Music"
	self.music.Looped = true
	self.music.Parent = parent
	
	--Initialize music state
	self.music_id = "0"
	self.music_volume = 0
	
	return self
end

function music_class:Destroy()
	--Destroy music object
	if self.music ~= nil then
		self.music:Destroy()
		self.music = nil
	end
end

--Music interface
function music_class:Update(id, volume, reset)
	--Update volume
	volume = tonumber(volume)
	if volume ~= nil and volume ~= self.music_volume then
		self.music.Volume = volume
		self.music_volume = volume
	end
	
	--Update id
	id = tostring(id)
	if id ~= self.music_id or reset then
		self.music:Stop()
		self.music.SoundId = "rbxassetid://"..id
		self.music_id = id
		self.music:Play()
	end
end

return music_class