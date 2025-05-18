local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local Trove = require(sharedPackages.Trove)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents
local reactUtil = require(shared.utilities.reactUtil)
local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil) -- Added import

local SKIP_ALL_PRODUCT_ID = 3101617187 -- Define the product ID

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { hover = 0, clicked = 0 }
	end)

	local price, setPrice = React.useBinding("...") -- Initialize price state

	React.useEffect(function()
		-- Fetch product info on mount
		local success, info = pcall(function()
			return marketplaceUtil.getProductInfo(SKIP_ALL_PRODUCT_ID, Enum.InfoType.Product)
		end)
		if success and info then
			setPrice(info.PriceInRobux)
		else
			warn("Failed to get product info for skipAll button:", info)
			setPrice("?") -- Show error indicator
		end
	end, {}) -- Empty dependency array means run once on mount

	return React.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Image = "rbxassetid://95213254815108",
		LayoutOrder = 0,
		Position = UDim2.fromScale(0.101, 0.714),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.0641 / 2, 1.1),
	}, {
		day = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.5, 0.12),
			Size = UDim2.fromScale(0.938, 0.182),
			Text = "SKIP ALL REWARDS",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
		}, {
			uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 4.38,
			}),

			uIStroke = React.createElement("UIStroke", {
				Thickness = reactUtil.scalePixelSize(4),
			}),
		}),

		BuyButtonContainer = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 3, -- Keep original LayoutOrder if it was on the button itself
			Position = styles.clicked:map(function(val)
				return UDim2.fromScale(0.5, 0.805):Lerp(UDim2.fromScale(0.5, 0.82), val)
			end),
			Size = styles.hover:map(function(val)
				return UDim2.fromScale(0.608 * 0.9, 0.827 * 0.9):Lerp(UDim2.fromScale(0.608, 0.827), val)
			end),
			Rotation = styles.hover:map(function(val)
				return val * 4
			end),
			ZIndex = 0, -- Keep original ZIndex if it was on the button itself
		}, {
			uIAspectRatioConstraintContainer = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 2.77,
			}),
			uIScaleContainer = React.createElement("UIScale", {
				Scale = _G.isMobile and 1.35 or 1,
			}),

			ShadowImageButton = React.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, reactUtil.scalePixelSize(3)), -- Only vertical offset
				Size = UDim2.fromScale(1, 1),
				Image = "rbxassetid://85156488647867",
				ImageColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScaleType = Enum.ScaleType.Fit,
				Active = false,
				Selectable = false,
				ZIndex = 1,
			}),

			MainBuyImageButton = React.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://85156488647867",
				Position = UDim2.fromScale(0.5, 0.5),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}, {
				price = React.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1.19, 0.893),
					Text = price:map(function(val)
						return "" .. val
					end),
					TextColor3 = styles.clicked:map(function(val)
						return Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(89, 160, 136), val)
					end),
					TextScaled = true,
					TextSize = 14,
					TextWrapped = true,
					ZIndex = 3,
				}, {
					uIAspectRatioConstraint3 = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 4.38,
					}),
				}),
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
						MarketplaceService:PromptProductPurchase(Players.LocalPlayer, SKIP_ALL_PRODUCT_ID) -- Use defined constant
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
		}),

		image = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.438),
			Size = UDim2.fromScale(0.74, 0.821),
			ZIndex = -1,
		}, {
			uIAspectRatioConstraint4 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1.06,
			}),
			main = React.createElement("ImageLabel", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				Image = "rbxassetid://99981368805393",
			}),
		}),
	})
end
