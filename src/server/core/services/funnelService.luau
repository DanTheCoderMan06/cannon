--!strict
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage.shared
local server = ServerStorage.server

local zap = require(ServerStorage.zap)
local dataService = require(server.services.dataService )

local funnelService = {}

local funnelCache = {}
local initialFloors = {}

function funnelService.trackFirstLaunch(player)
    if funnelCache[player.Name] ~= 1 then
        return
    end
    AnalyticsService:LogOnboardingFunnelStepEvent(player, 1 ," Joined game.")
    funnelCache[player.Name] += 1
end

function funnelService.onRewardClaimed(player)
    if funnelCache[player.Name] ~= 2 then
        return
    end
    AnalyticsService:LogOnboardingFunnelStepEvent(player, 2 ,"Recieved first Reward.")    
    funnelCache[player.Name] += 1
end

function funnelService.onPurchaseUpgrade(player, itemType)
    if itemType == "cannon" then
        if funnelCache[player.Name] ~= 3 then
            return
        end
        AnalyticsService:LogOnboardingFunnelStepEvent(player, 3 ,"Bought first cannon")  
    else
        if funnelCache[player.Name] ~= 4 then
            return
        end
        AnalyticsService:LogOnboardingFunnelStepEvent(player, 4 ,"Bought first floor")  
    end  
    funnelCache[player.Name] += 1
end

function funnelService.onVIPMenu(player)
    if funnelCache[player.Name] ~= 5 then
        return
    end
    AnalyticsService:LogOnboardingFunnelStepEvent(player, 5 ,"Offered VIP Menu (First time player only)")    
    funnelCache[player.Name] += 1
end

function funnelService.onTenthPurchase(player)
    if funnelCache[player.Name] ~= 5 and funnelCache[player.Name] ~= 6 then
        return
    end
    AnalyticsService:LogOnboardingFunnelStepEvent(player, 6 ,"Ten Floors Purchased!")  
    funnelCache[player.Name] = 7  
end

function funnelService.onTwentiethPurchase(player)
    if funnelCache[player.Name] ~= 7 then
        return
    end
    AnalyticsService:LogOnboardingFunnelStepEvent(player, 7 ,"Twenty Floors Purchased!")    
    funnelCache[player.Name] += 1
end


function funnelService.start()
    dataService.dataChanged:Connect(function(player, newData)
        if not initialFloors[player.Name] then
            return
        end
        local difference = newData.floors - initialFloors[player.Name]
        if difference >= 20 then
            funnelService.onTwentiethPurchase(player)
        elseif difference >= 2 then
            funnelService.onTenthPurchase(player)
        end
    end)
    Players.PlayerAdded:Connect(function(player)
        funnelCache[player.Name] = 1
        initialFloors[player.Name] = dataService.getPlayerData(player).floors
        funnelService.trackFirstLaunch(player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        funnelCache[player.Name] = nil
        initialFloors[player.Name] = nil
    end)
    zap.vipMenuEnabled.SetCallback(function(player, ...)
        funnelService.onVIPMenu(player)
    end)
end

return funnelService