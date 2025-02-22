local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local Trove = require(sharedPackages.Trove)
local ReactSpring = require(sharedPackages.ReactSpring)
local Sift = require(sharedPackages.Sift)
local components = ReplicatedStorage.client.reactComponents

local giftConfig = require(shared.config.giftConfig)

local optionsGroup = require(components.mainUI.gifts.optionsGroup)
local optionsFrame = require(components.mainUI.gifts.optionFrame)
local closeButton = require(components.mainUI.gifts.closeButton)

local marketplaceUtil = require(shared.utilities.marketplaceUtil)

local selectedPlayer
local selectedGift

local allPlayers = {}

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 1 }
	end)

	local selectedPlayer, setSelectedPlayer = React.useState("")
	local selectedGift, setSelectedGift = React.useState(0)

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(props.selectedUIEvent:Connect(function(uiName)
			local target = 1
			if uiName == "gifts" then
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

	local gifts = React.useMemo(function()
		local _gifts = {}

		for giftName, giftInfo in pairs(giftConfig) do
			local productInfo = marketplaceUtil.getProductInfo(giftInfo.id, Enum.InfoType.Product)
			table.insert(
				_gifts,
				React.createElement(optionsFrame, {
					Sift.Dictionary.merge(props, {
						image = "rbxassetid://" .. productInfo.IconImageAssetId,
						selectedObject = selectedGift,
						setSelectedObject = setSelectedGift,
						id = giftInfo.id,
					}),
				})
			)
		end

		return _gifts
	end, {})

	local players = React.useMemo(function()
		local _players = {}

		for i, player in pairs(allPlayers) do
			local userThumbnail = marketplaceUtil.getPlayerImage(Players.LocalPlayer)
			table.insert(
				_players,
				React.createElement(optionsFrame, {
					Sift.Dictionary.merge(props, {
						image = userThumbnail,
						selectedObject = selectedPlayer,
						setSelectedObject = setSelectedPlayer,
						id = player.Name,
					}),
				})
			)
		end

		return _players
	end, { allPlayers })

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
			Size = UDim2.fromScale(0.346, 0.765),
		}, {
			uIScale = React.createElement("UIScale"),

			closeButton = React.createElement(closeButton, {
				onActivated = function()
					props.selectedUIEvent:Fire("")
				end,
			}),

			text1 = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.0, -0.00543),
				Rotation = -12,
				Size = UDim2.fromScale(0.494, 0.0911),
				Text = "Gifts",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				ZIndex = 100,
			}, {
				uIAspectRatioConstraint2 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 4.38,
				}),

				uIStroke = React.createElement("UIStroke", {
					Thickness = 4,
				}),
			}),

			uIAspectRatioConstraint3 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 0.804,
			}),

			buttons = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://139755621830423",
				Position = UDim2.fromScale(0.5, -9.23e-09),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1.01, 0.0998),
			}, {
				uIListLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				uIAspectRatioConstraint4 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 8.11,
				}),
			}),

			text2 = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.498, 0.0491),
				Size = UDim2.fromScale(0.8, 0.071),
				Text = "Configuration",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				ZIndex = 2,
			}, {
				uIStroke1 = React.createElement("UIStroke", {
					Thickness = 4,
				}),
			}),

			text3 = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.498, 0.128),
				Size = UDim2.fromScale(0.8, 0.0567),
				Text = "Player",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
			}, {
				uIStroke2 = React.createElement("UIStroke", {
					Thickness = 2,
				}),
			}),

			players = React.createElement(
				optionsGroup,
				Sift.Dictionary.merge(props, {
					Position = UDim2.fromScale(0.0397, 0.17),
					elements = players,
				})
			),

			text4 = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.496, 0.308),
				Size = UDim2.fromScale(0.8, 0.0567),
				Text = "Gift",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
			}, {
				uIStroke3 = React.createElement("UIStroke", {
					Thickness = 2,
				}),
			}),

			gifts = React.createElement(
				optionsGroup,
				Sift.Dictionary.merge(props, {
					Position = UDim2.fromScale(0.0371, 0.35),
					elements = gifts,
				})
			),

			buy = React.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://85156488647867",
				LayoutOrder = 3,
				Position = UDim2.fromScale(0.495, 0.946),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.608, 0.0582),
			}, {
				uIAspectRatioConstraint5 = React.createElement("UIAspectRatioConstraint", {
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
					Text = "BUY",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					TextSize = 14,
					TextWrapped = true,
				}, {
					uIAspectRatioConstraint6 = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 4.38,
					}),
				}),
			}),
		}),
	})
end
