local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { gold = 0, rotate = 0 }
	end)

	return React.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.851, 0.922),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.346, 1.84),
		LayoutOrder = props.index,
		[React.Event.MouseEnter] = function()
			api.start({
				rotate = 1,
				config = {
					tension = 900,
					friction = 15,
				},
			})
		end,
		[React.Event.MouseLeave] = function()
			api.start({
				rotate = 0,
				config = {
					tension = 900,
					friction = 15,
				},
			})
		end,
		[React.Event.Activated] = function()
			task.spawn(function()
				api.start({
					gold = 1,
					config = {
						tension = 700,
						friction = 30,
					},
				})
				props.onActivated()
				task.delay(0.05, function()
					api.start({
						gold = 0,
						config = {
							tension = 700,
							friction = 30,
						},
					})
				end)
			end)
		end,
		ZIndex = 10,
	}, {
		text = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = styles.gold:map(function(val)
				return UDim2.fromScale(0.5, 0.5 + val * 0.05)
			end),
			Size = styles.rotate:map(function(val)
				return UDim2.fromScale(0.9, 0.9):Lerp(UDim2.fromScale(1, 1), val)
			end),
			Text = props.buttonText,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			Rotation = styles.rotate:map(function(val)
				return val * -3
			end),
			ZIndex = 2,
		}, {
			uIStroke = React.createElement("UIStroke", {
				Thickness = 4,
			}),

			uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 4.38,
			}),
		}),

		uIAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 2.96,
		}),
		overlayText = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = styles.gold:map(function(val)
				return UDim2.fromScale(0.5, 0.5 + val * 0.05)
			end),
			Size = styles.rotate:map(function(val)
				return UDim2.fromScale(0.9, 0.9):Lerp(UDim2.fromScale(1, 1), val)
			end),
			Text = props.buttonText,
			TextColor3 = Color3.fromHex("ffd700"),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			TextTransparency = styles.gold:map(function(val)
				return 1 - val
			end),
			Visible = styles.gold:map(function(val)
				return val > 0
			end),
			Rotation = styles.rotate:map(function(val)
				return val * -3
			end),
			ZIndex = 5,
		}, {
			uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 4.38,
			}),

			uIStroke = React.createElement("UIStroke", {
				Thickness = 4,
				Color = Color3.fromHex("ffd700"),
				Transparency = styles.gold:map(function(val)
					return 1 - val
				end),
			}),
		}),
	})
end
