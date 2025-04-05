local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local Trove = require(sharedPackages.Trove)
local ReactSpring = require(sharedPackages.ReactSpring)
local zap = require(ReplicatedStorage.zap)
local Sift = require(sharedPackages.Sift)

local giftConfig = require(ReplicatedStorage.shared.config.giftConfig)

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { hover = 0, clicked = 0 }
	end)

	local canGet, setCanGet = React.useBinding(false)

	React.useEffect(function()
		print(props.selectedGift)
		if props.selectedGift == "" or not props.selectedGift then
			return
		end
		print("call")
		local canGive = zap.checkRecipient.Call({ selectedPlayer = props.id, selectedGift = props.selectedGift })
		setCanGet(canGive)
	end, { props.selectedGift })

	return React.createElement("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Image = "rbxassetid://115932345440925",
		Position = UDim2.fromScale(0.447, 0.0816),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.417, 0.163),
	}, {
		playerName = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.489, 0.647),
			Size = UDim2.fromScale(0.863, 0.117),
			Text = props.id,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
		}, {
			uIStroke = React.createElement("UIStroke", {
				Thickness = 2,
			}),
		}),
		imageHolder = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://139535521619812",
			LayoutOrder = 1,
			Position = UDim2.fromScale(0.495, 0.315),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(0.721, 0.539),
		}, {
			uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1.07,
			}),

			image = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = props.image,
				Position = UDim2.fromScale(0.5, 0.5),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.988, 0.871),
			}, {
				uIAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 0.984,
				}),
			}),
		}),

		buy = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://85156488647867",
			LayoutOrder = 3,
			Position = styles.clicked:map(function(val)
				return UDim2.fromScale(0.5, 0.824):Lerp(UDim2.fromScale(0.5, 0.844), val)
			end),
			ScaleType = Enum.ScaleType.Fit,
			Size = styles.hover:map(function(val)
				return UDim2.fromScale(0.608, 0.827):Lerp(UDim2.fromScale(0.608 * 1.1, 0.827 * 1.1), val)
			end),
		}, {
			uIAspectRatioConstraint2 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 2.77,
			}),

			clicker = React.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "",
				Position = UDim2.fromScale(0.5, 0.5),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 10,
				ImageTransparency = 1,
				[React.Event.MouseEnter] = function()
					api.start({
						hover = 1,
						config = {
							tension = 900,
							friction = 15,
						},
					})
				end,
				[React.Event.MouseLeave] = function()
					api.start({
						hover = 0,
						config = {
							tension = 900,
							friction = 15,
						},
					})
				end,
				[React.Event.Activated] = function()
					SoundService.effects.uiClick:Play()
					task.spawn(function()
						api.start({
							clicked = 1,
							config = {
								tension = 700,
								friction = 30,
							},
						})
						if canGet:getValue() then
							props.onActivated()
						end
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
			}),

			price = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1.19, 0.893),
				Text = canGet:map(function(val)
					return val and "BUY" or "OWNS"
				end),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
			}, {
				uIAspectRatioConstraint3 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 4.38,
				}),
			}),
		}),
	})
end
