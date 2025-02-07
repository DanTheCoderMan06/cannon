local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local dataService = require(ServerStorage.server.services.dataService)

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

local zap = require(ServerStorage.zap)

local luckyBlockService = {}

local playerBlocks = {}

function luckyBlockService.spawnLuckyBlock(player)
	local newBlock = {}
	local playerData = dataService.getPlayerData(player)
	newBlock.id = HttpService:GenerateGUID()
	newBlock.reward = rewardsConfig.luckyBlockFormula(playerData.cannon)
	playerBlocks[tostring(player.UserId)][newBlock.id] = newBlock
	zap.spawnLuckyBlock.Fire(player, newBlock)
end

function luckyBlockService.start()
	Players.PlayerAdded:Connect(function(player)
		playerBlocks[tostring(player.UserId)] = {}
		playerBlocks[tostring(player.UserId)].lastClaimed = tick()
	end)
	Players.PlayerRemoving:Connect(function(player)
		playerBlocks[tostring(player.UserId)] = nil
	end)
	zap.claimLuckyBlock.SetCallback(function(player, data)
		if not playerBlocks[tostring(player.UserId)] then
			player:Kick("Lucky Block service didn't set up properly, please rejoin!")
			return
		end
		if
			not playerBlocks[tostring(player.UserId)][data.id]
			or type(playerBlocks[tostring(player.UserId)][data.id]) == "number"
		then
			return
		end
		local newBlock = playerBlocks[tostring(player.UserId)][data.id]
		local playerData = dataService.getPlayerData(player)
		playerData.money += newBlock.reward
		dataService.updatePlayerData(player, playerData)
	end)
	zap.requestLuckyBlock.SetCallback(function(player)
		if not playerBlocks[tostring(player.UserId)] then
			player:Kick("Lucky Block service didn't set up properly, please rejoin!")
			return
		end
		if tick() - playerBlocks[tostring(player.UserId)].lastClaimed < rewardsConfig.luckyBlockWaitTime then
			return false
		end
		playerBlocks[tostring(player.UserId)].lastClaimed = tick()
		task.defer(luckyBlockService.spawnLuckyBlock, player)
		return true
	end)
end

return luckyBlockService
