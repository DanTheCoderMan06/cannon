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
		Position = UDim2.fromScale(0.9, 0.5),
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
					props.selectedUIEvent:Fire("rewards")
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
	--[[
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.9, 0.5),
		Size = UDim2.fromScale(0.0521, 0.0926),
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
			overlay = React.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://116797538593247",
				ImageTransparency = styles.gold:map(function(val)
					return 1 - val
				end),
				Visible = styles.gold:map(function(val)
					return val > 0
				end),
				Position = styles.gold:map(function(val)
					return UDim2.fromScale(0.5, 0.5):Lerp(UDim2.fromScale(0.5, 0.55), val)
				end),
				Rotation = styles.rotate:map(function(val)
					return val * 14
				end),
				ScaleType = Enum.ScaleType.Fit,
				Size = styles.rotate:map(function(val)
					return UDim2.fromScale(0.9, 0.9):Lerp(UDim2.fromScale(1, 1), 1 - val)
				end),
				ZIndex = 10,
			}, {
				text = React.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
					Position = UDim2.fromScale(0.494, 0.883),
					Size = UDim2.fromScale(1.5, 0.371),
					Text = "Rewards",
					TextColor3 = Color3.fromHex("ffd700"),
					TextScaled = true,
					TextSize = 14,
					TextWrapped = true,
					TextTransparency = styles.gold:map(function(val)
						return 1 - val
					end),
				}, {
					uIAspectRatioConstraint2 = React.createElement("UIAspectRatioConstraint", {
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
			}),
			content = React.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://109156736467684",
				ImageColor3 = Color3.new(1, 1, 1),
				Position = styles.gold:map(function(val)
					return UDim2.fromScale(0.5, 0.5):Lerp(UDim2.fromScale(0.5, 0.55), val)
				end),
				Rotation = styles.rotate:map(function(val)
					return val * 14
				end),
				ScaleType = Enum.ScaleType.Fit,
				Size = styles.rotate:map(function(val)
					return UDim2.fromScale(0.9, 0.9):Lerp(UDim2.fromScale(1, 1), 1 - val)
				end),
				[React.Event.Activated] = function()
					task.spawn(function()
						api.start({
							gold = 1,
							config = {
								tension = 700,
								friction = 30,
							},
						})
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
				ZIndex = 5,
			}, {
				uIAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint"),

				text = React.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
					Position = UDim2.fromScale(0.494, 0.883),
					Size = UDim2.fromScale(1.5, 0.371),
					Text = "Rewards",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					TextSize = 14,
					TextWrapped = true,
				}, {
					uIAspectRatioConstraint2 = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 4.38,
					}),

					uIStroke = React.createElement("UIStroke", {
						Thickness = 4,
					}),
				}),
			}),
		}),

		uIPadding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0.8, 0),
		}),

		uIScale = React.createElement("UIScale", {
			Scale = 1.1,
		}),
	})
	--]]
end
