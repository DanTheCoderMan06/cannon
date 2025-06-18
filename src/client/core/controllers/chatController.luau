local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local chatController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local zap = require(ReplicatedStorage.zap)
local debugUtil = require(ReplicatedStorage.shared.utilities.debugUtil)

local giftConfig = require(ReplicatedStorage.shared.config.giftConfig)

local giftMessages = {}

local function onIncomingMessage(message)
	local textSource = message.TextSource
	local messageProp = Instance.new("TextChatMessageProperties")
	
	debugUtil.log(message.TextSource)

	if textSource then
		local player = Players:GetPlayerByUserId(textSource.UserId)
		if player then
			if player:GetAttribute("isDEV") then
				messageProp.PrefixText = "<font color='#00FF00'>[🤑 DEVELOPER]</font> " .. message.PrefixText
			elseif player:GetAttribute("isVIP") then
				messageProp.PrefixText = "<font color='#d4af37'>[👑 VIP]</font> " .. message.PrefixText
			end
		end

	end

	return messageProp
end

function chatController.testGift()
	local testData =  {target = "Player2",player = "Player1",giftID = 3106618239} 
	local textChannel = TextChatService:FindFirstChild("RBXGeneral",true)
	local messageData = testData
	local giftData 
	for _, v in pairs(giftConfig) do
		if v.id == messageData.giftID then
			debugUtil.log("found")
			giftData = v 
			break
		end
	end
	local playerTag = "@" .. messageData.player 
	local targetTag = "@" .. messageData.target 
	local targetText
	if giftData then
		targetText = string.format(
			"%s gifted <font color='#%s'>%s</font> to %s",
			playerTag,
			giftData.giftColor:ToHex(),
			giftData.formalName,
			targetTag
		)		
	end
	textChannel:DisplaySystemMessage(targetText)
end

function chatController.start()
	TextChatService.OnIncomingMessage = onIncomingMessage
	
	zap.giftPurchased.SetCallback(function(data)
		local textChannel = TextChatService:FindFirstChild("RBXGeneral",true)
		local messageData = HttpService:JSONDecode(data)
		local giftData 
		for _, v in pairs(giftConfig) do
			if v.id == messageData.giftID then
				giftData = v 
				break
			end
		end
		local playerTag = "@" .. messageData.player 
		local targetTag = "@" .. messageData.target 
		local targetText 
		if giftData then
			targetText = string.format(
				"[GLOBAL]: %s gifted <font color='#%s'>%s</font> to %s",
				playerTag,
				giftData.giftColor:ToHex(),
				giftData.formalName,
				targetTag
			)
		end
		textChannel:DisplaySystemMessage(targetText, nil)

	end)

end

return chatController
