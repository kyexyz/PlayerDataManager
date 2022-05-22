--[[
   ** PlayerDataManager **
   -----------------------
   Easy Player Data Module
   -----------------------
   Made by kyexyz


   :GetPlayerData(userId: number | string) -> PlayerData
   :DeletePlayerData(userId: number | string) -> wasSuccessful [boolean]
   :CreateLeaderstats(player: Player, {LeaderstatData}) -> Janitor

   -- PlayerData --
      .Changed [ScriptSignal] (key: string, value: any, oldValue: any)
      :GetValue(key: string) -> any
      :GetRaw() -> {string: any}
      :UpdateValue(key: string, value: any, updateType: string?) -> newValue [any]
      :CreateMiddleware(key: string, func)
      :RemoveMiddleware(key: string)
      :LinkDataToValueBase(key: string, value: ValueBase) -> ScriptConnection
      :Delete() -> wasSuccessful [boolean]
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataManager = {
   _profile_store = nil,
   _loaded = {},
   _loading = {},
   _view_only_loaded = {},
   _view_only_loading = {},
   _global_leaderboards = {},
   _generated_user_ids = {},
}

local Packages = ReplicatedStorage:WaitForChild("Packages")
local ProfileService = require(Packages:WaitForChild("ProfileService"))
local Janitor = require(Packages:WaitForChild("Janitor"))
local DataTypes = require(script.DataTypes)
local GlobalLeaderboard = require(script.GlobalLeaderboard)
local TypeCheck = require(script.TypeCheck)
local PlayerData


type LeaderstatData = {
   Name: string,
   Key: string,
   Type: string?,
   Parser: (any) -> (any)?,
}

type Configuration = {
   SAVE_IN_STUDIO: boolean,
   DATA_VERSION: string,
   TESTING_PLACE_ID: string,
   TESTING_DATA_VERSION: string,

   DEFAULT_DATA: {
      [string]: {
         value: any,
         type: string,
         optional: boolean?,
      } | any,
   },
}  


local function fetchProfileStore()
   local version = game.PlaceId ==  _G.PLAYERDATAMANAGER_CONFIGURATION.TESTING_PLACE_ID and  _G.PLAYERDATAMANAGER_CONFIGURATION.TESTING_DATA_VERSION or  _G.PLAYERDATAMANAGER_CONFIGURATION.DATA_VERSION

   PlayerDataManager._profile_store = ProfileService.GetProfileStore("PlayerData-" .. version, PlayerDataManager:_getDefaultData())

   if not  _G.PLAYERDATAMANAGER_CONFIGURATION.SAVE_IN_STUDIO and RunService:IsStudio() then
      PlayerDataManager._profile_store = PlayerDataManager._profile_store.Mock
   end
end

function PlayerDataManager:_getDefaultData(raw: boolean?)
   if raw then
      return  _G.PLAYERDATAMANAGER_CONFIGURATION.DEFAULT_DATA
   else
      local data = {}
      for key, value in next,  _G.PLAYERDATAMANAGER_CONFIGURATION.DEFAULT_DATA do
         if typeof(value) == 'table' and value.value then 
            value = value
         end
         
         if DataTypes[typeof(value)] then
            data[key] = DataTypes[typeof(value)].serialize(value)
         else
            data[key] = value
         end
      end
      return data
   end
end

function PlayerDataManager:_getRandomUserIdForPlayer(player: Player)
   if self._generated_user_ids[player] then return self._generated_user_ids[player] end

   local userId = math.random(1, 999999999)
   
   local function alreadyExists()
      for _, id in next, self._generated_user_ids do 
         if userId == id then
            return true
         end
      end
   end
   
   while alreadyExists() do
      userId = math.random(1, 999999999)
   end
   
   PlayerDataManager._generated_user_ids[player] = userId

   return userId
end

function PlayerDataManager:Init(configuration: Configuration)
   if _G.PLAYERDATAMANAGER_INITIALIZED then return end
   if not configuration then return error('No configuration provided for PlayerDataManager:Init') end 
   _G.PLAYERDATAMANAGER_INITIALIZED = true
   
   _G.PLAYERDATAMANAGER_CONFIGURATION = configuration

   -- Type Check Default Data
   TypeCheck:Data(_G.PLAYERDATAMANAGER_CONFIGURATION)

   Players.PlayerRemoving:Connect(function(player: Player)
      local playerData = PlayerDataManager:GetPlayerData(player.UserId)
      pcall(function()
         if playerData then
            playerData._profile:Release()
         end
         PlayerDataManager._generated_user_ids[player] = nil
      end)
   end)
end

function PlayerDataManager:GetPlayerData(userId: number | string)
   if not _G.PLAYERDATAMANAGER_INITIALIZED then return end 

   if tonumber(userId) <= 0 then
      local plr = Players:GetPlayerByUserId(userId)
      if plr then
         userId = self:_getRandomUserIdForPlayer(plr)
      else
         return 
      end
   end
   
   userId = tostring(userId)

   if not self._profile_store then
      fetchProfileStore()
   end

   if self._loaded[userId] then
      return self._loaded[userId]
   end

   if self._loading[userId] then
      repeat task.wait() until not self._loading[userId]
      return self._loaded[userId]
   end

   self._loading[userId] = true

   local profile = self._profile_store:LoadProfileAsync(userId, "ForceLoad")
   -- local player = Players:GetPlayerByUserId(userId) 
   if profile then
      profile:AddUserId(tonumber(userId))
      profile:Reconcile()
      profile:ListenToRelease(function()
         self._loaded[userId] = nil
      end)
   else
      self._loading[userId] = nil
      warn(string.format("[PlayerDataManager] Failed to load data for player %s", userId))
      return
   end

   if not PlayerData then
      PlayerData = require(script.PlayerData)
   end

   self._loaded[userId] = PlayerData.new(profile)
   self._loading[userId] = nil

   return self._loaded[userId]
end

function PlayerDataManager:ViewPlayerData(userId: number | string, version: string?)
   if not _G.PLAYERDATAMANAGER_INITIALIZED then return end 

   userId = tostring(userId)

   if not self._profile_store then
      fetchProfileStore()
   end

   if self._view_only_loaded[userId] then
      return self._view_only_loaded[userId]
   end

   if self._view_only_loading[userId] then
      repeat task.wait() 
      until 
      not self._view_only_loading[userId]
      return self._view_only_loaded[userId]
   end

   self._view_only_loading[userId] = true

   local profile = self._profile_store:ViewProfileAsync(userId, version)
   local player = Players:GetPlayerByUserId(userId)
   if profile then
      profile:AddUserId(tonumber(userId))
      profile:Reconcile()
      profile:ListenToRelease(function()
         self._view_only_loading[userId] = nil
         if player then
            player:Kick("[PlayerDataManager] Failed to load data")
         end
      end)
   else
      self._view_only_loading[userId] = nil
      return
   end

   if not PlayerData then
      PlayerData = require(script.PlayerData)
   end

   self._view_only_loaded[userId] = PlayerData.new(profile)
   self._view_only_loading[userId] = nil

   return self._view_only_loaded[userId]
end

function PlayerDataManager:DeletePlayerData(userId: number | string): boolean
   if not _G.PLAYERDATAMANAGER_INITIALIZED then return false end 

   userId = tostring(userId)

   if not self._profile_store then
      fetchProfileStore()
   end

   return self._profile_store:WipeProfileAsync(userId)
end

function PlayerDataManager:CreateLeaderstats(player: Player, leaderstatsData: {LeaderstatData})
   if not _G.PLAYERDATAMANAGER_INITIALIZED then return end 

   if player:FindFirstChild("leaderstats") then return end
   
   local janitor = Janitor.new()

   local leaderstats = Instance.new("Folder")
   leaderstats.Name = "leaderstats"
   leaderstats.Parent = player

   local playerData = self:GetPlayerData(player.UserId)
   local toUpdate = {}
   local valueParsers = {}

   for _, data in ipairs(leaderstatsData) do 
      local leaderstatsName = data.Name
      local key = data.Key
      local valueType = data.Type

      valueParsers[key] = data.Parser or function(v)
         return v
      end

      local ins: StringValue = Instance.new(valueType or "StringValue")
      ins.Name = leaderstatsName
      ins.Value = valueParsers[key](playerData:GetValue(key))
      ins.Parent = leaderstats 
   
      ins.Destroying:Connect(function()
         toUpdate[key] = nil
         valueParsers[key] = nil
      end)

      toUpdate[key] = ins
   end

   janitor:Add(leaderstats)
   janitor:LinkToInstance(leaderstats)

   janitor:Add(playerData.Changed:Connect(function(key, newValue)
      if toUpdate[key] then
         toUpdate[key].Value = valueParsers[key](newValue)
      end
   end))

   return janitor
end

function PlayerDataManager:GetGlobalLeaderboard(dataKey: string)
   if not _G.PLAYERDATAMANAGER_INITIALIZED then return end 

   if self._global_leaderboards[dataKey] then
      return self._global_leaderboards[dataKey]
   end

   local version = game.PlaceId ==  _G.PLAYERDATAMANAGER_CONFIGURATION.TESTING_PLACE_ID and  _G.PLAYERDATAMANAGER_CONFIGURATION.TESTING_DATA_VERSION or  _G.PLAYERDATAMANAGER_CONFIGURATION.DATA_VERSION

   local key = "PDM-" .. dataKey .. "@" .. version

   if #key > 50 then
      error("Maximum key length is 50 characters for DataStore name. " .. dataKey .. " is " .. #key .. " characters long.")
   end

   local orderedDataStore = DataStoreService:GetOrderedDataStore(key)

   local globalLeaderboard = GlobalLeaderboard.new(dataKey, orderedDataStore, self._loaded)

   self._global_leaderboards[dataKey] = globalLeaderboard

   return globalLeaderboard
end


return PlayerDataManager