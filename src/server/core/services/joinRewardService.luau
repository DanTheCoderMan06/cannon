local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService") -- For generating UUIDs

local dataService = require(ServerStorage.server.services.dataService)
local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)
local zap = require(ServerStorage.zap)
local assets = ReplicatedStorage:WaitForChild("assets")
local friendRewardPrefab = assets:WaitForChild("friendReward")

local joinRewardService = {}
-- Cache: [player] = { [blockId] = rewardAmount } - Allows multiple pending rewards per player
local pendingFriendRewards = {}
local activeBlocks = {} -- Cache: [blockId] = { blockInstance = instance, player = player }

-- Cooldown period from rewardsConfig
local FRIEND_JOIN_COOLDOWN = rewardsConfig.referWaitTime -- Use the value from config (50 seconds)

-- Simple function to handle pcalls with retry logic (kept for potential future use, but less critical now)
local function pcallWithRetry(callback)
	if RunService:IsStudio() then
		local success, result = pcall(callback)
		return success, result
	end

	local success, result
	local attempts = 0
	local maxAttempts = 3 -- Reduced attempts

	repeat
		attempts = attempts + 1
		success, result = pcall(callback)

		if not success then
			warn("[joinRewardService] Attempt " .. attempts .. " failed: " .. tostring(result) .. ". Retrying...")
			task.wait(1)
		end
	until success or attempts >= maxAttempts

	return success, result
end

-- Function to spawn the physical reward block
function joinRewardService.spawnBlock(player: Player, rewardAmount: number)
	if not player or not player:IsDescendantOf(Players) then
		warn("[joinRewardService] spawnBlock: Invalid player provided.")
		return
	end

	local blockId = HttpService:GenerateGUID(false)
	-- print(`[joinRewardService] Spawning friend reward block {blockId} for {player.Name} with reward {rewardAmount}`)

	local newBlock = friendRewardPrefab:Clone()

	-- Find the player's platform and the blockSpawn part within it
	local playerPlatform = Workspace:FindFirstChild("playerPlatforms", 5)
		and Workspace.playerPlatforms:FindFirstChild(player.Name, 5)
	if not playerPlatform then
		warn(`[joinRewardService] Could not find player platform for {player.Name}. Cannot spawn reward block.`)
		newBlock:Destroy() -- Clean up the unused block
		return
	end
	local blockSpawnPart = playerPlatform:FindFirstChild("blockSpawn")

	if not blockSpawnPart or not blockSpawnPart:IsA("BasePart") then
		warn(`[joinRewardService] Could not find 'blockSpawn' BasePart for {player.Name}. Cannot spawn reward block.`)
		newBlock:Destroy() -- Clean up the unused block
		return
	end

	-- Find a suitable position near the player's blockSpawn
	local basePosition = blockSpawnPart.Position
	local randomAngle = math.random() * 2 * math.pi
	local randomRadius = math.random() * 10 -- Max radius of 10 studs
	local offsetX = math.cos(randomAngle) * randomRadius
	local offsetZ = math.sin(randomAngle) * randomRadius
	local spawnPosition = basePosition + Vector3.new(offsetX, 12, offsetZ) -- Spawn 12 studs above the calculated point
	newBlock:SetPrimaryPartCFrame(CFrame.new(spawnPosition))

	-- Set collision group for the interaction part
	local interactionPart = newBlock:FindFirstChild("InteractionPart")
	if interactionPart and interactionPart:IsA("BasePart") then
		interactionPart.CollisionGroup = "luckyBlock" -- Re-use existing group for simplicity
	else
		warn(`[joinRewardService] Could not find 'InteractionPart' in friendReward model for block {blockId}.`)
	end

	-- Set attributes for the block script
	newBlock:SetAttribute("RewardAmount", rewardAmount)
	newBlock:SetAttribute("BlockId", blockId) -- Pass the ID to the block's script

	-- Store references and parent to workspace
	if not pendingFriendRewards[player] then
		pendingFriendRewards[player] = {} -- Initialize player's reward table if it doesn't exist
	end
	pendingFriendRewards[player][blockId] = rewardAmount -- Add the specific block ID and its reward
	activeBlocks[blockId] = { blockInstance = newBlock, player = player }
	newBlock.Parent = Workspace

	-- Fire event to the specific client to let them know the block exists
	zap.spawnFriendRewardBlock.Fire(player, { rewardAmount = rewardAmount, blockId = blockId })

	-- Handle cleanup if the player leaves while the block exists
	local playerLeavingConnection
	playerLeavingConnection = player.AncestryChanged:Connect(function(_, parent)
		if not parent then
			-- Player is leaving the game
			if activeBlocks[blockId] and activeBlocks[blockId].player == player then
				-- print(`[joinRewardService] Cleaning up reward block {blockId} for player {player.Name} who left.`)
				if activeBlocks[blockId].blockInstance then
					activeBlocks[blockId].blockInstance:Destroy() -- Destroy the physical block
				end
				-- Remove from activeBlocks (will also be handled by Destroying connection, but good to be explicit)
				activeBlocks[blockId] = nil
				-- Remove the specific reward from the player's pending list
				if pendingFriendRewards[player] then
					pendingFriendRewards[player][blockId] = nil
					-- Optional: Clean up player entry if their reward list becomes empty
					if next(pendingFriendRewards[player]) == nil then
						pendingFriendRewards[player] = nil
					end
				end
				if playerLeavingConnection and playerLeavingConnection.Connected then
					playerLeavingConnection:Disconnect()
				end
			end
		end
	end)

	-- Also handle cleanup if the block is destroyed manually or claimed
	local blockDestroyingConnection
	blockDestroyingConnection = newBlock.Destroying:Connect(function()
		if activeBlocks[blockId] then
			local ownerPlayer = activeBlocks[blockId].player
			activeBlocks[blockId] = nil
			-- Remove the specific reward from the player's pending list when block is destroyed
			if pendingFriendRewards[ownerPlayer] then
				pendingFriendRewards[ownerPlayer][blockId] = nil
				-- Optional: Clean up player entry if their reward list becomes empty
				if next(pendingFriendRewards[ownerPlayer]) == nil then
					pendingFriendRewards[ownerPlayer] = nil
				end
			end
		end
		if playerLeavingConnection and playerLeavingConnection.Connected then
			playerLeavingConnection:Disconnect()
		end
		if blockDestroyingConnection and blockDestroyingConnection.Connected then
			blockDestroyingConnection:Disconnect()
		end
	end)
