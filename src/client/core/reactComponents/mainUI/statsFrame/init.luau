local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents

local Trove = require(ReplicatedStorage.sharedPackages.Trove)

local zap = require(ReplicatedStorage.zap)

local floors = require(script.floors)
local money = require(script.money)

return function(props)
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.0),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
	}, {
		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 1.78,
		}),
		floorsFrame = React.createElement(floors, props),
		moneyFrame = React.createElement(money, props),
	})
end
