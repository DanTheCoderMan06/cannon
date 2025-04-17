local uiController = {}

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
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
local notification = require(ReplicatedStorage.client.reactComponents.notification)

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

local reactUtil = require(ReplicatedStorage.shared.utilities.reactUtil)

-- Removed unused getRandomPosition function
local notifContainer = ReactRoblox.createRoot(Instance.new("Folder"))

-- Modified function to accept a specific start position
function uiController.renderNotification(text: string, color: Color3, startPosition: UDim2)
	print("Render Notification!")
	local destroyEvent = Signal.new()

	notifContainer:render(ReactRoblox.createPortal(
		React.createElement(notification, {
			text = text,
			start = startPosition,
			color = color,
			destroyEvent = destroyEvent,
		}),
		Players.LocalPlayer.PlayerGui,
		"notification" .. HttpService:GenerateGUID(false)
	))

	task.spawn(function()
		destroyEvent:Wait()
		notifContainer:unmount()
		destroyEvent:Destroy()
	end)
end

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

local function app()
	local selectedGift, setSelectedGift = React.createBinding("")
	local giftSelectedEvent = Signal.new()
	return React.createElement(menuUi, {
		selectedUIEvent = selectedUIEvent,
		selectSectionEvent = selectSectionEvent,
		claimedItemEvent = claimedItemEvent,
		unlockedItemEvent = unlockedItemEvent,
		dataChanged = dataController.dataChanged,
		giftSelectedEvent = giftSelectedEvent,
		getData = dataController.getData,
		resetEvent = resetEvent,
		toggleMusicEvent = musicController.toggleMusicEvent,
		promptIn = function()
			if uiController.canPromptIn() then
				uiController.promptOptIn()
			end
		end,
		selectedGift = selectedGift,
		setSelectedGift = setSelectedGift,
	})
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
			content = React.createElement(app),
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
		if newData.money > currentData.money then
			-- Render money notification below the money stat
			task.spawn(function()
				uiController.renderNotification(
					"+ $" .. reactUtil.formatNumber(math.round(newData.money - currentData.money)), -- Fixed $ placement
					Color3.new(0.419607, 0.572549, 0.349019),
					UDim2.fromScale(0.349, 0.12) -- Position below money stat
				)
			end)
		end
		if newData.floors > currentData.floors then
			-- Render floors notification below the floors stat
			task.spawn(function()
				uiController.renderNotification(
					"+ " .. math.round(newData.floors - currentData.floors) .. " Floors",
					Color3.new(0.333333, 0.392156, 0.592156),
					UDim2.fromScale(0.639, 0.12) -- Position below floors stat
				)
			end)
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
			SoundService.effects.claim:Play()
		end
		if newData.daysPlayed > currentData.daysPlayed then
			for i = 1, newData.daysPlayed - currentData.daysPlayed do
				unlockedItemEvent:Fire(currentData.daysPlayed + i)
			end
		end
		currentData = newData
	end)

	ExperienceNotificationService.OptInPromptClosed:Connect(function()
		uiController.promptInEvent:Fire(true)
	end)

	-- Listen for gift received notifications from the server
	zap.giftReceived.SetCallback(function(message) -- Changed :SetCallback to .SetCallback
		-- Render gift notification (using a default position and color)
		uiController.renderNotification(
			message,
			Color3.fromRGB(170, 85, 255), -- Purple color for gifts
			UDim2.fromScale(0.5, 0.1) -- Default top-center position
		)
	end)
end

return uiController
