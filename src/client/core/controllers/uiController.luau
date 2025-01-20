local uiController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local sharedPackages = ReplicatedStorage.sharedPackages
local React = require(sharedPackages.React)
local ReactRoblox = require(sharedPackages.ReactRoblox)

local sharedPackages = ReplicatedStorage.sharedPackages
local Signal = require(sharedPackages.Signal)
local Trove = require(sharedPackages.Trove)
local menuUi = require(ReplicatedStorage.client.reactComponents.mainUI)

local selectedUIEvent = Signal.new()
local selectSectionEvent = Signal.new()

function uiController.start()
	local container = ReactRoblox.createRoot(Instance.new("Folder"))
	container:render(
		ReactRoblox.createPortal(
			React.createElement(
				"ScreenGui",
				{
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
					ResetOnSpawn = false,
					DisplayOrder = 1,
					IgnoreGuiInset = true,
				},
				{
					content = React.createElement(
						menuUi,
						{ selectedUIEvent = selectedUIEvent, selectSectionEvent = selectSectionEvent }
					),
				}
			),
			Players.LocalPlayer.PlayerGui,
			"menuUI"
		)
	)
end

return uiController
