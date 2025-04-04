local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local dataService = require(ServerStorage.server.services.dataService)
local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

local joinRewardService = {}

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
		referrerData.money += rewardAmount
		referrerData.invitedPlayers[joinedUserIdStr] = os.time() -- Record timestamp

		-- Update online player data
		dataService.updatePlayerData(referrerPlayer, referrerData)
		print(
			`[joinRewardService] Rewarded ONLINE player {referrerPlayer.Name} ({referrerId}) with {rewardAmount} money for referring {joinedUserId}.`
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
function joinRewardService.start()
	-- Connect to player added event
	Players.PlayerAdded:Connect(joinRewardService.onPlayerJoined)

	-- MessagingService subscription is no longer needed as we handle offline updates directly.

	print("[joinRewardService] Started successfully. Handles online and offline referrals.")
end

return joinRewardService
