local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local Sift = require(sharedPackages.Sift)
local components = ReplicatedStorage.client.reactComponents

return function(props)
	local isOn, setIsOn = React.useBinding(true)

	return React.createElement("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.963, 0.949),
		Size = UDim2.fromScale(0.072, 0.105),
	}, {
		musicOff = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://77767199959219",
			Position = UDim2.fromScale(0.5, 0.5),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 6,
			Visible = isOn:map(function(val)
				return not val
			end),
			[React.Event.Activated] = function()
				SoundService.effects.click:Play()
				setIsOn(true)
				props.toggleMusicEvent:Fire(true)
			end,
		}),

		musicOn = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://101581265831123",
			Position = UDim2.fromScale(0.5, 0.5),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 3,
			[React.Event.Activated] = function()
				SoundService.effects.click:Play()
				setIsOn(false)
				props.toggleMusicEvent:Fire(false)
			end,
		}),

		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),
	})
end
