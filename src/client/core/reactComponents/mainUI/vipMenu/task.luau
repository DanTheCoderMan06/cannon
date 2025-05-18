local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local Trove = require(sharedPackages.Trove)

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)

local vipTaskConfig = require(shared.config.vipClaimConfig)

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { enabled = 1 }
	end)

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(
			props.eventCompleted:Connect(function(name)
				if name == props.name then
					api.start({
						enabled = 0,
						config = {
							tension = 300,
							friction = 30,
						},
					})
				end
			end),
			"Disconnect"
		)

		return function()
			uiTrove:Destroy()
		end
	end, {})

	return React.createElement("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.7,
		BorderColor3 = Color3.new(),
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Size = UDim2.fromOffset(100, 100),
	}, {
		description = React.createElement("TextLabel", {
			BackgroundColor3 = Color3.fromRGB(241, 241, 241),
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.260108, 0.328489),
			Size = UDim2.fromScale(0.646045, 0.328273),
			Text = props.taskText,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
		}, {
			uICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0.025, 8),
			}),

			uIStroke = React.createElement("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(63, 63, 63),
				Thickness = 2,
			}),

			uIStroke2 = React.createElement("UIStroke"),
		}),

		button = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(193, 193, 193),
			Position = UDim2.fromScale(0.048, 0.076),
			Size = UDim2.fromScale(0.215, 0.842),
		}, {
			uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),

			uIStroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(104, 104, 104),
				Thickness = 3,
			}),

			uICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0.1, 0),
			}),

			enabled = React.createElement("ImageButton", {
				BackgroundTransparency = 1,
				Image = "rbxassetid://115998395063293",
				ImageTransparency = styles.enabled,
				Size = UDim2.fromScale(1, 1),
			}),
		}),
	})
end
