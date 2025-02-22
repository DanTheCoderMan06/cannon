local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)

local generics = ReplicatedStorage.client.reactComponents.generics

local button = require(generics.genericButton)

return function(props)
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.0, 0.45),
		Size = UDim2.fromScale(0.0521, 0.0926),
	}, {
		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),

		uIListLayout = React.createElement("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		rewards = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(5.76, 1.08),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(6.51, 1.43),
		}, {
			content = React.createElement(button, {
				overlayImage = "rbxassetid://116797538593247",
				buttonText = "Rewards",
				image = "rbxassetid://109156736467684",
				onActivated = function()
					props.selectedUIEvent:Fire("gifts")
				end,
			}),
		}),

		uIPadding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0.8, 0),
		}),

		uIScale = React.createElement("UIScale", {
			Scale = 1.1,
		}),
	})
end
