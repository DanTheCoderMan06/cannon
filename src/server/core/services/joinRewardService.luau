local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local playerBase = DataStoreService:GetDataStore("playerBase")
local dataService = require(ServerStorage.server.services.dataService)

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

local joinService = {}

function joinService.playerExists(userid: number)
	local data
	local S, R = pcall(function()
		data = playerBase:GetAsync(userid)
	end)
	if not S then
		return false
	end
	return data ~= nil
end

local function rewardReferrer(ref)
	local profileData
	if typeof(ref) == "Instance" then
		profileData = dataService.getPlayerData(ref)
		profileData.money = (profileData.money or 0) + rewardsConfig.playerJoinReward
		dataService.updatePlayerData(ref, profileData)
		print("Rewarded referrer " .. ref.Name .. " with 50 money!")
	elseif typeof(ref) == "number" then
		profileData = dataService.getGlobalPlayerData(ref)
		profileData.money = (profileData.money or 0) + rewardsConfig.playerJoinReward
		dataService.overwriteUserData(profileData)
		print("Rewarded referrer with userId " .. tostring(ref) .. " with 50 money!")
	end
end

local function onPlayerAdded(player)
	local joinData = player:GetJoinData()
	if joinData and joinData.ReferredByPlayerId and not joinService.playerExists(player.UserId) then
		local referrerId = joinData.ReferredByPlayerId
		local referrer = Players:GetPlayerByUserId(referrerId)
		rewardReferrer(referrer or referrerId)
		player:SetAttribute("ReferralRewarded", true)
	end
end

function joinService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
end

return joinService
