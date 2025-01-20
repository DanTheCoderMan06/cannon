local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents

local button = require(script.Parent.button)

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { hoverPosition = UDim2.fromScale(0.174, 0.454) }
	end)
	return React.createElement("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Image = "rbxassetid://139755621830423",
		Position = UDim2.fromScale(0.5, -9.23e-09),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(1.01, 0.0998),
	}, {
		content = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 3,
		}, {
			uIListLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 8.11,
			}),
			floors = React.createElement(button, {
				buttonText = "Floors",
				index = 1,
				onActivated = function()
					api.start({
						hoverPosition = UDim2.fromScale(0.174, 0.454),
						config = {
							tension = 600,
							friction = 30,
						},
					})
				end,
			}),
			cannons = React.createElement(button, {
				buttonText = "Special Cannons",
				index = 2,
				onActivated = function()
					api.start({
						hoverPosition = UDim2.fromScale(0.174 + 0.33, 0.454),
						config = {
							tension = 600,
							friction = 30,
						},
					})
				end,
			}),
			gamepasses = React.createElement(button, {
				buttonText = "Gamepasses",
				index = 3,
				onActivated = function()
					api.start({
						hoverPosition = UDim2.fromScale(0.174 + 0.66, 0.454),
						config = {
							tension = 600,
							friction = 30,
						},
					})
				end,
			}),
		}),

		hover = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://80527595044487",
			Position = styles.hoverPosition,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(0.346, 1.84),
		}, {
			uIAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 2.96,
			}),

			uIFlexItem = React.createElement("UIFlexItem", {
				FlexMode = Enum.UIFlexMode.Shrink,
			}),
		}),
	})
end
