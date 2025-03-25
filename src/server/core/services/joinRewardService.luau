local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local playerBase = DataStoreService:GetDataStore("playerBase")
local dataService = require(ServerStorage.server.services.dataService)

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

local joinService = {}

local function pcallFunction(callback)
	if RunService:IsStudio() then
		callback()
		return
	end
	local s, r = pcall(callback)

	while not s do
		task.wait(1)
		warn(r .. " RETRYING.")
		s, r = pcall(callback)
	end
end

function joinService.canGetReward(joined: number, referrer: number)
	local referrerData = dataService.getGlobalPlayerData(referrer)
	local lastReferred = referrerData.Data.invitedPlayers[joined]
	if not lastReferred then
		lastReferred = 0
	end
	if os.time() - lastReferred < rewardsConfig.referWaitTime then
		return false
	end
	if Players:GetPlayerByUserId(referrer) then
		dataService.updatePlayerData(Players:GetPlayerByUserId(referrer), referrerData)
	end
	return true
end

local function rewardReferrer(ref)
	if Players:GetPlayerByUserId(ref) then
		local targetPlayer = Players:GetPlayerByUserId(tonumber(ref))
		local profileData = dataService.getPlayerData(targetPlayer)

		profileData.money = (profileData.money or 0) + rewardsConfig.playerJoinReward(profileData.cannon)
		dataService.updatePlayerData(targetPlayer, profileData)
		print("[joinRewardService]: Rewarded referrer " .. ref .. " with 50 money! IN GAME")
	else
		local profileData = dataService.getGlobalPlayerData(ref)
		profileData.money = (profileData.money or 0) + rewardsConfig.playerJoinReward(profileData.cannon)

		dataService.overwriteUserData(profileData)
		print("[joinRewardService]: Rewarded referrer " .. ref .. " with 50 money! OFFLINE")
	end
end

local function onPlayerAdded(player)
	local joinData = player:GetJoinData()
	if joinData and joinData.ReferredByPlayerId then
		local referrerId = joinData.ReferredByPlayerId
		if not referrerId or referrerId == 0 then
			return
		end
		if not joinService.canGetReward(player.UserId, referrerId) then
			return
		end
		print("REFERERD BY :" .. referrerId)
		rewardReferrer(referrerId)
		player:SetAttribute("ReferralRewarded", true)
	end
end

function joinService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)

	pcallFunction(function()
		MessagingService:SubscribeAsync("joinReward", function(msg)
			local targetPlayer = Players:GetPlayerByUserId(tonumber(msg.Data))
			local profileData = dataService.getPlayerData(targetPlayer)
			profileData.money = (profileData.money or 0) + rewardsConfig.playerJoinReward(profileData.cannon)
			dataService.updatePlayerData(targetPlayer, profileData)
		end)
	end)
end

return joinService
