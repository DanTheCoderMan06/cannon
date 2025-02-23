local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage
local dataService
local castleService

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)

if RunService:IsServer() then
	ServerStorage = game:GetService("ServerStorage")
	dataService = require(ServerStorage.server.services.dataService)
	castleService = require(ServerStorage.server.services.castleService)
end

return {
	tenFloors = {
		id = 3221610346,
		shouldAppear = true,
		tiers = true,
		tier2 = "tenFloorsTier2",
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			if playerData.productTiers.gifts["tenFloors"] and playerData.productTiers.gifts["tenFloors"] >= 5 then
				return
			end
			playerData.productTiers.gifts["tenFloors"] = playerData.productTiers.gifts["tenFloors"] or 0
			playerData.productTiers.gifts["tenFloors"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.floors += 10
			targetPlayerData.boughtFloors += 10
			dataService.updatePlayerData(player, playerData)
			task.defer(function()
				dataService.updatePlayerData(player, targetPlayerData)
				castleService.updateTower(target)
			end)
		end,
		check = function(targetPlayer)
			return true
		end,
	},
	tenFloorsTier2 = {
		id = 3223017209,
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			playerData.productTiers.gifts["tenFloors"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.floors += 10
			targetPlayerData.boughtFloors += 10
			dataService.updatePlayerData(player, playerData)
			task.defer(function()
				dataService.updatePlayerData(target, targetPlayerData)
				castleService.updateTower(target)
			end)
		end,
		shouldAppear = false,
		check = function(targetPlayer)
			return true
		end,
	},
}
