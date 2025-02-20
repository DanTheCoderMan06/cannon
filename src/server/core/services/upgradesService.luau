local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local serverPackages = ServerStorage.serverPackages

local Players = game:GetService("Players")
local FriendService = game:GetService("FriendService")

local upgradesService = {}

local Sift = require(sharedPackages.Sift)

local dataService = require(ServerStorage.server.services.dataService)

local zap = require(ServerStorage.zap)

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local floorConfig = require(ReplicatedStorage.shared.config.floorConfig)
local gamepassConfig = require(ReplicatedStorage.shared.config.gamepassConfig)
local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)
local tierConfig = require(ReplicatedStorage.shared.config.tierConfig)

local castleService = require(ServerStorage.server.services.castleService)
local cannonService = require(ServerStorage.server.services.cannonService)

function upgradesService.upgradeTier(player, tierName, target)
	local playerData = dataService.getPlayerData(player)
	if playerData[tierName] < target - 1 then
		player:Kick("Anti-Exploit: You were kicked for buying a dev product you weren't meant to buy.")
		return
	end
	playerData[tierName] = target
	dataService.updatePlayerData(player, playerData)
	task.defer(function()
		cannonService.addCannon(player, cannonConfig.getCannon(playerData.cannon))
	end)
end

function upgradesService.handlePurchase(recieptInfo)
	local player = Players:GetPlayerByUserId(recieptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	for name, info in pairs(gamepassConfig) do
		if info.id == recieptInfo.ProductId then
			info.callback(player)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	for name, cannonTier in pairs(tierConfig.cannonTiers) do
		if cannonTier.id == recieptInfo.ProductId then
			task.defer(function()
				upgradesService.upgradeTier(player, "cannonTier", cannonTier.tier)
			end)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function upgradesService.start()
	MarketplaceService.ProcessReceipt = function(recieptInfo)
		return upgradesService.handlePurchase(recieptInfo)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then
			return
		end
		upgradesService.handlePurchase({
			PlayerId = player.UserId,
			ProductId = gamePassId,
		})
	end)

	zap.purchaseUpgrade.SetCallback(function(player, purchaseType)
		local playerData = dataService.getPlayerData(player)
		local cost = purchaseType == "cannon"
				and cannonConfig.costFormula(playerData.cannon + 1, playerData.boughtLevels)
			or floorConfig.costFormula(playerData.floors + 1, playerData.boughtFloors)

		if playerData.money < cost then
			return false
		end

		playerData.money -= cost

		if purchaseType == "cannon" then
			playerData.cannon += 1
			dataService.updatePlayerData(player, playerData)
			cannonService.addCannon(player, cannonConfig.getCannon(playerData.cannon))
		else
			playerData.floors += 1
			dataService.updatePlayerData(player, playerData)
			castleService.updateTower(player)
		end

		return true
	end)

	zap.claimDailyReward.SetCallback(function(player, rewardDay)
		local info = rewardsConfig.getDailyReward(rewardDay)
		if not info then
			return
		end
		local playerData = dataService.getPlayerData(player)
		print(playerData.daysPlayed)
		if playerData.daysPlayed < rewardDay then
			print(playerData.daysPlayed)
			return
		end
		if table.find(playerData.daysClaimed, rewardDay) then
			return
		end
		info.callback(playerData, player)
		table.insert(playerData.daysClaimed, rewardDay)
		task.defer(function()
			dataService.updatePlayerData(player, playerData)
		end)
	end)
end

return upgradesService
