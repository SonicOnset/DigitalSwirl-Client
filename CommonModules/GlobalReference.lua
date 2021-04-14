--[[

= DigitalSwirl =

Source: CommonModules/GlobalReference.lua
Purpose: Global Reference class
Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

--]]

local global_reference = {}

local cur_ref_reg = {}

--Common functions
local function StringSplit(s, delimiter)
	local spl = {}
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(spl, match)
	end
	return spl
end

--Internal interface
local function InitialReference(self)
	--Disconnect current reference connection
	if self.cur_p_con ~= nil then
		self.cur_p_con:Disconnect()
		self.cur_p_con = nil
	end
	
	--Find next current reference
	self.cur_p = self.parent
	for _,v in pairs(self.spl_dir) do
		local n = self.cur_p:FindFirstChild(v)
		if n ~= nil then
			self.cur_p = n
		else
			self.cur_p = nil
			break
		end
	end
	
	--Connect if reference was found
	if self.cur_p ~= nil then
		self.cur_p_con = self.cur_p:GetPropertyChangedSignal("Parent"):Connect(function()
			InitialReference(self)
		end)
	end
end

local function GetKey(parent, directory)
	return parent:GetFullName().."\\"..directory
end

local function Register(parent, directory)
	local key = GetKey(parent, directory)
	if cur_ref_reg[key] ~= nil then
		--Increment registration count
		cur_ref_reg[key].count += 1
		return cur_ref_reg[key].instance, true
	else
		--Create new registry
		local self = setmetatable({}, {__index = global_reference})
		cur_ref_reg[key] = {instance = self, count = 1}
		return self, false
	end
end

local function Deregister(parent, directory)
	local key = GetKey(parent, directory)
	if cur_ref_reg[key] ~= nil then
		--Decrement registration count
		cur_ref_reg[key].count -= 1
		if cur_ref_reg[key].count <= 0 then
			--Destroy registry since there's no more references
			cur_ref_reg[key] = nil
			return false
		else
			--Registry hasn't been destroyed yet
			return true
		end
	else
		return true
	end
end

--Constructor and destructor
function global_reference:New(parent, directory)
	--Check for same reference
	local self, alreg = Register(parent, directory)
	if alreg then
		return self
	end
	
	--Parse directory
	self.parent = parent
	self.directory = directory
	self.spl_dir = StringSplit(directory, "/")
	
	--Initial reference to given directory
	self.cur_p_con = nil
	InitialReference(self)
	
	return self
end

function global_reference:Destroy()
	--Deregister reference
	if Deregister(parent, directory) then
		return
	end
	
	--Disconnect current reference connection
	if self.cur_p_con ~= nil then
		self.cur_p_con:Disconnect()
		self.cur_p_con = nil
	end
end

--Global reference interface
function global_reference:Get()
	if self.cur_p == nil then
		InitialReference(self)
	end
	return self.cur_p
end

return global_reference