local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents
local Trove = require(sharedPackages.Trove)
local Sift = require(sharedPackages.Sift)

local shopUI = ReplicatedStorage.client.reactComponents.mainUI.shop

local closeButton = require(shopUI.closeButton)
local buttonsFolder = require(shopUI.buttonsFolder)
local productGroup = require(shopUI.productGroup)

local reactUtil = require(shared.utilities.reactUtil)

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 1 }
	end)

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(props.selectedUIEvent:Connect(function(uiName)
			print(uiName)
			local target = 1
			if uiName == "shop" then
				if styles.transparency:getValue() == 1 then
					target = 0
				end
			end
			api.start({
				transparency = target,
				config = {
					tension = 400,
					friction = 20,
				},
			})
		end))

		return function()
			uiTrove:Destroy()
		end
	end, {})

	return React.createElement("CanvasGroup", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = styles.transparency,
	}, {
		content = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://93180824709042",
			Position = UDim2.fromScale(0.5, 0.5),
			ScaleType = Enum.ScaleType.Fit,
			Size = styles.transparency:map(function(val)
				return UDim2.fromScale(0.346 * math.max(0.2, 1 - val), 0.765 * math.max(0.2, 1 - val))
			end),
			Rotation = styles.transparency:map(function(val)
				return 8 * val
			end),
		}, {
			uIScale = React.createElement("UIScale"),

			text = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.0496, -0.0156),
				Rotation = -12,
				Size = UDim2.fromScale(0.494, 0.0911),
				Text = "Shop",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				ZIndex = 10000,
			}, {
				uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 4.38,
				}),

				uIStroke = React.createElement("UIStroke", {
					Thickness = 4,
				}),
			}),

			uIAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 0.804,
			}),

			buttonsFolder = React.createElement(buttonsFolder, Sift.Dictionary.merge({ styles = styles }, props)),
			closeButton = React.createElement(closeButton, {
				styles = styles,
				onActivated = function()
					props.selectedUIEvent:Fire("")
				end,
			}),
			productGroupFrame = React.createElement(productGroup, props),
		}),
	})
end
