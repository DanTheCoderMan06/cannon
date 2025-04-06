local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local dataService = require(ServerStorage.server.services.dataService)

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

local zap = require(ServerStorage.zap)

local luckyBlockService = {}

local playerBlocks = {}

PhysicsService:RegisterCollisionGroup("luckyBlock")
PhysicsService:CollisionGroupSetCollidable("players", "luckyBlock", false)

function luckyBlockService.spawnLuckyBlock(player)
	local newBlock = {}
	local playerData = dataService.getPlayerData(player)
	newBlock.id = HttpService:GenerateGUID()
	newBlock.reward = rewardsConfig.luckyBlockFormula(playerData.cannon)
	newBlock.model = ReplicatedStorage.assets.luckyBlock:Clone()

	-- Find the player's platform and the spawn part
	local playerCastle = workspace.castles:WaitForChild(player.Name)
	local playerPlatform = playerCastle and playerCastle:FindFirstChildWhichIsA("Model") -- Assuming platform is the first model
	local blockSpawnPart = playerPlatform and playerPlatform:FindFirstChild("blockSpawn")

	if blockSpawnPart then
		-- Calculate random position within the blockSpawn part
		local spawnSize = blockSpawnPart.Size
		local spawnCFrame = blockSpawnPart.CFrame
		-- Generate random numbers biased towards the center by averaging two randoms
		local function biasedRandom()
			return (math.random() + math.random()) / 2
		end
		local randomX = biasedRandom() * spawnSize.X - spawnSize.X / 2
		local randomY = biasedRandom() * spawnSize.Y - spawnSize.Y / 2
		local randomZ = biasedRandom() * spawnSize.Z - spawnSize.Z / 2
		local randomPositionOffset = Vector3.new(randomX, randomY, randomZ)
		local spawnPosition = spawnCFrame * CFrame.new(randomPositionOffset)

		newBlock.model:SetPrimaryPartCFrame(spawnPosition) -- Set position before parenting
		newBlock.model.Parent = playerPlatform -- Parent to the platform
	else
		-- Fallback: Parent to platform origin if blockSpawn part not found
		warn("Could not find blockSpawn part for player:", player.Name)
		newBlock.model.Parent = playerPlatform
	end

	playerBlocks[tostring(player.UserId)][newBlock.id] = newBlock
	zap.spawnLuckyBlock.Fire(player, newBlock) -- Assuming this event handles client-side visuals if needed
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
		newBlock.model:Destroy()
		local playerData = dataService.getPlayerData(player)
		playerData.money += newBlock.reward
		dataService.updatePlayerData(player, playerData)
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
