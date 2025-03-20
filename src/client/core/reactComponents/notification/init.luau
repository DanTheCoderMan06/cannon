local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local Sift = require(sharedPackages.Sift)
local components = ReplicatedStorage.client.reactComponents

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 0, position = 0 }
	end)

	React.useEffect(function()
		api.start({
			position = 1,
			config = { tension = 300, friction = 120 },
		})
		task.wait(1)
		api.start({
			transparency = 1,
			config = { tension = 300, friction = 60 },
		})
		task.wait(2)
		props.destroyEvent:Fire()
	end)

	return React.createElement("ScreenGui", {
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		text = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = styles.position:map(function(val)
				return props.start:Lerp(props.start + UDim2.fromScale(0.0, 0.2), val)
			end),
			Size = UDim2.fromScale(0.46, 0.0443),
			Text = props.text,
			TextColor3 = props.color,
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			TextTransparency = styles.transparency,
		}, {
			uIStroke = React.createElement("UIStroke", {
				Transparency = styles.transparency,
			}),

			uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 5,
			}),
		}),
	})
end
