local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local Sift = require(sharedPackages.Sift)
local components = ReplicatedStorage.client.reactComponents

local rewardsButton = require(components.mainUI.rewardsButton)
local shopButton = require(components.mainUI.shopButton)
local shop = require(components.mainUI.shop)
local rewards = require(components.mainUI.rewards)
local autoFarmButton = require(components.mainUI.autoFarmButton)
local statsFrame = require(components.mainUI.statsFrame)
local musicButton = require(components.mainUI.musicButton)

return function(props)
	print("Go")
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 0.0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.),
		Size = UDim2.fromScale(1, 1),
	}, {
		autoFarmButton = React.createElement(autoFarmButton, props),
		rewardsButtonFrame = React.createElement(rewardsButton, props),
		shopButtonFrame = React.createElement(shopButton, props),
		shop = React.createElement(shop, props),
		rewards = React.createElement(rewards, props),
		statsFrame = React.createElement(statsFrame, props),
		musicButton = React.createElement(musicButton, props),
	})
end
