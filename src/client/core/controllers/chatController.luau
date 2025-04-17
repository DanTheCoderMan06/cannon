local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local chatController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)

local function onIncomingMessage(message)
	local textSource = message.TextSource
	local messageProp = Instance.new("TextChatMessageProperties")
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

function chatController.start()
	TextChatService.OnIncomingMessage = onIncomingMessage
end

return chatController
