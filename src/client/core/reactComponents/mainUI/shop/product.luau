local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { hover = 0, clicked = 0 }
	end)

	return React.createElement("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.447, 0.0816),
		Size = UDim2.fromScale(0.417, 0.163),
		ZIndex = 0,
		GroupTransparency = props.transparency,
		Visible = props.transparency:map(function(val)
			return val < 0.7
		end),
	}, {
		content = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://115932345440925",
			Position = UDim2.fromScale(0.5, 0.5),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
		}, {
			imageHolder = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://139535521619812",
				LayoutOrder = 1,
				Position = UDim2.fromScale(0.497, 0.249),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.423, 0.444),
				ZIndex = 9,
			}, {
				uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 1.07,
				}),

				image = React.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Image = "rbxassetid://" .. props.image,
					Position = UDim2.fromScale(0.5, 0.5),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(0.803, 0.871),
				}, {
					uIAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.984,
					}),
				}),
			}),

			buy = React.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://85156488647867",
				LayoutOrder = 3,
				Position = styles.clicked:map(function(val)
					return UDim2.fromScale(0.5, 0.805):Lerp(UDim2.fromScale(0.5, 0.82), val)
				end),
				ScaleType = Enum.ScaleType.Fit,
				Size = styles.hover:map(function(val)
					return UDim2.fromScale(0.608 * 0.9, 0.827 * 0.9):Lerp(UDim2.fromScale(0.608, 0.827), val)
				end),
				Rotation = styles.hover:map(function(val)
					return val * 4
				end),
				ZIndex = 0,
				[React.Event.MouseEnter] = function()
					api.start({
						hover = 1,
						config = {
							tension = 900,
							friction = 15,
						},
					})
				end,
				[React.Event.MouseLeave] = function()
					api.start({
						hover = 0,
						config = {
							tension = 900,
							friction = 15,
						},
					})
				end,
				[React.Event.Activated] = function()
					task.spawn(function()
						api.start({
							clicked = 1,
							config = {
								tension = 700,
								friction = 30,
							},
						})
						props.onActivated()
						task.delay(0.05, function()
							api.start({
								clicked = 0,
								config = {
									tension = 700,
									friction = 30,
								},
							})
						end)
					end)
				end,
			}, {
				uIAspectRatioConstraint2 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 2.77,
				}),

				price = React.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1.19, 0.893),
					Text = "" .. props.price,
					TextColor3 = styles.clicked:map(function(val)
						return Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(89, 160, 136), val)
					end),
					TextScaled = true,
					TextSize = 14,
					TextWrapped = true,
				}, {
					uIAspectRatioConstraint3 = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 4.38,
					}),
				}),
			}),

			text = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.499, 0.57),
				Size = UDim2.fromScale(0.814, 0.227),
				Text = props.name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
			}, {
				uIStroke = React.createElement("UIStroke", {
					Thickness = 1.5,
				}),

				uIAspectRatioConstraint4 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 4.38,
				}),
			}),
		}),
	})
end
