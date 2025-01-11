local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage
local dataService
local castleService

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)

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
	},
	artilleryGamepass = {
		id = 1,
		callback = function(player) end,
	},
	newCannon = {
		id = 2697043453,
		callback = function(player)
			local playerData = dataService.getPlayerData(player)
			local newCannon = cannonConfig.getNextCannon(player.cannon)
			playerData.cannon = newCannon.max
			dataService.updatePlayerData(player, playerData)
		end,
	},
}
