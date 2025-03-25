local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
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
    -- Only proceed if the referrer is in the game
    local referrer = Players:GetPlayerByUserId(referrerId)
    if not referrer then
        -- Send a message to other servers where the referrer might be
        pcallWithRetry(function()
            MessagingService:PublishAsync("joinReward", tostring(referrerId) .. ":" .. tostring(joinedUserId))
        end)
        return false
    end
    
    -- Referrer is in game, get their data
    local playerData = dataService.getPlayerData(referrer)
    
    -- Check if this player has already been referred recently
    local lastReferTime = playerData.invitedPlayers[tostring(joinedUserId)]
    if lastReferTime and (os.time() - lastReferTime) < REFERRAL_COOLDOWN then
        return false -- Already rewarded recently
    end
    
    -- Record this referral with current timestamp
    playerData.invitedPlayers[tostring(joinedUserId)] = os.time()
    
    -- Calculate and add reward
    local rewardAmount = rewardsConfig.playerJoinReward(playerData.cannon)
    playerData.money = playerData.money + rewardAmount
    
    -- Update player data
    dataService.updatePlayerData(referrer, playerData)
    
    print("[joinRewardService] Rewarded player " .. referrer.Name .. " with " .. rewardAmount .. " money for referral!")
    return true
end

-- Handler for when a player joins the game
function joinRewardService.onPlayerJoined(player)
    local joinData = player:GetJoinData()
    
    -- Check if they were referred by someone
    if joinData and joinData.ReferredByPlayerId then
        local referrerId = joinData.ReferredByPlayerId
        
        -- Validate referrer ID
        if not referrerId or referrerId == 0 then
            return
        end
        
        -- Process the referral
        local success = joinRewardService.handleReferral(player.UserId, referrerId)
        
        -- Mark that this player has been processed
        if success then
            player:SetAttribute("ReferralRewarded", true)
        end
    end
end

-- Handle incoming reward messages from other servers
function joinRewardService.handleRewardMessage(message)
    local data = string.split(message.Data, ":")
    local referrerId = tonumber(data[1])
    local joinedUserId = tonumber(data[2])
    
    if not referrerId or not joinedUserId then 
        warn("[joinRewardService] Invalid message format received")
        return 
    end
    
    -- Try to handle the referral (this will already check if the referrer is in this server)
    joinRewardService.handleReferral(joinedUserId, referrerId)
end

-- Initialize the service
function joinRewardService.start()
    -- Connect to player added event
    Players.PlayerAdded:Connect(joinRewardService.onPlayerJoined)
    
    -- Subscribe to cross-server messages
    pcallWithRetry(function()
        MessagingService:SubscribeAsync("joinReward", joinRewardService.handleRewardMessage)
    end)
    
    print("[joinRewardService] Started successfully")
end

return joinRewardService