end

-- Function to handle claiming the cached reward via the block
function joinRewardService.claimReward(player: Player, blockId: string)
	local blockData = activeBlocks[blockId]

	-- Verify the block exists and belongs to the player trying to claim it
	if not blockData or blockData.player ~= player then
		warn(
			`[joinRewardService] Player {player.Name} tried to claim invalid or non-existent block {blockId}. BlockData: {blockData}`
		)
		return false
	end

	local playerRewards = pendingFriendRewards[player]
	local rewardAmount = playerRewards and playerRewards[blockId]

	-- Verify there's a pending reward associated with this specific block ID for this player
	if not rewardAmount then
		warn(
			`[joinRewardService] Player {player.Name} tried to claim block {blockId}, but no pending reward found for this ID or player. PlayerRewards: {playerRewards}`
		)
		-- Block might be orphaned or already claimed, destroy it just in case
		if blockData.blockInstance then
			blockData.blockInstance:Destroy()
		end
		activeBlocks[blockId] = nil -- Ensure cleanup if block instance was missing
		return false
	end

	-- Clear the specific reward entry *before* giving money
	playerRewards[blockId] = nil
	-- Optional: Clean up player entry if their reward list becomes empty
	if next(playerRewards) == nil then
		pendingFriendRewards[player] = nil
	end
	-- activeBlocks entry will be cleared by the block:Destroy() call below

	-- Get current data and add the reward
	local playerData = dataService.getPlayerData(player)
	playerData.money += rewardAmount
	dataService.updatePlayerData(player, playerData)

	-- Destroy the claimed block
	blockData.blockInstance:Destroy()

	print(
		`[joinRewardService] Player {player.Name} claimed friend reward of {rewardAmount} money from block {blockId}.`
	)
	return true, rewardAmount -- Return success and amount for potential effects
