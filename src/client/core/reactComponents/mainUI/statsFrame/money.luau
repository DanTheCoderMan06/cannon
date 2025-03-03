local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents

local Trove = require(ReplicatedStorage.sharedPackages.Trove)

local zap = require(ReplicatedStorage.zap)

return function(props)
	local currentMoney, setCurrentMoney = React.useBinding("0")

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(
			props.dataChanged:Connect(function(data)
				setCurrentMoney((math.ceil(data.money)))
			end),
			"Disconnect"
		)

		return function()
			uiTrove:Destroy()
		end
	end, {})

	return React.createElement("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Image = "rbxassetid://103415731180628",
		Position = UDim2.fromScale(0.349, 0.0684),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.349, 0.093),
		ZIndex = 2,
	}, {
		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 4.1,
		}),

		imageLabel = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://132572336266782",
			Position = UDim2.fromScale(0.164, 0.514),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(0.22, 1),
			ZIndex = 3,
		}),

		uIScale = React.createElement("UIScale", {
			Scale = _G.isMobile and 1.1 or 1,
		}),
		label = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.56, 0.514),
			Size = UDim2.fromScale(0.547, 0.505),
			Text = currentMoney,
			TextColor3 = Color3.fromRGB(255, 255, 0),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 3,
		}, {
			uIStroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(11, 60, 76),
				Thickness = 2.3,
			}),
		}),
	})
end
