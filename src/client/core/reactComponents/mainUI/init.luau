local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local Sift = require(sharedPackages.Sift)
-- Removed dataController require
local components = ReplicatedStorage.client.reactComponents

local rewardsButton = require(components.mainUI.rewardsButton)
local shopButton = require(components.mainUI.shopButton)
local shop = require(components.mainUI.shop)
local rewards = require(components.mainUI.rewards)
local autoFarmButton = require(components.mainUI.autoFarmButton)
local statsFrame = require(components.mainUI.statsFrame)
local musicButton = require(components.mainUI.musicButton)
local newGifts = require(components.mainUI.newGifts)
local vipMenu = require(components.mainUI.vipMenu)

return function(props)
	local uiVisible, setUiVisible = React.useBinding()
	-- Removed vipButtonReadyForNewPlayer binding

	React.useEffect(function()
		local connection = Players.LocalPlayer:GetAttributeChangedSignal("inTutorial"):Connect(function()
			setUiVisible(not Players.LocalPlayer:GetAttribute("inTutorial"))
		end)

		task.delay(1, function()
			setUiVisible(not Players.LocalPlayer:GetAttribute("inTutorial"))
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	-- Removed useEffect for vipButtonReadyForNewPlayer

	-- Removed newProps merge
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 0.0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.),
		Size = UDim2.fromScale(1, 1),
		Visible = uiVisible,
	}, {
		autoFarmButton = React.createElement(autoFarmButton, props),
		rewardsButtonFrame = React.createElement(rewardsButton, props),
		shopButtonFrame = React.createElement(shopButton, props),
		shop = React.createElement(shop, props),
		newGifts = React.createElement(newGifts, props),

		rewards = React.createElement(rewards, props),
		statsFrame = React.createElement(statsFrame, props),
		musicButton = React.createElement(musicButton, props),

		vipMenu = React.createElement(vipMenu, props),
	})
end
