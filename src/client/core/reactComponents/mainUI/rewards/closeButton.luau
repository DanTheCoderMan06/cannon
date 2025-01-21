local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents

local genericButton = require(components.generics.genericButton)

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { rotate = 0, clicked = 0 }
	end)

	return React.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.984, -0.00141),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.129, 0.238),
		ZIndex = 5,
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
		content = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://123565630442478",
			Position = styles.rotate:map(function(val)
				return UDim2.fromScale(0.5, 0.5 + 0.05 * val)
			end),
			ScaleType = Enum.ScaleType.Fit,
			Size = styles.rotate:map(function(val)
				return UDim2.fromScale(0.9, 0.9):Lerp(UDim2.fromScale(1, 1), val)
			end),
			Rotation = styles.rotate:map(function(val)
				return val * 5
			end),
			ZIndex = 5,
			[React.Event.Activated] = function()
				task.spawn(function()
					print("Go")
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
			text = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://91168667582185",
				Position = UDim2.fromScale(0.503, 0.469),
				Rotation = 5,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.532, 0.645),
				ZIndex = 7,
			}, {
				uIAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 0.872,
				}),
			}),
		}),
	})
end
