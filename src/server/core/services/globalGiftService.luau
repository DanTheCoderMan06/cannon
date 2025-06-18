local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local debugUtil = require(ReplicatedStorage.shared.utilities.debugUtil)

local zap = require(ServerStorage.zap)

local GlobalGiftAnnouncer = {}

local GIFT_ANNOUNCEMENT_TOPIC = "GlobalGiftAnnouncements"

-- Private function to handle local announcements
local function _announceLocally(data)
	-- Placeholder: This will be replaced by a RemoteEvent to broadcast to clients
	debugUtil.log("Local Announcement: " .. data)
	zap.giftPurchased.FireAll(data)
end

-- Public function to announce a gift purchase
function GlobalGiftAnnouncer.announceGiftPurchase(player, target, giftData)
	local data = HttpService:JSONEncode({
		player = player.Name,
		target = target.Name,
		giftID = giftData.id
	})

	-- Publish to other servers
	local success, result = pcall(function()
		MessagingService:PublishAsync(GIFT_ANNOUNCEMENT_TOPIC, data)
	end)

	if not success then
		warn("Failed to publish gift announcement: " .. tostring(result))
	end
end

-- Subscribe to the global announcement topic
local function onReceiveMessage(message)
	_announceLocally(message.Data)
end

function GlobalGiftAnnouncer.start()
	local s, r = pcall(function()
		MessagingService:SubscribeAsync(GIFT_ANNOUNCEMENT_TOPIC, onReceiveMessage)
	end)
end

return GlobalGiftAnnouncer