local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 1 }
	end)

	React.useEffect(function()
		api.start({
			transparency = 0,
			config = {
				tension = 300,
				friction = 30,
			},
		})
		task.wait(3)
		api.start({
			transparency = 1,
			config = {
				tension = 300,
				friction = 30,
			},
		})
	end, {})

	return React.createElement("CanvasGroup", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = styles.transparency,
	}, {
		distance = React.createElement("TextLabel", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.1, 0.404),
			RichText = true,
			Size = UDim2.fromScale(0.8, 0.25),
			Text = props.distance .. " studs",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
		}, {
			iStroke = React.createElement("UIStroke"),
		}),

		money = React.createElement("TextLabel", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.025, 0),
			RichText = true,
			Size = UDim2.fromScale(1, 0.5),
			Text = props.reward .. "$",
			TextColor3 = Color3.fromRGB(0, 200, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			iStroke1 = React.createElement("UIStroke"),
		}),

		record = React.createElement("TextLabel", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.05, 0.6),
			RichText = true,
			Size = UDim2.fromScale(0.95, 0.25),
			Text = "NEW RECORD",
			TextColor3 = Color3.fromRGB(255, 117, 117),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Visible = props.isHighscore,
		}, {
			iStroke2 = React.createElement("UIStroke"),
		}),
	})
end
