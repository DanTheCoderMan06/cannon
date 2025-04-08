local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local dataService = require(ServerStorage.server.services.dataService)
local floorConfig = require(ReplicatedStorage.shared.config.floorConfig) -- Added floorConfig require

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

local zap = require(ServerStorage.zap)

local luckyBlockService = {}

local playerBlocks = {}

PhysicsService:RegisterCollisionGroup("luckyBlock")
PhysicsService:CollisionGroupSetCollidable("players", "luckyBlock", false)

function luckyBlockService.spawnLuckyBlock(player)
	-- Server only needs ID and reward amount
	local blockData = {}
	local playerData = dataService.getPlayerData(player)
	blockData.id = HttpService:GenerateGUID()
	-- Calculate reward based on next floor cost * 2.5
	blockData.reward = rewardsConfig.luckyBlockFormula(playerData.floors, playerData.boughtFloors)
	-- Removed: newBlock.model = ReplicatedStorage.assets.luckyBlock:Clone()

	-- Removed server-side model cloning, positioning, and parenting

	-- Store only the necessary data (ID and reward)
	playerBlocks[tostring(player.UserId)][blockData.id] = { reward = blockData.reward } -- Store reward associated with ID
	-- Fire event to client with ID and reward
	zap.spawnLuckyBlock.Fire(player, { id = blockData.id, reward = blockData.reward })
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
		-- Check if the block ID exists in the player's tracked blocks
		local blockData = playerBlocks[tostring(player.UserId)][data.id]
		if not blockData or type(blockData) ~= "table" then -- Check if it's the expected table format
			warn(
				`[luckyBlockService] Player {player.Name} tried to claim invalid or already claimed block ID: {data.id}`
			)
			return -- Invalid or already claimed
		end
		-- Removed: newBlock.model:Destroy() - No server model to destroy
		local playerData = dataService.getPlayerData(player)
		playerData.money += blockData.reward -- Use the stored reward
		dataService.updatePlayerData(player, playerData)
		-- Mark the block as claimed by removing it from the player's tracked blocks
		playerBlocks[tostring(player.UserId)][data.id] = nil
	end)
	zap.requestLuckyBlock.SetCallback(function(player)
		if not playerBlocks[tostring(player.UserId)] then
			player:Kick("Lucky Block service didn't set up properly, please rejoin!")
			return
		end

		-- Get player cannon level to calculate wait time
		local playerData = dataService.getPlayerData(player)
		local cannonLevel = playerData.cannon or 1 -- Default to level 1 if not found

		-- Calculate wait time directly based on cannon level
		local waitTime = rewardsConfig.luckyBlockWaitTime(cannonLevel)

		-- Check cooldown
		if tick() - playerBlocks[tostring(player.UserId)].lastClaimed < waitTime then
			return false
		end
		playerBlocks[tostring(player.UserId)].lastClaimed = tick()
		task.defer(luckyBlockService.spawnLuckyBlock, player)
		return true
	end)
end

return luckyBlockService
