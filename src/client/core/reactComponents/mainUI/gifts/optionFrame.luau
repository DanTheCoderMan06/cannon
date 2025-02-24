local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local Sift = require(sharedPackages.Sift)
local Trove = require(sharedPackages.Trove)
local components = ReplicatedStorage.client.reactComponents

local tierConfig = require(ReplicatedStorage.shared.config.tierConfig)

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { selected = 0 }
	end)

	local tierFrameVisible, setTierFrameVisible = React.useBinding(false)

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(
			props.dataChanged:Connect(function(newData)
				if props.tiers then
					if newData.productTiers.gifts[props.productKey] then
						setTierFrameVisible(newData.productTiers.gifts[props.productKey] >= 5)
					else
						setTierFrameVisible(false)
					end
				end
			end),
			"Disconnect"
		)

		return function()
			uiTrove:Destroy()
		end
	end, {})

	return React.createElement("CanvasGroup", {
		BackgroundTransparency = 1,
		GroupTransparency = styles.selected:map(function(val)
			return (1 - val) * 0.1
		end),
	}, {
		content = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "rbxassetid://115932345440925",
			Position = UDim2.fromScale(0.5, 0.5),
			ScaleType = Enum.ScaleType.Fit,
			[React.Event.MouseEnter] = function()
				api.start({ selected = 1, config = { friction = 30, tension = 300 } })
			end,
			[React.Event.MouseLeave] = function()
				api.start({ selected = 0, config = { friction = 30, tension = 300 } })
			end,
			Rotation = styles.selected:map(function(value)
				return value * 2
			end),
			Size = styles.selected:map(function(value)
				return UDim2.fromScale(0.9, 0.9):Lerp(UDim2.fromScale(1, 1), value)
			end),
		}, {
			tierFrameItem = React.createElement("TextLabel", {
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
				Visible = tierFrameVisible,
				ZIndex = 100,
			}, {
				uIStroke = React.createElement("UIStroke"),
			}),
			imageHolder = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://139535521619812",
				LayoutOrder = 1,
				Position = UDim2.fromScale(0.498, 0.34),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.53 * 1.21, 0.6 * 1.21),
			}, {
				uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 1.07,
				}),

				icon = React.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Image = props.image,
					Position = UDim2.fromScale(0.5, 0.5),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(0.803, 0.932),
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
				Position = UDim2.fromScale(0.5, 0.805),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.608, 0.827),
			}, {
				uIAspectRatioConstraint2 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 2.77,
				}),

				price = React.createElement("TextButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1.19, 0.893),
					Text = (props.id == props.selectedObject or props.tier2Name == props.selectedObject) and "CANCEL"
						or "SELECT",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					TextSize = 14,
					TextWrapped = true,
					ZIndex = 10000,
					[React.Event.Activated] = function()
						if tierFrameVisible:getValue() then
							if props.selectedObject == props.tier2Name then
								props.setSelectedObject("")
							else
								props.setSelectedObject(props.tier2Name)
							end
						else
							if props.selectedObject == props.id then
								props.setSelectedObject("")
							else
								props.setSelectedObject(props.id)
							end
						end
					end,
				}, {
					uIAspectRatioConstraint3 = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 4.38,
					}),
				}),
			}),
		}),
	})
end
