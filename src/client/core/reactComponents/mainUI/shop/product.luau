local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local Trove = require(sharedPackages.Trove)
local components = ReplicatedStorage.client.reactComponents

local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)
local gamepassConfig = require(ReplicatedStorage.shared.config.gamepassConfig)

local function lockedFrame(props)
	return React.createElement("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Image = "rbxassetid://115932345440925",
		ImageColor3 = Color3.fromRGB(70, 239, 64),
		Position = UDim2.fromScale(0.5, 0.5),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(1, 1),
		Visible = props.owned,
		ZIndex = 0,
	}, {
		text = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.518, 0.495),
			Size = UDim2.fromScale(0.814, 0.227),
			Text = "OWNED",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
		}, {
			iAspectRatioConstraint4 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 4.38,
			}),

			iStroke = React.createElement("UIStroke", {
				Thickness = 1.5,
			}),
		}),
	})
end

local function tierFrame(props)
	return React.createElement("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
		Position = UDim2.fromScale(0.61, 0.112),
		RichText = true,
		Size = UDim2.fromScale(0.582, 0.171),
		Text = "Tier II",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		Visible = props.visible,
		ZIndex = 100,
	}, {
		uIStroke = React.createElement("UIStroke"),
	})
end

return function(props)
	local owned, setIsOwned = React.useBinding(marketplaceUtil.userOwnsGamepass(Players.LocalPlayer, props.id))
	local tierFrameVisible, setTierFrameVisible = React.useBinding(false)
	local currentPrice, setCurrentPrice = React.useBinding(props.price)

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(
			props.dataChanged:Connect(function(newData)
				if props.id == rewardsConfig.vipGamepass then
					setIsOwned(newData.hasVIPOn)
				end
				if props.type == "cannons" then
					setIsOwned(table.find(newData.cannons, props.cannonName) ~= nil)
				end
				if props.tiers then
					if newData.productTiers.products[props.productKey] then
						setTierFrameVisible(newData.productTiers.products[props.productKey] >= 5)
						if newData.productTiers.products[props.productKey] >= 5 then
							local tier2Info = gamepassConfig[props.tier2Name]
							local newInfo = marketplaceUtil.getProductInfo(tier2Info.id, Enum.InfoType.Product)
							setCurrentPrice(newInfo.PriceInRobux)
						end
					end
				end
			end),
			"Disconnect"
		)

		uiTrove:Add(props.playerEvent:Connect(function(data)
			if props.id == data then
				setIsOwned(true)
			end
		end))

		return function()
			uiTrove:Destroy()
		end
	end)

	local styles, api = ReactSpring.useSpring(function()
		return { hover = 0, clicked = 0 }
	end)

	return React.createElement("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.447, 0.0816),
		Size = UDim2.fromScale(0.417, 0.163),
		ZIndex = 0,
		GroupTransparency = props.transparency,
		Visible = props.transparency:map(function(val)
			return val < 0.7
		end),
	}, {
		lockedFrame = React.createElement(lockedFrame, { owned = owned }),

		content = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://115932345440925",
			Position = UDim2.fromScale(0.5, 0.5),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
		}, {
			tierFrame = React.createElement(tierFrame, { visible = tierFrameVisible }),
			imageHolder = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://139535521619812",
				LayoutOrder = 1,
				Position = UDim2.fromScale(0.497, 0.249),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.423, 0.444),
				ZIndex = 9,
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
					Image = "rbxassetid://" .. props.image,
					Position = UDim2.fromScale(0.5, 0.5),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(0.803, 0.871),
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
					return UDim2.fromScale(0.5, 0.805):Lerp(UDim2.fromScale(0.5, 0.82), val)
				end),
				ScaleType = Enum.ScaleType.Fit,
				Size = styles.hover:map(function(val)
					return UDim2.fromScale(0.608 * 0.9, 0.827 * 0.9):Lerp(UDim2.fromScale(0.608, 0.827), val)
				end),
				Rotation = styles.hover:map(function(val)
					return val * 4
				end),
				ZIndex = 0,
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
					SoundService.effects.click:Play()
					task.spawn(function()
						api.start({
							clicked = 1,
							config = {
								tension = 700,
								friction = 30,
							},
						})
						if not owned:getValue() then
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
			}, {
				uIAspectRatioConstraint2 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 2.77,
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
					Text = currentPrice:map(function(val)
						return "" .. val
					end),
					TextColor3 = styles.clicked:map(function(val)
						return Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(89, 160, 136), val)
					end),
					TextScaled = true,
					TextSize = 14,
					TextWrapped = true,
				}, {
					uIAspectRatioConstraint3 = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 4.38,
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
				Position = UDim2.fromScale(0.499, 0.57),
				Size = UDim2.fromScale(0.814, 0.227),
				Text = props.name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
			}, {
				uIStroke = React.createElement("UIStroke", {
					Thickness = 1.5,
				}),

				uIAspectRatioConstraint4 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 4.38,
				}),
			}),
		}),
	})
end
