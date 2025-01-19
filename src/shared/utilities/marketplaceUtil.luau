local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sharedPackages = ReplicatedStorage.sharedPackages
local Signal = require(sharedPackages.Signal)

local marketplaceUtil = {}
local playerCache = {}
local playerEvents = {}

local function safeCall(callback)
	local s, r = pcall(callback)
	while not s do
		task.wait()
		warn("SAFECALL FAILED: " .. r)
		s, r = pcall(callback)
	end
end

function marketplaceUtil.userOwnsGamepass(player, gamepassId)
	if not playerCache[player.UserId] then
		playerCache[player.UserId] = {}
	end
	if not playerCache[player.UserId][gamepassId] then
		safeCall(function()
			playerCache[player.UserId][gamepassId] = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
		end)
	end
	return playerCache[player.UserId][gamepassId]
end

function marketplaceUtil.getPlayerEvent(player)
	if not playerEvents[player.UserId] then
		playerEvents[player.UserId] = Signal.new()
	end
	return playerEvents[player.UserId]
end

function marketplaceUtil.updatePlayerCache(player, id)
	if not playerCache[player.UserId] then
		playerCache[player.UserId] = {}
	end
	playerCache[player.UserId][id] = true
end

if RunService:IsClient() then
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then
			return
		end
		playerCache[player.UserId][gamePassId] = true
		if playerEvents[player.UserId] then
			playerEvents[player.UserId]:Fire(gamePassId)
		end
	end)
end

return marketplaceUtil
