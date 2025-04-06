local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage
local dataService
local castleService
local luckyBlockService
local cannonService

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)
local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

if RunService:IsServer() then
	ServerStorage = game:GetService("ServerStorage")
	luckyBlockService = require(ServerStorage.server.services.luckyBlockService)
	dataService = require(ServerStorage.server.services.dataService)
	castleService = require(ServerStorage.server.services.castleService)
	cannonService = require(ServerStorage.server.services.cannonService)
end

return {
	luckyBlockSkip = {
		floorTiers = true,
		id = {
			1228168162, -- Tier 1: Floors 1-49 (Skip Timer)
			3101480459, -- Tier 2: Floors 50-99 (Skip Timer II)
			3101497833, -- Tier 3: Floors 100-149 (Skip Timer III)
			3101507555, -- Tier 4: Floors 150-199 (Skip Timer IV)
			3101517491, -- Tier 5: Floors 200+ (Skip Timer V)
		},
		getId = function(playerData)
			local tierRanges = {
				{ min = 0, max = 49 }, -- Tier 1
				{ min = 50, max = 99 }, -- Tier 2
				{ min = 100, max = 149 }, -- Tier 3
				{ min = 150, max = 199 }, -- Tier 4
				{ min = 200, max = math.huge }, -- Tier 5
			}

			local ids = {
				1228168162, -- Tier 1: Floors 1-49 (Skip Timer)
				3101480459, -- Tier 2: Floors 50-99 (Skip Timer II)
				3101497833, -- Tier 3: Floors 100-149 (Skip Timer III)
				3101507555, -- Tier 4: Floors 150-199 (Skip Timer IV)
				3101517491, -- Tier 5: Floors 200+ (Skip Timer V)
			}

			for i, range in ipairs(tierRanges) do
				if playerData.floors >= range.min and playerData.floors <= range.max then
					return ids[i]
				end
			end

			return 0
		end,
		callback = function(player, productId)
			local tierRanges = {
				{ min = 0, max = 49 }, -- Tier 1
				{ min = 50, max = 99 }, -- Tier 2
				{ min = 100, max = 149 }, -- Tier 3
				{ min = 150, max = 199 }, -- Tier 4
				{ min = 200, max = math.huge }, -- Tier 5
			}

			local ids = {
				1228168162, -- Tier 1: Floors 1-49 (Skip Timer)
				3101480459, -- Tier 2: Floors 50-99 (Skip Timer II)
				3101497833, -- Tier 3: Floors 100-149 (Skip Timer III)
				3101507555, -- Tier 4: Floors 150-199 (Skip Timer IV)
				3101517491, -- Tier 5: Floors 200+ (Skip Timer V)
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

			luckyBlockService.spawnLuckyBlock(player)
		end,
		changeOnData = "floors",
		type = "gamepasses",
		infoType = Enum.InfoType.Product,
		shouldAppear = false,
		speicalTiers = true,
	},
	upgradeCannon = {
		id = {
			2691922174, -- Tier 1: Cannon Upgrade 1
			2691922949, -- Tier 2: Cannon Upgrade 2
			2691923019, -- Tier 3: Cannon Upgrade 3
			2691925876, -- Tier 4: Cannon Upgrade 4
			2691925945, -- Tier 5: Cannon Upgrade 5
		},
		getId = function(playerData)
			local tierRanges = {
				{ min = 0, max = 19 }, -- Tier 1
				{ min = 20, max = 39 }, -- Tier 2
				{ min = 40, max = 59 }, -- Tier 3
				{ min = 60, max = 79 }, -- Tier 4
				{ min = 80, max = math.huge }, -- Tier 5
			}

			local ids = {
				2691922174, -- Tier 1: Cannon Upgrade 1
				2691922949, -- Tier 2: Cannon Upgrade 2
				2691923019, -- Tier 3: Cannon Upgrade 3
				2691925876, -- Tier 4: Cannon Upgrade 4
				2691925945, -- Tier 5: Cannon Upgrade 5
			}
			for i, range in ipairs(tierRanges) do
				if playerData.cannon >= range.min and playerData.cannon <= range.max then
					return ids[i]
				end
			end

			return 0
		end,
		callback = function(player, productId)
			local tierRanges = {
				{ min = 0, max = 19 }, -- Tier 1
				{ min = 20, max = 39 }, -- Tier 2
				{ min = 40, max = 59 }, -- Tier 3
				{ min = 60, max = 79 }, -- Tier 4
				{ min = 80, max = math.huge }, -- Tier 5
			}

			local ids = {
				2691922174, -- Tier 1: Cannon Upgrade 1
				2691922949, -- Tier 2: Cannon Upgrade 2
				2691923019, -- Tier 3: Cannon Upgrade 3
				2691925876, -- Tier 4: Cannon Upgrade 4
				2691925945, -- Tier 5: Cannon Upgrade 5
			}

			local playerData = dataService.getPlayerData(player)

			local playerTier = 1
			for i, range in ipairs(tierRanges) do
				if playerData.cannon >= range.min and playerData.cannon <= range.max then
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

			if cannonConfig.maxLevel > playerData.cannon then
				playerData.cannon += 10
				playerData.cannon = math.clamp(playerData.cannon, 0, cannonConfig.maxLevel)
			end

			task.defer(function()
				dataService.updatePlayerData(player, playerData)
				cannonService.addCannon(player, cannonConfig.getCannon(playerData.cannon))
			end)
		end,
		changeOnData = "cannon",
		type = "cannons",
		infoType = Enum.InfoType.Product,
		shouldAppear = false,
		speicalTiers = true,
	},
	allRewardsWhale = {
		id = 3101617187, -- Unlock All Daily Rewards
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			if playerData.productTiers.products["allRewards"] then
				if playerData.productTiers.products["allRewards"] >= 5 then
					return
				end
			end
			for _, reward in pairs(rewardsConfig.rewards) do
				task.wait()
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
		shouldAppear = false,
		tiers = true,
		tier2Name = "allRewardsWhaleTier2",
	},

	allRewardsWhaleTier2 = {
		id = 3101617187, -- Using same ID for now since no specific Tier II ID was provided
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
		id = 2706011527, -- +10 Floors (Tier II)
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			playerData.floors += 10
			playerData.boughtFloors += 10
			playerData.productTiers.products["floors"] += 1
			dataService.updatePlayerData(player, playerData)
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		shouldAppear = false,
	},
	fiftyFloorsTier2 = {
		id = 2706011767, -- +50 Floors (Tier II)
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			playerData.floors += 50
			playerData.boughtFloors += 50
			playerData.productTiers.products["floors"] += 1
			dataService.updatePlayerData(player, playerData)
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		shouldAppear = false,
	},
	tenFloors = {
		id = 2691912508, -- +10 Floors
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
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		tiers = true,
		tier2Name = "tenFloorsTier2",
		--Gift Compatability
		giftName = "tenFloors",
		index = 3,
	},
	fiftyFloors = {
		id = 2691912808, -- +50 Floors
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
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		tiers = true,
		tier2Name = "fiftyFloorsTier2",
		--Gift Compatability
		giftName = "fiftyFloors",
		index = 2,
	},
	twoHundredFiftyFloors = {
		id = 2691913116, -- +250 Floors (BEST DEAL!)
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
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		tiers = true,
		tier2Name = "twoHundredFiftyFloorsTier2",
		--Gift Compatability
		giftName = "twoHundredFifty",
		index = 1,
	},
	twoHundredFiftyFloorsTier2 = {
		id = 2706012109, -- +250 Floors (Tier II)
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			playerData.floors += 250
			playerData.boughtFloors += 250
			playerData.productTiers.products["floors"] += 1
			dataService.updatePlayerData(player, playerData)
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
		shouldAppear = false,
	},
	--[[
	buyCircusCannon = {
		id = 3102291606, -- Special Cannon 1
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			marketplaceUtil.updatePlayerCache(player, 3102291606)
			table.insert(playerData.cannons, "circusCannon")
			dataService.updatePlayerData(player, playerData)
		end,
		type = "cannons",
		infoType = Enum.InfoType.GamePass,
		cannonName = "circusCannon",
		--Gift Compatability
		giftName = "circusCannon",
	},
	--]]
	--[[
	buyArmyCannon = {
		id = 1136518787, -- Army Cannon
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			marketplaceUtil.updatePlayerCache(player, 1136518787)
			table.insert(playerData.cannons, "armyCannon")
			dataService.updatePlayerData(player, playerData)
		end,
		type = "cannons",
		infoType = Enum.InfoType.GamePass,
		cannonName = "armyCannon",
		--Gift Compatability
		--giftName = "giftArmyCannon",
	},
	--]]
	buyArtillery = {
		id = 1136518787, -- Special Cannon 1
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			marketplaceUtil.updatePlayerCache(player, 1136518787)
			table.insert(playerData.cannons, "artillery")
			dataService.updatePlayerData(player, playerData)
		end,
		type = "cannons",
		infoType = Enum.InfoType.GamePass,
		cannonName = "artillery",
		--Gift Compatability
		giftName = "giftArtillery",
		index = 2,
	},
	buyRailgun = {
		id = 1137894433, -- Railgun
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			marketplaceUtil.updatePlayerCache(player, 1137894433)
			table.insert(playerData.cannons, "railgun")
			dataService.updatePlayerData(player, playerData)
		end,
		type = "cannons",
		infoType = Enum.InfoType.GamePass,
		cannonName = "railgun",
		--Gift Compatability
		giftName = "giftRailgun",
		index = 1,
	},
	buyDoubleDistance = {
		id = 1022787535, -- 2x Distance
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			marketplaceUtil.updatePlayerCache(player, 1022787535)
			playerData.doubleDistance = true
			dataService.updatePlayerData(player, playerData)
		end,
		type = "gamepasses",
		infoType = Enum.InfoType.GamePass,
		--Gift Compatability
		giftName = "doubleDistance",
		index = 1,
	},

	buyDoubleMoney = {
		id = 1022657721, -- 2x Money
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			marketplaceUtil.updatePlayerCache(player, 1022657721)
			playerData.doubleMoney = true
			dataService.updatePlayerData(player, playerData)
		end,
		type = "gamepasses",
		infoType = Enum.InfoType.GamePass,
		--Gift Compatability
		giftName = "doubleMoney",
		index = 2,
	},

	buyInfiniteVIP = {
		id = 1022963419, -- VIP
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			marketplaceUtil.updatePlayerCache(player, 1022963419)
			playerData.infiniteVIP = true
			dataService.updatePlayerData(player, playerData)
		end,
		type = "gamepasses",
		infoType = Enum.InfoType.GamePass,
		--Gift Compatability
		giftName = "giveVIP",
		index = 3,
	},
	artilleryGamepasses = {
		["3102302619"] = "artillery", -- Special Cannon 2
		["1137894433"] = "railgun", -- Railgun
		["1136518787"] = "armyCannon", -- Army Cannon
		["3102291606"] = "circusCannon", -- Special Cannon 1
	},
}
