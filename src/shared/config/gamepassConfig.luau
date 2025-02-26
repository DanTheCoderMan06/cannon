local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage
local dataService
local castleService
local luckyBlockService

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)
local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

if RunService:IsServer() then
	ServerStorage = game:GetService("ServerStorage")
	luckyBlockService = require(ServerStorage.server.services.luckyBlockService)
	dataService = require(ServerStorage.server.services.dataService)
	castleService = require(ServerStorage.server.services.castleService)
end

return {
	luckyBlockSkip = {
		floorTiers = true,
		id = {
			3225913162, -- Tier 1: Floors 1-49
			3225913163, -- Tier 2: Floors 50-99
			3225913164, -- Tier 3: Floors 100-149
			3225913165, -- Tier 4: Floors 150-199
			3225913166, -- Tier 5: Floors 200+
		},
		getId = function(playerData)
			local tierRanges = {
				{ min = 1, max = 49 }, -- Tier 1
				{ min = 50, max = 99 }, -- Tier 2
				{ min = 100, max = 149 }, -- Tier 3
				{ min = 150, max = 199 }, -- Tier 4
				{ min = 200, max = math.huge }, -- Tier 5
			}

			local ids = {
				3225913162, -- Tier 1: Floors 1-49
				3225913163, -- Tier 2: Floors 50-99
				3225913164, -- Tier 3: Floors 100-149
				3225913165, -- Tier 4: Floors 150-199
				3225913166, -- Tier 5: Floors 200+
			}

			local playerTier = 1
			for i, range in ipairs(tierRanges) do
				if playerData.floors >= range.min and playerData.floors <= range.max then
					return ids[i]
				end
			end

			return 0
		end,
		callback = function(player, productId)
			local tierRanges = {
				{ min = 1, max = 49 }, -- Tier 1
				{ min = 50, max = 99 }, -- Tier 2
				{ min = 100, max = 149 }, -- Tier 3
				{ min = 150, max = 199 }, -- Tier 4
				{ min = 200, max = math.huge }, -- Tier 5
			}

			local ids = {
				3225913162, -- Tier 1: Floors 1-49
				3225913163, -- Tier 2: Floors 50-99
				3225913164, -- Tier 3: Floors 100-149
				3225913165, -- Tier 4: Floors 150-199
				3225913166, -- Tier 5: Floors 200+
			}

			local playerData = dataService.getPlayerData(player)

			local playerTier = 1
			for i, range in ipairs(tierRanges) do
				if playerData.floors >= range.min and playerData.floors <= range.max then
					playerTier = i
					break
				end
			end

			local purchasedTier = nil
			for i, id in ipairs(ids) do
				if id == productId then
					purchasedTier = i
					break
				end
			end

			if purchasedTier ~= playerTier then
				print(
					"[PurchasesService]: Player tried to use incorrect tier product. Expected tier: "
						.. playerTier
						.. ", got tier: "
						.. tostring(purchasedTier)
				)
				return
			end

			luckyBlockService.resetPlayerTimer(player)
		end,
		speicalFloorTiers = true,
		type = "gamepasses",
		infoType = Enum.InfoType.Product,
		shouldAppear = true,
	},
	allRewardsWhale = {
		id = 3225912732,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			if playerData.productTiers.products["allRewards"] then
				if playerData.productTiers.products["allRewards"] >= 5 then
					return
				end
			end
			for _, reward in pairs(rewardsConfig.rewards) do
				reward.callback(playerData, player)
			end
			playerData.daysPlayed = 0
			playerData.daysClaimed = {}
			playerData.lastClaimed = os.time()
			playerData.productTiers.products["allRewards"] = playerData.productTiers.products["allRewards"] or 0
			playerData.productTiers.products["allRewards"] += 1
			print(playerData)
			task.defer(function()
				dataService.updatePlayerData(player, playerData)
			end)
		end,
		type = "gamepasses",
		infoType = Enum.InfoType.Product,
		shouldAppear = true,
		tiers = true,
		tier2Name = "allRewardsWhaleTier2",
	},

	allRewardsWhaleTier2 = {
		id = 3225913161,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			for _, reward in pairs(rewardsConfig.rewards) do
				reward.callback(playerData, player)
			end
			playerData.daysPlayed = 0
			playerData.daysClaimed = {}
			playerData.lastClaimed = os.time()
			playerData.productTiers.products["allRewards"] += 1
			dataService.updatePlayerData(player, playerData)
		end,
		type = "gamepasses",
		infoType = Enum.InfoType.Product,
		shouldAppear = false,
	},
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
