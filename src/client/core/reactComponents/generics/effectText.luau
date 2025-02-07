local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { timeElapsed = 0 }
	end)

	React.useEffect(function()
		task.delay(0.3, function()
			api.start({
				timeElapsed = 1,
				config = {
					friction = 150,
					tension = 300,
				},
			})
		end)
	end, {})

	return React.createElement("BillboardGui", {
		Active = true,
		AlwaysOnTop = true,
		ClipsDescendants = true,
		LightInfluence = 1,
		Adornee = props.Adornee,
		Size = UDim2.fromScale(18, 6),
		StudsOffset = styles.timeElapsed:map(function(val)
			return Vector3.new(0, 5 + 2 * val, 0)
		end),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		content = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			distance = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				Text = props.text,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextTransparency = styles.timeElapsed,
			}, {
				iStroke = React.createElement("UIStroke", {
					Transparency = styles.timeElapsed,
				}),
			}),
		}),
	})
end
