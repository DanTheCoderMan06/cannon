local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage
local dataService
local castleService
local cannonService

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)

if RunService:IsServer() then
	ServerStorage = game:GetService("ServerStorage")
	dataService = require(ServerStorage.server.services.dataService)
	castleService = require(ServerStorage.server.services.castleService)
end

return {
	tenFloors = {
		id = 2697043460,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			playerData.floors += 10
			playerData.boughtFloors += 10
			dataService.updatePlayerData(player, playerData)
			castleService.updateTower(player)
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
	},
	fiftyFloors = {
		id = 2697043455,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			playerData.floors += 50
			playerData.boughtFloors += 50
			dataService.updatePlayerData(player, playerData)
			castleService.updateTower(player)
		end,
		type = "floors",
		infoType = Enum.InfoType.Product,
	},
	buyCircusCannon = {
		id = 1051314279,
		callback = function(player)
			marketplaceUtil.updatePlayerCache(player, 1051314279)
		end,
		type = "cannons",
		infoType = Enum.InfoType.GamePass,
	},
	buyArmyCannon = {
		id = 1051600321,
		callback = function(player)
			marketplaceUtil.updatePlayerCache(player, 1051600321)
		end,
		type = "cannons",
		infoType = Enum.InfoType.GamePass,
	},
	buyArtillery = {
		id = 1028783141,
		callback = function(player)
			marketplaceUtil.updatePlayerCache(player, 1028783141)
		end,
		type = "cannons",
		infoType = Enum.InfoType.GamePass,
	},
	buyRailgun = {
		id = 1035960145,
		callback = function(player)
			marketplaceUtil.updatePlayerCache(player, 1035960145)
		end,
		type = "cannons",
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
