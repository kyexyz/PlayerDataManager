local Players = game:GetService("Players")

--[=[
   @class PlayerData

   Player Data Class
]=]
local PlayerData = {}
PlayerData.__index = PlayerData

local Packages = require(script.Parent.GetPackages)()
local Janitor = require(Packages:WaitForChild("Janitor"))
local TableUtil = require(Packages:WaitForChild("TableUtil"))
local Signal = require(Packages:WaitForChild("Signal"))
local DataTypes = require(script.Parent.DataTypes)
local TypeCheck = require(script.Parent.TypeCheck)
local PlayerDataManager

local function serialize(value)
	if DataTypes[typeof(value)] then
		local newValue = DataTypes[typeof(value)].serialize(value)
		return newValue, value
	end

	if typeof(value) == "table" then
		for a, b in next, value do
			local new, _ = serialize(b)
			value[a] = new
		end
	end

	return value, value
end

local function deserialize(value)
	if typeof(value) == "table" and value._serialized_type then
		local valueType = value._serialized_type
		if DataTypes[valueType] then
			local newValue = DataTypes[valueType].deserialize(value)
			return newValue, value
		end
	end

	if typeof(value) == "table" then
		for a, b in next, value do
			local new, _ = deserialize(b)
			value[a] = new
		end
	end

	return value, value
end

function PlayerData.new(profile)
	local self = setmetatable({}, PlayerData)

	self._janitor = Janitor.new()
	self._profile = profile
	self._key = tostring(self._profile.UserIds[1])
	self._player = Players:GetPlayerByUserId(tonumber(self._key))

	self.Changed = Signal.new()
	self.Middleware = {}

	self._janitor:Add(self.Changed)

	return self
end

function PlayerData:GetValue(key: string): any
	if not key then
		return
	end

	local value = self._profile.Data[key]

	if self.Middleware[key] then
		value = self.Middleware[key]("GET")
	end

	value = deserialize(value)

	return value
end

function PlayerData:GetRaw(serialized: boolean?): { string: any }
	local data = TableUtil.Copy(self._profile.Data) :: { string: any }

	if serialized then
		return data
	else
		for key, value in next, data do
			if typeof(value) == "table" and value._serialized_type then
				if DataTypes[value._serialized_type] then
					data[key] = DataTypes[value._serialized_type].deserialize(value)
				else
					data[key] = value
				end
			else
				data[key] = value
			end
		end
		return data
	end
end

function PlayerData:SetValue(key: string, value: any): any
	if not self._profile:IsActive() then
		return
	end

	local oldValue = self._profile.Data[key]
	local rawValue = value

	-- Serialize
	value, rawValue = serialize(value)

	-- Middleware
	if self.Middleware[key] then
		value = self.Middleware[key]("UPDATE", value, oldValue)
	end

	-- Type Check
	TypeCheck:Value(key, value)

	-- Update Profile
	self._profile.Data[key] = value

	-- Changed Signal
	self.Changed:Fire(key, value, oldValue)

	-- Return Updated Value
	return rawValue
end

function PlayerData:AdjustValue(key: string, delta: number): any
	if not self._profile:IsActive() then
		return
	end

	local oldValue = self._profile.Data[key]
	if not tonumber(oldValue) or not tonumber(delta) then
		return
	end

	local value = oldValue + delta

	self:SetValue(key, value)

	return value
end

function PlayerData:UpdateValue(key: string, func: (any) -> (any)): any
	if not self._profile:IsActive() then
		return
	end

	local oldValue = self._profile.Data[key]
	local value = func(oldValue)

	self:SetValue(key, value)

	return value
end

function PlayerData:CreateMiddleware(key: string, func)
	assert(not self.Middleware[key], string.format('[%s]: Middleware already exists for key "%s"', self._key, key))

	self.Middleware[key] = func
end

function PlayerData:RemoveMiddleware(key)
	if not self.Middleware[key] then
		return
	end

	self.Middleware[key] = nil
end

function PlayerData:LinkToValueBase(key: string, valueBase: ValueBase)
	if not self._profile:IsActive() then
		return
	end

	return self.Changed:Connect(function(changedKey, newValue)
		if changedKey == key then
			(valueBase :: StringValue).Value = newValue
		end
	end)
end

function PlayerData:Delete(): boolean
	if not PlayerDataManager then
		PlayerDataManager = require(script.Parent)
	end

	return PlayerDataManager:DeletePlayerData(self._key)
end

return PlayerData
