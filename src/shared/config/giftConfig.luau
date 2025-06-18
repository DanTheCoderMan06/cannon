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
		id = 2691916915, -- Gift 10 Floors (Tier II) 2706012608
		shouldAppear = true,
		tiers = true,
		tier2Name = "tenFloorsTier2",
		type = "floors",
		formalName = "10 Floors",
		giftColor = Color3.new(0.5, 1, 0.5),
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
		Name = "10 Floors",
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " 10 Floors!"
		end,
	},
	tenFloorsTier2 = {
		type = "floors",
		id = 2706012608, -- Gift 10 Floors (Tier II)
		formalName = "10 Floors",
		giftColor = Color3.new(0.5, 1, 0.5),
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 5 -- Initialize if nil
				playerData.productTiers.gifts["floors"] += 1
				playerData.floors += 10
				playerData.boughtFloors += 10

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 5 -- Initialize if nil
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
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " 10 Floors!"
		end,
	},
	fiftyFloors = {
		id = 2691917042, -- Gift 50 Floors (Tier II)
		type = "floors",
		shouldAppear = true,
		tiers = true,
		tier2Name = "fiftyFloorsTier2",
		formalName = "50 Floors",
		giftColor = Color3.new(0.5, 0.5, 1),
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
		Name = "50 Floors",
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " 50 Floors!"
		end,
	},
	fiftyFloorsTier2 = {
		id = 2706012927, -- Gift 50 Floors (Tier II)
		type = "floors",
		formalName = "50 Floors",
		giftColor = Color3.new(0.5, 0.5, 1),
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 5 -- Initialize if nil
				playerData.productTiers.gifts["floors"] += 1
				playerData.floors += 50
				playerData.boughtFloors += 50

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 5 -- Initialize if nil
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
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " 50 Floors!"
		end,
	},
	twoHundredFifty = {
		id = 2691917179, -- Gift 250 Floors (BEST DEAL!)
		shouldAppear = true,
		tiers = true,
		type = "floors",
		tier2Name = "twoHundredFiftyTier2",
		formalName = "250 Floors",
		giftColor = Color3.new(0.5, 0.5, 1),
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
		Name = "250 Floors",
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " 250 Floors!"
		end,
	},
	twoHundredFiftyTier2 = {
		id = 2706013070, -- Gift 250 Floors (Tier II)
		type = "floors",
		formalName = "250 Floors",
		giftColor = Color3.new(0.5, 0.5, 1),
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 5 -- Initialize if nil
				playerData.productTiers.gifts["floors"] += 1
				playerData.floors += 250
				playerData.boughtFloors += 250

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["floors"] = playerData.productTiers.gifts["floors"] or 5 -- Initialize if nil
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
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " 250 Floors!"
		end,
	},
	doubleDistance = {
		id = 3106616737, -- 2x Distance (Gift)
		shouldAppear = true,
		tiers = false,
		type = "gamepasses",
		tier2Name = "doubleDistanceTier2",
		formalName = "2x Distance",
		giftColor = Color3.new(0.7, 0.5, 0.7),
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
		Name = "2x Distance",
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " 2x Distance!"
		end,
	},
	--[[
	doubleDistanceTier2 = {
		id = 3106616737, -- 2x Distance (Gift)
		type = "gamepasses",
		shouldAppear = false,
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["doubleDistance"] = playerData.productTiers.gifts["doubleDistance"] or 5 -- Initialize if nil
				playerData.productTiers.gifts["doubleDistance"] += 1
				playerData.doubleDistance = true

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["doubleDistance"] = playerData.productTiers.gifts["doubleDistance"] or 5 -- Initialize if nil
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
	--]]
	doubleMoney = {
		id = 3106616541, -- 2x Cash (Gift)
		shouldAppear = true,
		tiers = false,
		type = "gamepasses",
		tier2Name = "doubleMoneyTier2",
		formalName = "2x Cash",
		giftColor = Color3.new(0.7, 0.5, 0.7),
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
		Name = "2x Cash",
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " 2x Cash!"
		end,
	},
	--[[
	doubleMoneyTier2 = {
		id = 3106616541, -- 2x Cash (Gift)
		shouldAppear = false,
		type = "gamepasses",
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["doubleMoney"] = playerData.productTiers.gifts["doubleMoney"] or 5 -- Initialize if nil
				playerData.productTiers.gifts["doubleMoney"] += 1
				playerData.doubleMoney = true

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["doubleMoney"] = playerData.productTiers.gifts["doubleMoney"] or 5 -- Initialize if nil
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
	--]]
	giveVIP = {
		id = 3106616269, -- VIP (Gift)
		shouldAppear = true,
		tiers = false,
		type = "gamepasses",
		tier2Name = "giveVIPTier2",
		formalName = "VIP",
		giftColor = Color3.new(0.7, 0.5, 0.7),
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
		Name = "VIP",
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " VIP!"
		end,
	},
	--[[
	giveVIPTier2 = {
		id = 3106616269, -- VIP (Gift)
		type = "gamepasses",
		shouldAppear = false,
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["giveVIP"] = playerData.productTiers.gifts["giveVIP"] or 5 -- Initialize if nil
				playerData.productTiers.gifts["giveVIP"] += 1
				playerData.infiniteVIP = true

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["giveVIP"] = playerData.productTiers.gifts["giveVIP"] or 5 -- Initialize if nil
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
	--]]
	giftArtillery = {
		id = 3106618096, -- Special Cannon 1 (Gift)
		shouldAppear = true,
		tiers = true,
		type = "cannons",
		tier2Name = "giftArtilleryTier2",
		formalName = "Artillery Cannon",
		giftColor = Color3.new(0.5, 0.67, 1),
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				if playerData.productTiers.gifts["cannons"] and playerData.productTiers.gifts["cannons"] >= 5 then
					return
				end
				playerData.productTiers.gifts["cannons"] = playerData.productTiers.gifts["cannons"] or 0
				playerData.productTiers.gifts["cannons"] += 1
				dataService.addCannon(player, "artillery")

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

				dataService.addCannon(target, "artillery")

				task.defer(function()
					-- No need to update target data here, addCannon handles it
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
		--Gift Compat
		giftName = "giftArtillery",
		Name = "Artillery Cannon",
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " the Artillery Cannon!"
		end,
	},
	giftArtilleryTier2 = {
		id = 3106618096, -- Special Cannon 1 (Gift)
		type = "cannons",
		formalName = "Artillery Cannon",
		giftColor = Color3.new(0.5, 0.73, 1),
		shouldAppear = false,
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["cannons"] = playerData.productTiers.gifts["cannons"] or 5 -- Initialize if nil
				playerData.productTiers.gifts["cannons"] += 1
				dataService.addCannon(player, "artillery")

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["cannons"] = playerData.productTiers.gifts["cannons"] or 5 -- Initialize if nil
				playerData.productTiers.gifts["cannons"] += 1

				dataService.addCannon(target, "artillery")

				task.defer(function()
					-- No need to update target data here, addCannon handles it
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
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " the Artillery Cannon!"
		end,
	},
	giftRailgun = {
		id = 3106618239, -- Special Cannon 2 (Gift)
		shouldAppear = true,
		tiers = false,
		type = "cannons",
		tier2Name = "giftRailgunTier2",
		formalName = "Railgun Cannon",
		giftColor = Color3.new(0.7, 0.5, 0.7),
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
		Name = "Railgun Cannon",
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " the Railgun Cannon!"
		end,
	},
	giftRailgunTier2 = {
		id = 3106618239, -- Special Cannon 2 (Gift)
		type = "cannons",
		formalName = "Railgun Cannon",
		giftColor = Color3.new(0.7, 0.5, 0.7),
		shouldAppear = false,
		callback = function(player, target)
			if player == target then
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["cannons"] = playerData.productTiers.gifts["cannons"] or 5 -- Initialize if nil
				playerData.productTiers.gifts["cannons"] += 1
				table.insert(playerData.cannons, "railgun")

				task.defer(function()
					dataService.updatePlayerData(player, playerData)
				end)
			else
				local playerData = dataService.getPlayerData(player)
				playerData.productTiers.gifts["cannons"] = playerData.productTiers.gifts["cannons"] or 5 -- Initialize if nil
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
		AnnouncementMessage = function(player, target)
			return player.Name .. " has gifted " .. target.Name .. " the Railgun Cannon!"
		end,
	},
}
