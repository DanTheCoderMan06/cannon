local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")

local sharedPackages = ReplicatedStorage.sharedPackages
local Signal = require(sharedPackages.Signal)

local gamepassConfig = require(ReplicatedStorage.shared.config.gamepasses)

local marketplaceUtil = {}
local playerCache = {}
local playerEvents = {}
local gamepassInfoCache = {}

local function safeCall(callback)
	local s, r = pcall(callback)
	while not s do
		task.wait()
		warn("SAFECALL FAILED: " .. r)
		s, r = pcall(callback)
	end
end

function marketplaceUtil.canPromptIn()
	local success, canPrompt = pcall(function()
		return ExperienceNotificationService:CanPromptOptInAsync()
	end)

	return success and canPrompt
end

function marketplaceUtil.promptOptIn()
	local success, errorMessage = pcall(function()
		ExperienceNotificationService:PromptOptIn()
	end)
	return success, errorMessage
end

function marketplaceUtil.getProductInfo(gamepassId, infoType)
	if gamepassInfoCache[gamepassId] then
		return gamepassInfoCache[gamepassId]
	end
	safeCall(function()
		gamepassInfoCache[gamepassId] = MarketplaceService:GetProductInfo(gamepassId, infoType)
	end)
	return gamepassInfoCache[gamepassId]
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

		local amountBought = 0
		for _, v in pairs(gamepassConfig) do
			if v.infoType == Enum.InfoType.GamePass and v.id ~= gamePassId then
				amountBought += 1
			end
		end

		if amountBought then
			if marketplaceUtil.canPromptIn() then
				marketplaceUtil.promptOptIn()
			end
		end
	end)
end

return marketplaceUtil
