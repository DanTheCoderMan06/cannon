local uiController = {}

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local sharedPackages = ReplicatedStorage.sharedPackages
local React = require(sharedPackages.React)
local ReactRoblox = require(sharedPackages.ReactRoblox)

local sharedPackages = ReplicatedStorage.sharedPackages
local Signal = require(sharedPackages.Signal)
local Trove = require(sharedPackages.Trove)
local Sift = require(sharedPackages.Sift)
local menuUi = require(ReplicatedStorage.client.reactComponents.mainUI)
local loadUI = require(ReplicatedStorage.client.reactComponents.loadingScreen)

local zap = require(ReplicatedStorage.zap)

local selectedUIEvent = Signal.new()
local selectSectionEvent = Signal.new()
local unlockedItemEvent = Signal.new()
local claimedItemEvent = Signal.new()
local resetEvent = Signal.new()

local effectsController = require(ReplicatedStorage.client.controllers.effectsController)
local dataController = require(ReplicatedStorage.client.controllers.dataController)
local musicController = require(ReplicatedStorage.client.controllers.musicController)
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
	_G.isMobile = UserInputService.TouchEnabled

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
				dataChanged = dataController.dataChanged,
				getData = dataController.getData,
				resetEvent = resetEvent,
				toggleMusicEvent = musicController.toggleMusicEvent,
				promptIn = function()
					if uiController.canPromptIn() then
						uiController.promptOptIn()
					end
				end,
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
		if newData.daysPlayed == 0 and currentData.daysPlayed ~= 0 then
			resetEvent:Fire()
			currentData = newData
		end
		if not Sift.Array.equalsDeep(newData.daysClaimed, currentData.daysClaimed) then
			local newDays = Sift.Array.difference(newData.daysClaimed, currentData.daysClaimed)
			for _, v in pairs(newDays) do
				claimedItemEvent:Fire(v)
			end
		end
		if newData.daysPlayed > currentData.daysPlayed then
			for i = 1, newData.daysPlayed - currentData.daysPlayed do
				unlockedItemEvent:Fire(currentData.daysPlayed + i)
			end
		end
		currentData = newData
	end)

	ExperienceNotificationService.OptInPromptClosed:Connect(function()
		local canSend = zap.hasNotificationsEnabled.Call()
		uiController.promptInEvent:Fire(canSend)
	end)
end

return uiController
