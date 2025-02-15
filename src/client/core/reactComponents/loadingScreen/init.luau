local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents

local rotator = require(components.loadingScreen.rotator)

return function()
	local styles, api = ReactSpring.useSpring(function()
		return { progress = 0 }
	end)

	local dots, setDots = React.useBinding(1)

	React.useEffect(function()
		api.start({
			progress = 1,
			config = { tension = 150, friction = 300 },
		})
		local enabled = true
		task.spawn(function()
			while enabled do
				task.wait(0.2)
				local cd = dots:getValue()
				cd += 1
				if cd > 3 then
					cd = 0
				end
				setDots(cd)
			end
		end)
	end, {})

	return React.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(164, 255, 178),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, {
		info = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			loadbar = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://139755621830423",
				Position = UDim2.fromScale(0.5, 0.793),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1.23, 0.0998),
			}, {
				uIGradient = React.createElement("UIGradient", {
					Color = styles.progress:map(function(val)
						return ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 149)),
							ColorSequenceKeypoint.new(0.31 + 0.375 * val, Color3.fromRGB(3, 255, 150)),
							ColorSequenceKeypoint.new(0.319 + 0.375 * val, Color3.fromRGB(255, 255, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
						})
					end),
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
			Position = UDim2.fromScale(0.5, 0.761),
			Size = UDim2.fromScale(0.46, 0.0443),
			Text = dots:map(function(val)
				local loadT = "Loading"
				for i = 0, val do
					loadT = loadT .. "."
				end
				return loadT
			end),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
		}, {
			uIStroke = React.createElement("UIStroke", {
				Thickness = 4,
			}),
		}),

		logo = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.393),
			Size = UDim2.fromScale(0.46, 0.224),
		}, {
			text1 = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.5, 0.5),
				RichText = true,
				Size = UDim2.fromScale(1, 1),
				Text = "LOGO",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
			}, {
				uIStroke1 = React.createElement("UIStroke", {
					Thickness = 4,
				}),
			}),
		}),
		rotate = React.createElement(rotator),
	})
end
