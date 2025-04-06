local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService") -- For generating UUIDs

local dataService = require(ServerStorage.server.services.dataService)
local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)
local zap = require(ServerStorage.zap) -- Corrected path as per user feedback
local assets = ReplicatedStorage:WaitForChild("assets")
local friendRewardPrefab = assets:WaitForChild("friendReward")
-- blockSpawn is per-player, find it dynamically

local joinRewardService = {}
local pendingFriendRewards = {} -- Cache: [player] = { blockId = blockId, rewardAmount = amount }
local activeBlocks = {} -- Cache: [blockId] = { blockInstance = instance, player = player }

-- Constant for the 24-hour cooldown period in seconds
local REFERRAL_COOLDOWN = 86400 -- 24 hours in seconds

-- Simple function to handle pcalls with retry logic
local function pcallWithRetry(callback)
	if RunService:IsStudio() then
		callback()
		return true
	end

	local success, result
	local attempts = 0
	local maxAttempts = 5

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

-- Core function to handle a player referral
function joinRewardService.handleReferral(joinedUserId, referrerId)
	local joinedUserIdStr = tostring(joinedUserId)
	local referrerPlayer = Players:GetPlayerByUserId(referrerId)

	if referrerPlayer then
		-- Referrer is ONLINE in this server
		local referrerData = dataService.getPlayerData(referrerPlayer)

		-- Check cooldown
		local lastReferTime = referrerData.invitedPlayers[joinedUserIdStr]
		if lastReferTime and (os.time() - lastReferTime) < REFERRAL_COOLDOWN then
			print(`[joinRewardService] Cooldown active for referrer {referrerId} regarding user {joinedUserId}.`)
			return false -- Already rewarded recently
		end

		-- Calculate and add reward
		local rewardAmount = rewardsConfig.playerJoinReward(referrerData.cannon)

		-- Record the referral timestamp in player data
		referrerData.invitedPlayers[joinedUserIdStr] = os.time()
		dataService.updatePlayerData(referrerPlayer, referrerData) -- Save timestamp

		-- Spawn the block instead of directly giving money
		joinRewardService.spawnBlock(referrerPlayer, rewardAmount)

		print(
			`[joinRewardService] Triggered reward block spawn for ONLINE player {referrerPlayer.Name} ({referrerId}) with reward {rewardAmount} for referring {joinedUserId}.`
		)
		return true
	else
		-- Referrer is OFFLINE or in another server, attempt offline update
		print(`[joinRewardService] Referrer {referrerId} is offline or in another server. Attempting offline update.`)

		local success = dataService.updateOfflinePlayerData(referrerId, function(offlineData)
			-- This function runs only if the offline profile is loaded successfully

			-- Ensure invitedPlayers table exists
			if not offlineData.invitedPlayers then
				offlineData.invitedPlayers = {}
			end

			-- Check cooldown within the offline data
			local lastReferTime = offlineData.invitedPlayers[joinedUserIdStr]
			if lastReferTime and (os.time() - lastReferTime) < REFERRAL_COOLDOWN then
				print(
					`[joinRewardService] Cooldown active for OFFLINE referrer {referrerId} regarding user {joinedUserId}. No update needed.`
				)
				-- To prevent unnecessary saves, we can potentially return a specific value or error,
				-- but ProfileService might save anyway if data is modified.
				-- For simplicity, we'll let it save but log that no reward was given.
				-- Alternatively, throw an error to signal no changes needed:
				-- error("Cooldown active, no reward given.") -- This would stop the save if updateOfflinePlayerData handles it.
				-- Let's assume updateOfflinePlayerData saves regardless, so we just don't modify money.
				return -- Exit the callback without modifying data further
			end

			-- Calculate and add reward based on offline data
			local rewardAmount = rewardsConfig.playerJoinReward(offlineData.cannon or 0) -- Use 0 if cannon level is missing
			offlineData.money += rewardAmount
			offlineData.invitedPlayers[joinedUserIdStr] = os.time() -- Record timestamp

			print(
				`[joinRewardService] Calculated offline reward {rewardAmount} for referrer {referrerId} (Level: {offlineData.cannon or 0}).`
			)
		end)

		if success then
			print(`[joinRewardService] Successfully processed offline referral reward for referrer {referrerId}.`)
			return true
		else
			warn(`[joinRewardService] Failed to process offline referral reward for referrer {referrerId}.`)
			return false
		end
	end
end

