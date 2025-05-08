local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents

local reactUtil = require(ReplicatedStorage.shared.utilities.reactUtil)

local Trove = require(ReplicatedStorage.sharedPackages.Trove)

local zap = require(ReplicatedStorage.zap)

local oldMoney = 0

return function(props)
	local currentMoney, setCurrentMoney = React.useBinding("0")

	React.useEffect(function()
		local uiTrove = Trove.new()
		local player = Players.LocalPlayer
		local stat
		for _, v in pairs(player.leaderstats:GetChildren()) do
			if v:GetAttribute("statName") == "money" then
				stat = v
				setCurrentMoney(tostring(stat.Value))
			end
		end

		if stat then
			uiTrove:Add(stat:GetPropertyChangedSignal("Value"):Connect(function()
				if stat.Value == oldMoney then
					return
				end
				oldMoney = stat.Value
				setCurrentMoney(tostring(stat.Value))
			end))
		end

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
			Text = currentMoney:map(function(val)
				return reactUtil.formatNumber(val)
			end),
			TextColor3 = Color3.fromRGB(255, 255, 0),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 3,
		}, {
			uIStroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(11, 60, 76),
				Thickness = reactUtil.scalePixelSize(2.3),
			}),
		}),
		label2 = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.56, 0.55),
			Size = UDim2.fromScale(0.547, 0.505),
			Text = currentMoney:map(function(val)
				return reactUtil.formatNumber(val)
			end),
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 3,
		}, {
			uIStroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(11, 60, 76),
				Thickness = reactUtil.scalePixelSize(2.3),
			}),
		}),
	})
end
