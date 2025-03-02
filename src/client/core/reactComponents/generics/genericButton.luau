local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)

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
		Position = UDim2.fromScale(0.5, 0.5),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(1, 1),
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
		overlay = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = props.overlayImage,
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
				Text = props.buttonText,
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
			Image = props.image,
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
				SoundService.effects.click:Play()
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
				Text = props.buttonText,
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
	})
end
