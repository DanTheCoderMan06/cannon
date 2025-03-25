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
            priority = 2,                -- Priority level (higher = sent first)
            multiple = true,             -- Can be sent multiple times
            waitTime = 7 * 24 * 60 * 60,              -- Minimum seconds between repeated notifications
            assetid = "04db6352-3a0f-4d4b-a1bb-9c764a6892cf",
            callback = function(playerData)
                -- Grant 50 floors when notification closes
                playerData.Data.floors += 50
            end,
            parseParameters = function(userId, playerData)
                -- Parameters for the notification template
                return {
                    ["name"] = { stringValue = Players:GetNameFromUserIdAsync(userId) }
                }
            end,
        },
        
        -- Free cannon notification
        freeCannon = {
            priority = 3,                -- Priority level (highest priority)
            multiple = true,             -- Can be sent multiple times
            waitTime = 30 * 24 * 60 * 60,              -- Minimum seconds between repeated notifications
            assetid = "192fdfe5-05e6-0142-8ea2-d34dcbbb37ab",
            callback = function(playerData)
                -- Grant 500 floors and circus cannon when notification closes
                playerData.Data.floors += 500
                if not table.find(playerData.Data.cannons, "circusCannon") then
                    table.insert(playerData.Data.cannons, "circusCannon")
                end
            end,
            parseParameters = function(userId, playerData)
                -- Parameters for the notification template
                return {
                    ["name"] = { stringValue = Players:GetNameFromUserIdAsync(userId) }
                }
            end,
        },
        
        -- Daily reward notification
        dailyReward = {
            priority = 1,                -- Priority level (lowest priority)
            multiple = false,            -- Only send once until claimed
            waitTime = 24 * 60 * 60,              -- Minimum seconds between notifications
            assetid = "faefcc75-1b13-fc4f-8708-8c0f9026d5a3",
            callback = function(playerData)
                -- The reward is handled by the daily rewards system
            end,
            parseParameters = function(userId, playerData)
                -- Calculate reward details
                local timePassed = os.time() - playerData.lastClaimed
                local daysPassed = math.floor(timePassed / (24 * 60 * 60))
                local rewardInfo = rewardsConfig.getDailyReward(playerData.daysPlayed + daysPassed)
                local rewardName = rewardInfo and rewardInfo.name or "Unknown Reward"
                
                -- Return parameters
                return {
                    ["rewardName"] = { stringValue = rewardName }
                }
            end,
        },
    },
}