end

-- New function to check friends and grant rewards when a player joins
function joinRewardService.processFriendRewardsOnJoin(joiningPlayer: Player)
	task.wait(2) -- Short delay to allow other players' data to potentially load

	local joiningPlayerId = joiningPlayer.UserId
	local joiningPlayerIdStr = tostring(joiningPlayerId)

	for _, existingPlayer in ipairs(Players:GetPlayers()) do
		-- Skip the player who just joined
		if existingPlayer == joiningPlayer then
			continue
		end

		-- Check friendship (use pcall for safety)
		local areFriendsSuccess, areFriends = pcall(function()
			return existingPlayer:IsFriendsWith(joiningPlayerId)
		end)

		if not areFriendsSuccess then
			warn(
				`[joinRewardService] Failed to check friendship between {existingPlayer.Name} and {joiningPlayer.Name}. Error: {areFriends}`
			)
			continue -- Skip this pair if API fails
		end

		if areFriends then
			-- They are friends, now check cooldown for the existing player
			local existingPlayerData = dataService.getPlayerData(existingPlayer) -- This function waits for data

			-- Ensure the rewards table exists
			if not existingPlayerData.friendJoinRewards then
				existingPlayerData.friendJoinRewards = {}
			end

			local lastRewardTime = existingPlayerData.friendJoinRewards[joiningPlayerIdStr]

			if not lastRewardTime or (os.time() - lastRewardTime) >= FRIEND_JOIN_COOLDOWN then
				-- Cooldown passed or first time, grant reward block
				local rewardAmount =
					rewardsConfig.playerJoinReward(existingPlayerData.floors or 0, existingPlayerData.boughtFloors or 0)

				-- Spawn the block for the existing player
				joinRewardService.spawnBlock(existingPlayer, rewardAmount)

				-- Update the timestamp for this specific friend
				existingPlayerData.friendJoinRewards[joiningPlayerIdStr] = os.time()
				dataService.updatePlayerData(existingPlayer, existingPlayerData) -- Save the updated timestamp

				print(
					`[joinRewardService] Spawned friend reward block for {existingPlayer.Name} because friend {joiningPlayer.Name} joined.`
				)
			else
				-- Still on cooldown for this specific friend
				-- print(`[joinRewardService] Player {existingPlayer.Name} is on cooldown for friend {joiningPlayer.Name}.`)
			end
		end
	end
end

-- Initialize the service
function joinRewardService.start()
	-- Connect to player added event
	Players.PlayerAdded:Connect(function(player)
		-- Use task.defer to avoid potential issues with data loading order
		task.defer(joinRewardService.processFriendRewardsOnJoin, player)

		-- Add debug chat command listener only in Studio
		if RunService:IsStudio() then
			player.Chatted:Connect(function(msg)
				if msg == ":spawnFriendReward" then -- Changed command name for clarity
					print(`[joinRewardService] Debug command :spawnFriendReward received from {player.Name}`)
					local playerData = dataService.getPlayerData(player)
					if playerData then
						local rewardAmount =
							rewardsConfig.playerJoinReward(playerData.floors or 0, playerData.boughtFloors or 0)
						joinRewardService.spawnBlock(player, rewardAmount)
						print(
							`[joinRewardService] Spawned debug friend reward block for {player.Name} with amount {rewardAmount}`
						)
					else
						warn(`[joinRewardService] Could not get player data for {player.Name} to spawn debug reward.`)
					end
				end
			end)
		end

		--Handle DEV

		pcallWithRetry(function()
			if player:GetRankInGroup(13101898) >= 253 then
				player:SetAttribute("isDEV", true)
			end
		end)
	end)

	-- Listen for the client event when they trigger the reward block
	zap.claimFriendReward.SetCallback(function(player, data)
		-- Attempt to claim the reward using the block ID
		local success, amount = joinRewardService.claimReward(player, data.blockId)
		if success then
			-- Optional: Could fire another event here for server-side effects if needed
		end
	end)

	-- PlayerRemoving cleanup is handled by the connection made in spawnBlock

	print("[joinRewardService] Started successfully. Handles friend join rewards and block claiming.")
end

return joinRewardService
