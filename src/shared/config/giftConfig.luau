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
		type = "floors",
		callback = function(player, target)
			-- If player is gifting themselves, use a single data operation
			if player == target then
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["floors"] and playerData.productTiers.gifts["floors"] >= 5 then
					return
				end
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 0
				playerData.productTiers.gifts["floors"] += 1
				playerData.floors += 10
				playerData.boughtFloors += 10

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
					castleService.updateTower(player)
				end)
			else
				-- Traditional flow for gifting another player
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["floors"] and playerData.productTiers.gifts["floors"] >= 5 then
					return
				end
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 0
				playerData.productTiers.gifts["floors"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				targetPlayerData.floors += 10
				targetPlayerData.boughtFloors += 10

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					castleService.updateTower(target)
					dataService.updatePlayerData(player, playerData)
				end)
			end
		end,
		check = function(targetPlayer)
			return true
		end,
	},
	tenFloorsTier2 = {
		type = "floors",
		id = 3223017209,
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] += 1
				playerData.floors += 10
				playerData.boughtFloors += 10

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
					castleService.updateTower(player)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				targetPlayerData.floors += 10
				targetPlayerData.boughtFloors += 10

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					castleService.updateTower(target)
					dataService.updatePlayerData(player, playerData)
				end)
			end
		end,
		shouldAppear = false,
		check = function(targetPlayer)
			return true
		end,
	},
	fiftyFloors = {
		id = 3224502320,
		type = "floors",
		shouldAppear = true,
		tiers = true,
		tier2Name = "fiftyFloorsTier2",
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["floors"] and playerData.productTiers.gifts["floors"] >= 5 then
					return
				end
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 0
				playerData.productTiers.gifts["floors"] += 1
				playerData.floors += 50
				playerData.boughtFloors += 50

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
					castleService.updateTower(player)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["floors"] and playerData.productTiers.gifts["floors"] >= 5 then
					return
				end
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 0
				playerData.productTiers.gifts["floors"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				targetPlayerData.floors += 50
				targetPlayerData.boughtFloors += 50

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					castleService.updateTower(target)
					dataService.updatePlayerData(player, playerData)
				end)
			end
		end,
		check = function(targetPlayer)
			return true
		end,
	},
	fiftyFloorsTier2 = {
		id = 3224502578,
		type = "floors",
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] += 1
				playerData.floors += 50
				playerData.boughtFloors += 50

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
					castleService.updateTower(player)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				targetPlayerData.floors += 50
				targetPlayerData.boughtFloors += 50

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					castleService.updateTower(target)
					dataService.updatePlayerData(player, playerData)
				end)
			end
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
		type = "floors",
		tier2Name = "twoHundredFiftyTier2",
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["floors"] and playerData.productTiers.gifts["floors"] >= 5 then
					return
				end
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 0
				playerData.productTiers.gifts["floors"] += 1
				playerData.floors += 250
				playerData.boughtFloors += 250

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
					castleService.updateTower(player)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["floors"] and playerData.productTiers.gifts["floors"] >= 5 then
					return
				end
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 0
				playerData.productTiers.gifts["floors"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				targetPlayerData.floors += 250
				targetPlayerData.boughtFloors += 250

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					castleService.updateTower(target)
					dataService.updatePlayerData(player, playerData)
				end)
			end
		end,
		check = function(targetPlayer)
			return true
		end,
	},
	twoHundredFiftyTier2 = {
		id = 3224504000,
		type = "floors",
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] += 1
				playerData.floors += 250
				playerData.boughtFloors += 250

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
					castleService.updateTower(player)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				targetPlayerData.floors += 250
				targetPlayerData.boughtFloors += 250

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					castleService.updateTower(target)
					dataService.updatePlayerData(player, playerData)
				end)
			end
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
		type = "gamepasses",
		tier2Name = "doubleDistanceTier2",
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				if
					playerData.productTiers.gifts["doubleDistance"]
					and playerData.productTiers.gifts["doubleDistance"] >= 5
				then
					return
				end
				playerData.productTiers.gifts["doubleDistance"] = playerData.productTiers.gifts["doubleDistance"] or 0
				playerData.productTiers.gifts["doubleDistance"] += 1
				playerData.doubleDistance = true

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
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
					dataService.updatePlayerData(target, targetPlayerData)
					dataService.updatePlayerData(player, playerData)
				end)
			end
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
		type = "gamepasses",
		shouldAppear = false,
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["doubleDistance"] += 1
				playerData.doubleDistance = true

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["doubleDistance"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				targetPlayerData.doubleDistance = true

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					dataService.updatePlayerData(player, playerData)
				end)
			end
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
		type = "gamepasses",
		tier2Name = "doubleMoneyTier2",
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				if
					playerData.productTiers.gifts["doubleMoney"]
					and playerData.productTiers.gifts["doubleMoney"] >= 5
				then
					return
				end
				playerData.productTiers.gifts["doubleMoney"] = playerData.productTiers.gifts["doubleMoney"] or 0
				playerData.productTiers.gifts["doubleMoney"] += 1
				playerData.doubleMoney = true

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				if
					playerData.productTiers.gifts["doubleMoney"]
					and playerData.productTiers.gifts["doubleMoney"] >= 5
				then
					return
				end
				playerData.productTiers.gifts["doubleMoney"] = playerData.productTiers.gifts["doubleMoney"] or 0
				playerData.productTiers.gifts["doubleMoney"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				targetPlayerData.doubleMoney = true

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					dataService.updatePlayerData(player, playerData)
				end)
			end
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
		type = "gamepasses",
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["doubleMoney"] += 1
				playerData.doubleMoney = true

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["doubleMoney"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				targetPlayerData.doubleMoney = true

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					dataService.updatePlayerData(player, playerData)
				end)
			end
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
		type = "gamepasses",
		tier2Name = "giveVIPTier2",
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["giveVIP"] and playerData.productTiers.gifts["giveVIP"] >= 5 then
					return
				end
				playerData.productTiers.gifts["giveVIP"] = playerData.productTiers.gifts["giveVIP"] or 0
				playerData.productTiers.gifts["giveVIP"] += 1
				playerData.infiniteVIP = true

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["giveVIP"] and playerData.productTiers.gifts["giveVIP"] >= 5 then
					return
				end
				playerData.productTiers.gifts["giveVIP"] = playerData.productTiers.gifts["giveVIP"] or 0
				playerData.productTiers.gifts["giveVIP"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				targetPlayerData.infiniteVIP = true

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					dataService.updatePlayerData(player, playerData)
				end)
			end
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
		type = "gamepasses",
		shouldAppear = false,
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["giveVIP"] += 1
				playerData.infiniteVIP = true

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["giveVIP"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				targetPlayerData.infiniteVIP = true

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					dataService.updatePlayerData(player, playerData)
				end)
			end
		end,
		check = function(targetPlayer)
			local playerData = dataService.getPlayerData(targetPlayer)
			if playerData.infiniteVIP or marketplaceUtil.userOwnsGamepass(targetPlayer, rewardsConfig.vipGamepass) then
				return false
			end
			return true
		end,
	},
	giftArtillery = {
		id = 3224676081,
		shouldAppear = true,
		tiers = true,
		type = "cannons",
		tier2Name = "giftArtilleryTier2",
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["cannons"] and playerData.productTiers.gifts["cannons"] >= 5 then
					return
				end
				playerData.productTiers.gifts["cannons"] = playerData.productTiers.gifts["cannons"] or 0
				playerData.productTiers.gifts["cannons"] += 1
				table.insert(playerData.cannons, "artillery")

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["cannons"] and playerData.productTiers.gifts["cannons"] >= 5 then
					return
				end
				playerData.productTiers.gifts["cannons"] = playerData.productTiers.gifts["cannons"] or 0
				playerData.productTiers.gifts["cannons"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				table.insert(targetPlayerData.cannons, "artillery")

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					dataService.updatePlayerData(player, playerData)
				end)
			end
		end,
		check = function(targetPlayer)
			local playerData = dataService.getPlayerData(targetPlayer)
			if table.find(playerData.cannons, "artillery") then
				return false
			end
			return true
		end,
	},
	giftArtilleryTier2 = {
		id = 3224676143,
		type = "cannons",
		shouldAppear = false,
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["cannons"] += 1
				table.insert(playerData.cannons, "artillery")

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["cannons"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				table.insert(targetPlayerData.cannons, "artillery")

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					dataService.updatePlayerData(player, playerData)
				end)
			end
		end,
		check = function(targetPlayer)
			local playerData = dataService.getPlayerData(targetPlayer)
			if table.find(playerData.cannons, "artillery") then
				return false
			end
			return true
		end,
	},
	giftRailgun = {
		id = 3225217016,
		shouldAppear = true,
		tiers = true,
		type = "cannons",
		tier2Name = "giftRailgunTier2",
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["cannons"] and playerData.productTiers.gifts["cannons"] >= 5 then
					return
				end
				playerData.productTiers.gifts["cannons"] = playerData.productTiers.gifts["cannons"] or 0
				playerData.productTiers.gifts["cannons"] += 1
				table.insert(playerData.cannons, "railgun")

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["cannons"] and playerData.productTiers.gifts["cannons"] >= 5 then
					return
				end
				playerData.productTiers.gifts["cannons"] = playerData.productTiers.gifts["cannons"] or 0
				playerData.productTiers.gifts["cannons"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				table.insert(targetPlayerData.cannons, "railgun")

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					dataService.updatePlayerData(player, playerData)
				end)
			end
		end,
		check = function(targetPlayer)
			local playerData = dataService.getPlayerData(targetPlayer)
			if table.find(playerData.cannons, "railgun") then
				return false
			end
			return true
		end,
	},
	giftRailgunTier2 = {
		id = 3225217064,
		type = "cannons",
		shouldAppear = false,
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["cannons"] += 1
				table.insert(playerData.cannons, "railgun")

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["cannons"] += 1

				local targetPlayerData = dataService.getPlayerData(target)
				table.insert(targetPlayerData.cannons, "railgun")

				task.defer(function()
					dataService.updatePlayerData(target, targetPlayerData)
					dataService.updatePlayerData(player, playerData)
				end)
			end
		end,
		check = function(targetPlayer)
			local playerData = dataService.getPlayerData(targetPlayer)
			if table.find(playerData.cannons, "railgun") then
				return false
			end
			return true
		end,
	},
}
