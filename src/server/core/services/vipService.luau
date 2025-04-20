local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local dataService = require(ServerStorage.server.services.dataService)
local castleService = require(ServerStorage.server.services.castleService)

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)
local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)

local vipService = {}

function vipService.givePlayerTempVIP(player)
	local playerData = dataService.getPlayerData(player)
	playerData.vipTimeStart = os.time()
	task.delay(0.1, function()
		dataService.updatePlayerData(player, playerData)
	end)
end

function vipService.start()
	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in pairs(Players:GetPlayers()) do
				local playerData = dataService.getPlayerData(player)
				print(os.time() - playerData.vipTimeStart)
				if
					marketplaceUtil.userOwnsGamepass(player, rewardsConfig.vipGamepass)
					or os.time() - playerData.vipTimeStart < rewardsConfig.vipRewardDuration
					or playerData.infiniteVIP
				then
					player:SetAttribute("isVIP", true)
					playerData.hasVIPOn = true
					if playerData.firstTimeVIP then
						playerData.floors += 100
						playerData.boughtFloors += 100
						playerData.firstTimeVIP = false
						print("Give floors!")
						-- castleService.updateTower(player) -- Update tower after giving floors -- Removed, handled by dataChanged now
					end
					task.delay(0.1, function()
						dataService.updatePlayerData(player, playerData)
					end)
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
