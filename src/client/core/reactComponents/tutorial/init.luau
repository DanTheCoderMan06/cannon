local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local Trove = require(sharedPackages.Trove)
local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local Sift = require(sharedPackages.Sift)
local components = ReplicatedStorage.client.reactComponents

local closeButton = require(script.closeButton)

return function(props)
	return React.createElement("CanvasGroup", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		GroupTransparency = props.styles.transparency,
		ZIndex = 10,
		Visible = props.styles.transparency:map(function(val)
			return val < 0.99
		end),
	}, {
		React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.8,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = props.styles.transparency:map(function(val)
				return UDim2.fromScale(0.5, 1):Lerp(UDim2.fromScale(0.5, 1.071), val)
			end),
			Size = UDim2.fromScale(1, 0.0704),
		}, {
			text = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.5, 0.5),
				RichText = true,
				Size = UDim2.fromScale(0.99, 0.8),
				Text = props.text, --"Welcome to the tutorial! Our system detects you are a new player, and we recommend you read this tutorial to play the game! Press the close button to skip this tutorial!"
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
			}, {
				uIStroke = React.createElement("UIStroke", {
					Thickness = 2,
				}),
			}),

			closeButton = React.createElement(closeButton, {
				onActivated = function()
					props.endTutorial()
					props.toggleEvent:Fire(false)
				end,
			}),
		}),
	})
end
