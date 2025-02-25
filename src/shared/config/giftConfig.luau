local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage
local dataService
local castleService

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)
local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

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
	doubleDistance = {
		id = 3224600930,
		shouldAppear = true,
		tiers = true,
		tier2Name = "doubleDistanceTier2",
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			if
				playerData.productTiers.gifts["doubleDistance"]
				and playerData.productTiers.gifts["doubleDistance"] >= 5
			then
				return
			end
			playerData.productTiers.gifts["doubleDistance"] = playerData.productTiers.gifts["doubleDistance"] or 0
			playerData.productTiers.gifts["doubleDistance"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.doubleDistance = true
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
			local playerData = dataService.getPlayerData(targetPlayer)
			if playerData.doubleDistance then
				return false
			end
			return true
		end,
	},
	doubleDistanceTier2 = {
		id = 3224600931,
		shouldAppear = false,
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			playerData.productTiers.gifts["doubleDistance"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.doubleDistance = true
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
			local playerData = dataService.getPlayerData(targetPlayer)
			if playerData.doubleDistance then
				return false
			end
			return true
		end,
	},
	doubleMoney = {
		id = 3224601898,
		shouldAppear = true,
		tiers = true,
		tier2Name = "doubleMoneyTier2",
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			if playerData.productTiers.gifts["doubleMoney"] and playerData.productTiers.gifts["doubleMoney"] >= 5 then
				return
			end
			playerData.productTiers.gifts["doubleMoney"] = playerData.productTiers.gifts["doubleMoney"] or 0
			playerData.productTiers.gifts["doubleMoney"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.doubleMoney = true
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
			local playerData = dataService.getPlayerData(targetPlayer)
			if playerData.doubleMoney then
				return false
			end
			return true
		end,
	},
	doubleMoneyTier2 = {
		id = 3224601897,
		shouldAppear = false,
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			playerData.productTiers.gifts["doubleMoney"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.doubleMoney = true
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
			local playerData = dataService.getPlayerData(targetPlayer)
			if playerData.doubleMoney then
				return false
			end
			return true
		end,
	},
	giveVIP = {
		id = 3224616084,
		shouldAppear = true,
		tiers = true,
		tier2Name = "giveVIPTier2",
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			if playerData.productTiers.gifts["giveVIP"] and playerData.productTiers.gifts["giveVIP"] >= 5 then
				return
			end
			playerData.productTiers.gifts["giveVIP"] = playerData.productTiers.gifts["giveVIP"] or 0
			playerData.productTiers.gifts["giveVIP"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.infiniteVIP = true
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
			local playerData = dataService.getPlayerData(targetPlayer)
			if playerData.infiniteVIP or marketplaceUtil.userOwnsGamepass(targetPlayer, rewardsConfig.vipGamepass) then
				return false
			end
			return true
		end,
	},
	giveVIPTier2 = {
		id = 3224616147,
		shouldAppear = false,
		callback = function(player, target)
			local playerData = dataService.getPlayerData(player)
			playerData.productTiers.gifts["giveVIP"] += 1
			local targetPlayerData = dataService.getPlayerData(target)
			targetPlayerData.infiniteVIP = true
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
			local playerData = dataService.getPlayerData(targetPlayer)
			if playerData.infiniteVIP or marketplaceUtil.userOwnsGamepass(targetPlayer, rewardsConfig.vipGamepass) then
				return false
			end
			return true
		end,
	},
}
