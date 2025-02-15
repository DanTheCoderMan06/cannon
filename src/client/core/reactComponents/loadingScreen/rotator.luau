local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents

local function imageIcon(props)
	return React.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.02 * 2.5, 0.037 * 2.5),
		Position = props.position,
	}, {
		imageLabel = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://83040543408221",
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}),
	})
end

return function(props)
	local images = React.useMemo(function()
		local positions = {}

		for x = 0, 19 do
			for y = 0, 12 do
				table.insert(positions, UDim2.fromScale(x / 10, y / 6))
			end
		end
		local imageFrames = {}
		for _, position in pairs(positions) do
			table.insert(imageFrames, React.createElement(imageIcon, { position = position }))
		end
		return imageFrames
	end, {})

	local styles, api = ReactSpring.useSpring(function()
		return {
			offset = UDim2.fromScale(0, 0),
		}
	end)

	React.useEffect(function()
		api.start({
			offset = UDim2.fromScale(-2, -2),
			config = {
				friction = 300,
				tension = 30,
			},
		})
	end, {})

	return React.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(2, 2),
		Position = styles.offset,
	}, {
		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 1.78,
		}),

		React.createElement(React.Fragment, nil, images),
	})
end