-- Function to spawn the physical reward block
function joinRewardService.spawnBlock(player: Player, rewardAmount: number)
	if not player or not player:IsDescendantOf(Players) then
		warn("[joinRewardService] spawnBlock: Invalid player provided.")
		return
	end

	-- Check if player already has a pending reward (prevent spamming blocks for same reward)
	if pendingFriendRewards[player] then
		warn(`[joinRewardService] Player {player.Name} already has a pending reward block. Ignoring new spawn request.`)
		-- Optional: Could refresh the existing block's lifetime or ignore
		return
	end

	local blockId = HttpService:GenerateGUID(false)
	print(`[joinRewardService] Spawning friend reward block {blockId} for {player.Name} with reward {rewardAmount}`)

	local newBlock = friendRewardPrefab:Clone()

	-- Find the player's platform and the blockSpawn part within it
	local playerPlatform = Workspace:FindFirstChild("playerPlatforms", 5)
		and Workspace.playerPlatforms:FindFirstChild(player.Name, 5)
	if not playerPlatform then
		warn(`[joinRewardService] Could not find player platform for {player.Name}. Cannot spawn reward block.`)
		newBlock:Destroy() -- Clean up the unused block
		return
	end
	local blockSpawnPart = playerPlatform:FindFirstChild("blockSpawn", true) -- Recursive search within platform
	if not blockSpawnPart or not blockSpawnPart:IsA("BasePart") then
		warn(
			`[joinRewardService] Could not find 'blockSpawn' BasePart within platform for {player.Name}. Cannot spawn reward block.`
		)
		newBlock:Destroy() -- Clean up the unused block
		return
	end

	-- Find a suitable position near the player's blockSpawn
	local basePosition = blockSpawnPart.Position
	local randomAngle = math.random() * 2 * math.pi
	local randomRadius = math.random() * 10 -- Max radius of 10 studs
	local offsetX = math.cos(randomAngle) * randomRadius
	local offsetZ = math.sin(randomAngle) * randomRadius
	local spawnPosition = basePosition + Vector3.new(offsetX, 2, offsetZ) -- Spawn 2 studs above the calculated point
	newBlock:SetPrimaryPartCFrame(CFrame.new(spawnPosition))

	-- Set attributes for the block script
	newBlock:SetAttribute("RewardAmount", rewardAmount)
	newBlock:SetAttribute("BlockId", blockId) -- Pass the ID to the block's script

	-- Store references and parent to workspace
	pendingFriendRewards[player] = { blockId = blockId, rewardAmount = rewardAmount }
	activeBlocks[blockId] = { blockInstance = newBlock, player = player }
	newBlock.Parent = Workspace

	-- Fire event to the specific client to let them know the block exists
	-- (Client script on the block might handle visuals/prompt directly, but this confirms spawn)
	zap.spawnFriendRewardBlock.Fire(player, { rewardAmount = rewardAmount, blockId = blockId })

	-- Handle cleanup if the player leaves while the block exists
	local playerLeavingConnection
	playerLeavingConnection = player.AncestryChanged:Connect(function(_, parent)
		if not parent then
			local pending = pendingFriendRewards[player]
			if pending and pending.blockId == blockId then
				print(`[joinRewardService] Cleaning up reward block {blockId} for player {player.Name} who left.`)
				if activeBlocks[blockId] and activeBlocks[blockId].blockInstance then
					activeBlocks[blockId].blockInstance:Destroy()
				end
				activeBlocks[blockId] = nil
				pendingFriendRewards[player] = nil
				playerLeavingConnection:Disconnect()
			end
		end
	end)

	-- Also handle cleanup if the block is destroyed manually or claimed
	local blockDestroyingConnection
	blockDestroyingConnection = newBlock.Destroying:Connect(function()
		if activeBlocks[blockId] then
			local ownerPlayer = activeBlocks[blockId].player
			-- Clear active block cache
			activeBlocks[blockId] = nil
			-- Clear pending reward cache if it matches this block
			if pendingFriendRewards[ownerPlayer] and pendingFriendRewards[ownerPlayer].blockId == blockId then
				pendingFriendRewards[ownerPlayer] = nil
			end
		end
		-- Disconnect player leaving connection if block is destroyed first
		if playerLeavingConnection and playerLeavingConnection.Connected then
			playerLeavingConnection:Disconnect()
		end
		blockDestroyingConnection:Disconnect() -- Disconnect self
	end)
end

-- Handler for when a player joins the game
function joinRewardService.onPlayerJoined(player)
	local joinData = player:GetJoinData()

	-- Check if they were referred by someone
	if joinData and joinData.ReferredByPlayerId then
		local referrerId = joinData.ReferredByPlayerId
		print("REFERRED BY: " .. referrerId)
		-- Validate referrer ID
		if not referrerId or referrerId == 0 then
			return
		end

		-- Process the referral
		print("Proccess Referral")
		local success = joinRewardService.handleReferral(player.UserId, referrerId)

		-- Mark that this player has been processed
		if success then
			player:SetAttribute("ReferralRewarded", true)
		end
	end
end

-- Initialize the service
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

	local pendingData = pendingFriendRewards[player]

	-- Verify there's a pending reward associated with this block
	if not pendingData or pendingData.blockId ~= blockId then
		warn(
			`[joinRewardService] Player {player.Name} tried to claim block {blockId}, but pending reward data mismatch or missing. PendingData: {pendingData}`
		)
		-- Clean up potentially orphaned block if it exists
		if blockData.blockInstance then
			blockData.blockInstance:Destroy()
		end
		activeBlocks[blockId] = nil -- Ensure cleanup
		return false
	end

	local rewardAmount = pendingData.rewardAmount

	-- Clear the cache entries *before* giving money
	pendingFriendRewards[player] = nil
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

-- Initialize the service
function joinRewardService.start()
	-- Connect to player added event
	Players.PlayerAdded:Connect(joinRewardService.onPlayerJoined)

	-- Listen for the client event when they trigger the reward block
	zap.claimFriendReward.SetCallback(function(player, data)
		-- Attempt to claim the reward using the block ID
		local success, amount = joinRewardService.claimReward(player, data.blockId)
		if success then
			-- Optional: Could fire another event here for server-side effects if needed
			-- e.g., zap.friendRewardClaimedEffect.Fire(player, { amount = amount })
		end
	end)

	-- PlayerRemoving cleanup is handled by the connection made in spawnBlock

	print("[joinRewardService] Started successfully. Handles online/offline referrals and reward block claiming.")
end

return joinRewardService
