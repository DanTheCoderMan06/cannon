local uiController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local sharedPackages = ReplicatedStorage.sharedPackages
local React = require(sharedPackages.React)
local ReactRoblox = require(sharedPackages.ReactRoblox)

local sharedPackages = ReplicatedStorage.sharedPackages
local Signal = require(sharedPackages.Signal)
local Trove = require(sharedPackages.Trove)
local Sift = require(sharedPackages.Sift)
local menuUi = require(ReplicatedStorage.client.reactComponents.mainUI)

local zap = require(ReplicatedStorage.zap)

local selectedUIEvent = Signal.new()
local selectSectionEvent = Signal.new()
local unlockedItemEvent = Signal.new()
local claimedItemEvent = Signal.new()

local dataController = require(ReplicatedStorage.client.controllers.dataController)

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)
uiController.promptInEvent = Signal.new()

function uiController.canPromptIn()
	local success, canPrompt = pcall(function()
		return ExperienceNotificationService:CanPromptOptInAsync()
	end)

	return success and canPrompt
end

function uiController.getNameFromDay(day)
	for _, v in pairs(rewardsConfig.rewards) do
		if v.day == day then
			return v.name
		end
	end
end

function uiController.promptOptIn()
	local success, errorMessage = pcall(function()
		ExperienceNotificationService:PromptOptIn()
	end)
	return success, errorMessage
end

function uiController.start()
	local container = ReactRoblox.createRoot(Instance.new("Folder"))
	container:render(ReactRoblox.createPortal(
		React.createElement("ScreenGui", {
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			ResetOnSpawn = false,
			DisplayOrder = 1,
			IgnoreGuiInset = true,
		}, {
			content = React.createElement(menuUi, {
				selectedUIEvent = selectedUIEvent,
				selectSectionEvent = selectSectionEvent,
				claimedItemEvent = claimedItemEvent,
				unlockedItemEvent = unlockedItemEvent,
			}),
		}),
		Players.LocalPlayer.PlayerGui,
		"menuUI"
	))

	local currentData = nil
	dataController.dataChanged:Connect(function(newData)
		if not currentData then
			currentData = newData
			return
		end
		if not Sift.Array.equals(currentData.daysClaimed, newData.daysClaimed) then
			local newDays = Sift.Array.difference(newData.daysClaimed, currentData.daysClaimed)
			for _, v in pairs(newDays) do
				claimedItemEvent:Fire(uiController.getNameFromDay(v))
			end
		end
		if newData.daysPlayed > currentData.daysPlayed then
			for i = 1, newData.daysPlayed - currentData.daysPlayed do
				unlockedItemEvent:Fire(uiController.getNameFromDay(currentData.daysPlayed + i))
			end
		end
		currentData = newData
	end)

	ExperienceNotificationService.OptInPromptClosed:Connect(function()
		print("Closed")
		local canSend = zap.hasNotificationsEnabled.Call()
		print(canSend)
		uiController.promptInEvent:Fire(canSend)
	end)
end

return uiController
