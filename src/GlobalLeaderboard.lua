local Players = game:GetService("Players")

local GlobalLeaderboard = {}
GlobalLeaderboard.__index = GlobalLeaderboard

local Packages = require(script.Parent.GetPackages)()
local Signal = require(Packages:WaitForChild("Signal"))
local Janitor = require(Packages:WaitForChild("Janitor"))

function GlobalLeaderboard.new(dataKey: string, orderedDataStore: OrderedDataStore, loadedPlayerData)
	local self = setmetatable({}, GlobalLeaderboard)

	self._janitor = Janitor.new()
	self._dataKey = dataKey
	self._dataStore = orderedDataStore
	self._loadedPlayerData = loadedPlayerData
	self._loopRunning = true
	self._refreshTime = 60
	self._data = nil
	self._dataGetDebounce = false
	self._excludedPlayers = {}
	self._lastSaved = {}
	self.RefreshingIn = Signal.new()

	self._janitor:Add(self.RefreshingIn)

	task.spawn(function()
		while self._loopRunning do
			for i = self._refreshTime, 0, -1 do
				self.RefreshingIn:Fire(i)
				task.wait(1)
			end
			self:_save()
		end
	end)

	self._janitor:Add(Players.PlayerRemoving:Connect(function(player: Player)
		if
			not self._lastSaved[tostring(player.UserId)]
			or (self._lastSaved[tostring(player.UserId)] and os.time() - self._lastSaved[tostring(player.UserId)] > 10)
		then
			self:_save_player(self._loadedPlayerData[tostring(player.UserId)])
		end

		self._lastSaved[tostring(player.UserId)] = nil
	end))

	return self
end

function GlobalLeaderboard:_save_player(playerData)
	if not playerData then
		return
	end

	if table.find(self._excludedPlayers, playerData._key) then
		return
	end

	local value = playerData:GetValue(self._dataKey)

	if value and tonumber(value) then
		self._dataStore:SetAsync(playerData._key, value)
		self._lastSaved[playerData._key] = os.time()
	end
end

function GlobalLeaderboard:_save()
	for _, playerData in next, self._loadedPlayerData do
		task.spawn(function()
			self:_save_player(playerData)
		end)
	end
end

function GlobalLeaderboard:GetData(ascending: boolean, size: number)
	if self._dataGetDebounce then
		return
	end
	self._dataGetDebounce = true
	task.delay(30, function()
		if self then
			self._dataGetDebounce = false
		end
	end)

	local dataStorePages: DataStorePages = self._dataStore:GetSortedAsync(ascending, size)
	local data = dataStorePages:GetCurrentPage()

	return data
end

function GlobalLeaderboard:Destroy()
	self._loopRunning = false
	self._janitor:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

return GlobalLeaderboard
