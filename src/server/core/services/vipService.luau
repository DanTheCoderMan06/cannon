local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local dataService = require(ServerStorage.server.services.dataService)

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)
local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)

local vipService = {}

function vipService.givePlayerTempVIP(player)
	local playerData = dataService.getPlayerData(player)
	if playerData.vipTimeStart == 0 then
		playerData.floors += 100
	end
	playerData.vipTimeStart = os.time()
	task.defer(function()
		dataService.updatePlayerData(player, playerData)
	end)
end

function vipService.start()
	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in pairs(Players:GetPlayers()) do
				local playerData = dataService.getPlayerData(player)
				if
					marketplaceUtil.userOwnsGamepass(player, rewardsConfig.vipGamepass)
					or os.time() - playerData.vipTimeStart < rewardsConfig.vipRewardDuration
					or playerData.infiniteVIP
				then
					player:SetAttribute("isVIP", true)
					playerData.hasVIPOn = true
					dataService.updatePlayerData(player, playerData)
				else
					player:SetAttribute("isVIP", false)
					playerData.hasVIPOn = false
					dataService.updatePlayerData(player, playerData)
				end
			end
		end
	end)
end

return vipService
