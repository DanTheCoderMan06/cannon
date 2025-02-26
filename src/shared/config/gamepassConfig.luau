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
	tenFloorsTier2 = {
		id = 3218172172,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			playerData.floors += 10
			playerData.boughtFloors += 10
			playerData.productTiers.products["floors"] += 1
			dataService.updatePlayerData(player, playerData)
			castleService.updateTower(player)
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		shouldAppear = false,
	},
	fiftyFloorsTier2 = {
		id = 3218172192,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			playerData.floors += 50
			playerData.boughtFloors += 50
			playerData.productTiers.products["floors"] += 1
			dataService.updatePlayerData(player, playerData)
			castleService.updateTower(player)
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		shouldAppear = false,
	},
	tenFloors = {
		id = 2697043460,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			if playerData.productTiers.products["floors"] then
				if playerData.productTiers.products["floors"] >= 5 then
					return
				end
			end
			playerData.floors += 10
			playerData.boughtFloors += 10
			playerData.productTiers.products["floors"] = playerData.productTiers.products["floors"] or 0
			playerData.productTiers.products["floors"] += 1
			dataService.updatePlayerData(player, playerData)
			castleService.updateTower(player)
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		tiers = true,
		tier2Name = "tenFloorsTier2",
	},
	fiftyFloors = {
		id = 2697043455,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			if playerData.productTiers.products["floors"] then
				if playerData.productTiers.products["floors"] >= 5 then
					return
				end
			end
			playerData.floors += 50
			playerData.boughtFloors += 50
			playerData.productTiers.products["floors"] = playerData.productTiers.products["floors"] or 0
			playerData.productTiers.products["floors"] += 1
			dataService.updatePlayerData(player, playerData)
			castleService.updateTower(player)
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		tiers = true,
		tier2Name = "fiftyFloorsTier2",
	},
	twoHundredFiftyFloors = {
		id = 3220619326,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			if playerData.productTiers.products["floors"] then
				if playerData.productTiers.products["floors"] >= 5 then
					return
				end
			end
			playerData.floors += 250
			playerData.boughtFloors += 250
			playerData.productTiers.products["floors"] = playerData.productTiers.products["floors"] or 0
			playerData.productTiers.products["floors"] += 1
			dataService.updatePlayerData(player, playerData)
			castleService.updateTower(player)
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		tiers = true,
		tier2Name = "twoHundredFiftyFloorsTier2",
	},
	twoHundredFiftyFloorsTier2 = {
		id = 3220619459,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			playerData.floors += 250
			playerData.boughtFloors += 250
			playerData.productTiers.products["floors"] += 1
			dataService.updatePlayerData(player, playerData)
			castleService.updateTower(player)
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		shouldAppear = false,
	},
	buyCircusCannon = {
		id = 1051314279,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			marketplaceUtil.updatePlayerCache(player, 1051314279)
			table.insert(playerData.cannons, "circusCannon")
			dataService.updatePlayerData(player, playerData)
		end,
		type = "cannons",
		infoType = Enum.InfoType.GamePass,
		cannonName = "circusCannon",
	},
	buyArmyCannon = {
		id = 1051600321,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			marketplaceUtil.updatePlayerCache(player, 1051600321)
			table.insert(playerData.cannons, "armyCannon")
			dataService.updatePlayerData(player, playerData)
		end,
		type = "cannons",
		infoType = Enum.InfoType.GamePass,
		cannonName = "armyCannon",
	},
	buyArtillery = {
		id = 1028783141,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			marketplaceUtil.updatePlayerCache(player, 1028783141)
			table.insert(playerData.cannons, "artillery")
			dataService.updatePlayerData(player, playerData)
		end,
		type = "cannons",
		infoType = Enum.InfoType.GamePass,
		cannonName = "artillery",
	},
	buyRailgun = {
		id = 1035960145,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			marketplaceUtil.updatePlayerCache(player, 1035960145)
			table.insert(playerData.cannons, "railgun")
			dataService.updatePlayerData(player, playerData)
		end,
		type = "cannons",
		infoType = Enum.InfoType.GamePass,
		cannonName = "railgun",
	},
	buyVIP = {
		id = 1060138098,
		callback = function(player)
			marketplaceUtil.updatePlayerCache(player, 1060138098)
		end,
		type = "gamepasses",
		infoType = Enum.InfoType.GamePass,
	},
	newCannon = {
		id = 2697043453,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			local newCannon = cannonConfig.getNextCannon(player.cannon)
			playerData.cannon = newCannon.max
			dataService.updatePlayerData(player, playerData)
		end,
		type = "cannons",
		infoType = Enum.InfoType.Product,
	},
	artilleryGamepasses = {
		["1028783141"] = "artillery",
		["1035960145"] = "railgun",
		["1051600321"] = "armyCannon",
		["1051314279"] = "circusCannon",
	},
}
