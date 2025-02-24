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
		tier2Name = "tenFloorsTier2",
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
			task.defer(function()
				dataService.updatePlayerData(player, targetPlayerData)
				castleService.updateTower(target)
				if player ~= target then
					task.defer(function()
						dataService.updatePlayerData(player, playerData)
					end)
				end
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
			task.defer(function()
				dataService.updatePlayerData(target, targetPlayerData)
				castleService.updateTower(target)
				if player ~= target then
					task.defer(function()
						dataService.updatePlayerData(player, playerData)
					end)
				end
			end)
		end,
		shouldAppear = false,
		check = function(targetPlayer)
			return true
		end,
	},
	fiftyFloors = {
		id = 3224502320,
		shouldAppear = true,
		tiers = true,
		tier2Name = "fiftyFloorsTier2",
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			if playerData.productTiers.gifts["fiftyFloors"] and playerData.productTiers.gifts["fiftyFloors"] >= 5 then
				return
			end
			playerData.productTiers.gifts["fiftyFloors"] = playerData.productTiers.gifts["fiftyFloors"] or 0
			playerData.productTiers.gifts["fiftyFloors"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.floors += 50
			targetPlayerData.boughtFloors += 50
			task.defer(function()
				dataService.updatePlayerData(player, targetPlayerData)
				castleService.updateTower(target)
				if player ~= target then
					task.defer(function()
						dataService.updatePlayerData(player, playerData)
					end)
				end
			end)
		end,
		check = function(targetPlayer)
			return true
		end,
	},
	fiftyFloorsTier2 = {
		id = 3224502578,
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			playerData.productTiers.gifts["fiftyFloors"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.floors += 50
			targetPlayerData.boughtFloors += 50
			task.defer(function()
				dataService.updatePlayerData(target, targetPlayerData)
				castleService.updateTower(target)
				if player ~= target then
					task.defer(function()
						dataService.updatePlayerData(player, playerData)
					end)
				end
			end)
		end,
		shouldAppear = false,
		check = function(targetPlayer)
			return true
		end,
	},
	twoHundredFifty = {
		id = 3224504001,
		shouldAppear = true,
		tiers = true,
		tier2Name = "twoHundredFiftyTier2",
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			if
				playerData.productTiers.gifts["twoHundredFifty"]
				and playerData.productTiers.gifts["twoHundredFifty"] >= 5
			then
				return
			end
			playerData.productTiers.gifts["twoHundredFifty"] = playerData.productTiers.gifts["twoHundredFifty"] or 0
			playerData.productTiers.gifts["twoHundredFifty"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.floors += 250
			targetPlayerData.boughtFloors += 250
			task.defer(function()
				dataService.updatePlayerData(player, targetPlayerData)
				castleService.updateTower(target)
				if player ~= target then
					task.defer(function()
						dataService.updatePlayerData(player, playerData)
					end)
				end
			end)
		end,
		check = function(targetPlayer)
			return true
		end,
	},
	twoHundredFiftyTier2 = {
		id = 3224504000,
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			playerData.productTiers.gifts["twoHundredFifty"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.floors += 250
			targetPlayerData.boughtFloors += 250
			task.defer(function()
				dataService.updatePlayerData(target, targetPlayerData)
				castleService.updateTower(target)
				if player ~= target then
					task.defer(function()
						dataService.updatePlayerData(player, playerData)
					end)
				end
			end)
		end,
		shouldAppear = false,
		check = function(targetPlayer)
			return true
		end,
	},
}
