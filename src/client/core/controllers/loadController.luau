local uiController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

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

local effectsController = require(ReplicatedStorage.client.controllers.effectsController)

function uiController.start()
	local lContainer = ReactRoblox.createRoot(Instance.new("Folder"))
	lContainer:render(ReactRoblox.createPortal(
		React.createElement("ScreenGui", {
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			ResetOnSpawn = false,
			DisplayOrder = 10000,
			IgnoreGuiInset = true,
			Enabled = true,
		}, {
			content = React.createElement(loadUI),
		}),
		Players.LocalPlayer.PlayerGui,
		"loadingContainer"
	))
	Players.LocalPlayer.PlayerGui:WaitForChild("remove"):Destroy()
	task.wait(10)
	effectsController.blackScreen(4, function()
		lContainer:unmount()
	end)
end

return uiController
