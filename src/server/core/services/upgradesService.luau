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

local castleService = require(ServerStorage.server.services.castleService)
local cannonService = require(ServerStorage.server.services.cannonService)

function upgradesService.start()
	MarketplaceService.ProcessReceipt = function(recieptInfo)
		local player = Players:GetPlayerByUserId(recieptInfo.PlayerId)

		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		print(recieptInfo)

		for name, info in pairs(gamepassConfig) do
			if info.id == recieptInfo.ProductId then
				info.callback(player)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

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
end

return upgradesService
