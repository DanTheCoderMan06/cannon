local tutorialController = {}

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local tutorialUI = require(ReplicatedStorage.client.reactComponents.tutorial)

local zap = require(ReplicatedStorage.zap)

local toggleEvent
local setText
local endTutorial

local effectsController = require(ReplicatedStorage.client.controllers.effectsController)
local dataController = require(ReplicatedStorage.client.controllers.dataController)
local castleController = require(ReplicatedStorage.client.controllers.castleController)
local cannonController = require(ReplicatedStorage.client.controllers.cannonController)

local tutorialConfig = require(ReplicatedStorage.shared.config.tutorialConfig)

local nextPageSignal = Signal.new()

local tutorialItems

function tutorialController.loadPage(index)
	local pageInfo = tutorialConfig.steps[index]
	setText:Fire(pageInfo.text)
	if not pageInfo then
		tutorialController.endTutorial()
		return
	end

	pageInfo.action(tutorialItems, nextPageSignal, {
		getData = dataController.getData,
		dataChanged = dataController.dataChanged,
		togglePlatform = castleController.togglePlatform,
		toggleAllPlatforms = castleController.toggleAllPlatforms,
		toggleEntrance = cannonController.toggleEntrance,
	})
end

function tutorialController.endTutorial()
	nextPageSignal:DisconnectAll()
	toggleEvent:Fire(false)
	if tutorialItems then
		tutorialItems:Destroy()
	end
	castleController.toggleAllPlatforms(true)
	cannonController.toggleEntrance(true)
end

function tutorialController.startTutorial()
	toggleEvent:Fire(true)
	local currentIndex = 1
	tutorialItems = ReplicatedStorage.assets.tutorial:Clone()
	tutorialItems.Parent = workspace
	nextPageSignal:Connect(function()
		currentIndex += 1
		tutorialController.loadPage(currentIndex)
	end)

	tutorialController.loadPage(currentIndex)
end

function tutorialController.start()
	toggleEvent = Signal.new()
	setText = Signal.new()
	endTutorial = Signal.new()

	task.delay(0.25, function()
		local container = ReactRoblox.createRoot(Instance.new("Folder"))
		container:render(ReactRoblox.createPortal(
			React.createElement("ScreenGui", {
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				ResetOnSpawn = false,
				DisplayOrder = 1,
				IgnoreGuiInset = true,
			}, {
				content = React.createElement(tutorialUI, {
					toggleEvent = toggleEvent,
					setText = setText,
					endTutorial = endTutorial,
				}),
			}),
			Players.LocalPlayer.PlayerGui,
			"tutorialUI"
		))

		local connection

		connection = dataController.dataChanged:Connect(function(newData)
			if newData.firstTime then
				connection:Disconnect()
				tutorialController.startTutorial()
			end
		end)

		if RunService:IsStudio() then
			connection:Disconnect()
			task.wait(1)
			tutorialController.startTutorial()
		end

		endTutorial:Connect(function()
			tutorialController.endTutorial()
		end)
	end)
end

return tutorialController
