local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

return {
	-- Test notification for checking if a player has notifications enabled
	testNotification = "f453b630-ef25-5349-9102-78762be674ac",

	-- Available notifications that can be sent to players
	notifications = {
		-- Free floors reward notification
		freeFloors = {
			priority = 4, -- Priority level (higher = sent first)
			multiple = true, -- Can be sent multiple times
			waitTime = 7 * 24 * 60 * 60, -- Minimum seconds between repeated notifications
			assetid = "29ef74fb-3af9-0b4c-b8ea-e6465387a6b1",
			callback = function(playerData)
				-- Grant 50 floors when notification closes
				playerData.Data.floors += 50
			end,
			parseParameters = function(userId, playerData)
				-- Parameters for the notification template
				return {
					["name"] = { stringValue = Players:GetNameFromUserIdAsync(userId) },
				}
			end,
		},

		-- Free cannon notification
		freeCannon = {
			priority = 3, -- Priority level (highest priority)
			multiple = true, -- Can be sent multiple times
			waitTime = 30 * 24 * 60 * 60, -- Minimum seconds between repeated notifications
			assetid = "192fdfe5-05e6-0142-8ea2-d34dcbbb37ab",
			callback = function(playerData)
				-- Grant 500 floors and circus cannon when notification closes
				playerData.Data.floors += 500
				if not table.find(playerData.Data.cannons, "railgun") then
					table.insert(playerData.Data.cannons, "railgun")
				end
			end,
			parseParameters = function(userId, playerData)
				-- Parameters for the notification template
				return {
					["name"] = { stringValue = Players:GetNameFromUserIdAsync(userId) },
				}
			end,
		},

		-- Daily reward notification
		dailyReward = {
			priority = 1, -- Priority level (lowest priority)
			multiple = false, -- Only send once until claimed
			waitTime = 24 * 60 * 60, -- Minimum seconds between notifications
			assetid = "faefcc75-1b13-fc4f-8708-8c0f9026d5a3",
			callback = function(playerData)
				-- The reward is handled by the daily rewards system
			end,
			parseParameters = function(userId, playerData)
				-- Calculate reward details
				local timePassed = os.time() - playerData.lastClaimed
				local daysPassed = math.floor(timePassed / (24 * 60 * 60))
				local rewardInfo = rewardsConfig.getDailyReward(playerData.daysPlayed + math.clamp(daysPassed, 0, 1))
				local rewardName = rewardInfo and rewardInfo.name or "Unknown Reward"
				if rewardName == "Cash" then
					rewardName = "+ $" .. rewardsConfig.getDailyRewardCash(1, playerData.cannon)
				end
				-- Return parameters
				return {
					["rewardName"] = { stringValue = rewardName },
				}
			end,
			-- Custom checker to ensure 24 hours have passed since the last claim
			customChecker = function(userId, playerData, timeElapsed)
				if not playerData.lastClaimed then
					return true
				end
				local timeSinceLastClaim = os.time() - playerData.lastClaimed
				require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
					"TIME SINCE LAST DAILY NOTIF: " .. timeSinceLastClaim
				)
				-- Check if at least 24 hours (86400 seconds) have passed
				return timeSinceLastClaim >= 86400
			end,
		},

		-- Daily reward notification
		vipReward = {
			priority = 2, -- Priority level (lowest priority)
			multiple = false, -- Only send once until claimed
			waitTime = 24 * 60 * 60, -- Minimum seconds between notifications
			assetid = "cfd2c9ce-591d-214b-861e-8979c9bd940b",
			callback = function(playerData)
				playerData.Data.vipNotificationSent = true
				playerData.Data.infiniteVIP = true
			end,
			parseParameters = function(userId, playerData)
				return { ["name"] = { stringValue = Players:GetNameFromUserIdAsync(userId) } }
			end,
			-- Custom checker to ensure 24 hours have passed since the last claim
			customChecker = function(userId, playerData, timeElapsed)
				local playerTimeCreated = playerData.timeCreated or 0
				local timeSinceCreated = os.time() - playerTimeCreated
				if userId == 880645672 then
					return true
				end
				if timeSinceCreated < 86400 then
					return false
				end
				if playerData.vipNotificationSent then
					return false
				end
				return true
			end,
		},
	},
}
