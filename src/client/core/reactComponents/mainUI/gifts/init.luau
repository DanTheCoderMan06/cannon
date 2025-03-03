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
local components = ReplicatedStorage.client.reactComponents

local giftConfig = require(shared.config.giftConfig)

local optionsGroup = require(components.mainUI.gifts.optionsGroup)
local optionsFrame = require(components.mainUI.gifts.optionFrame)
local closeButton = require(components.mainUI.gifts.closeButton)

local marketplaceUtil = require(shared.utilities.marketplaceUtil)

local selectedPlayer
local selectedGift

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 1, selected = 0, valid = 0 }
	end)

	local selectedPlayer, setSelectedPlayer = React.useState("")
	local selectedGift, setSelectedGift = React.useState("")
	local allPlayers, setAllPlayers = React.useState({})

	local valid, setValid = React.useState(false)

	React.useEffect(function()
		local function update()
			local newValid = false
			if not Players:FindFirstChild(selectedPlayer) or not giftConfig[selectedGift] then
				newValid = false
			else
				local check = zap.checkRecipient.Call({ selectedPlayer = selectedPlayer, selectedGift = selectedGift })
				newValid = check
			end
			api.start({
				valid = newValid and 1 or 0,
				config = {
					friction = 30,
					tension = 300,
				},
			})
			setValid(newValid)
		end
		update()

		local uiTrove = Trove.new()

		uiTrove:Add(MarketplaceService.PromptProductPurchaseFinished:Connect(function()
			print("Go")
			update()
		end))

		return function()
			uiTrove:Destroy()
		end
	end, { selectedGift, selectedPlayer, allPlayers })

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

		local marketEvent = marketplaceUtil.getPlayerEvent(Players.LocalPlayer)

		uiTrove:Add(
			marketEvent:Connect(function(id)
				print("Reset")
				setSelectedGift("")
			end),
			"Disconnect"
		)

		return function()
			uiTrove:Destroy()
		end
	end, {})

	local gifts = React.useMemo(function()
		local _gifts = {}

		for giftName, giftInfo in pairs(giftConfig) do
			if not giftInfo.shouldAppear then
				continue
			end
			local productInfo = marketplaceUtil.getProductInfo(giftInfo.id, Enum.InfoType.Product)
			table.insert(
				_gifts,
				React.createElement(optionsFrame, {
					image = "rbxassetid://" .. productInfo.IconImageAssetId,
					selectedObject = selectedGift,
					setSelectedObject = function(input)
						print("UPDATE GIFT " .. tostring(input))
						setSelectedGift(input)
					end,
					id = giftName,
					dataChanged = props.dataChanged,
					tier2Name = giftInfo.tier2Name,
					tiers = giftInfo.tiers,
					productKey = giftName,
					type = giftInfo.type,
				})
			)
		end

		return _gifts
	end, { selectedGift })

	local players = React.useMemo(function()
		local _players = {}

		for i, player in pairs(allPlayers) do
			local userThumbnail = marketplaceUtil.getPlayerImage(player)
			table.insert(
				_players,
				React.createElement(optionsFrame, {
					image = userThumbnail,
					selectedObject = selectedPlayer,
					setSelectedObject = function(input)
						print("UPDATE GIFT " .. tostring(input))
						setSelectedPlayer(input)
					end,

					id = player.Name,
					dataChanged = props.dataChanged,
				})
			)
		end

		return _players
	end, { allPlayers, selectedPlayer })

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(Players.PlayerAdded:Connect(function()
			setAllPlayers(Players:GetPlayers())
		end))

		uiTrove:Add(Players.PlayerRemoving:Connect(function()
			setAllPlayers(Players:GetPlayers())
		end))

		if #players == 0 then
			setAllPlayers(Players:GetPlayers())
		end

		return function()
			uiTrove:Destroy()
		end
	end, { allPlayers })

	return React.createElement("CanvasGroup", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = styles.transparency,
		ZIndex = 10,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	}, {
		uIScale = React.createElement("UIScale", {
			Scale = _G.isMobile and 1.12 or 1,
		}),
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

			players = React.createElement(optionsGroup, {
				Position = UDim2.fromScale(0.0397, 0.17),
				elements = players,
			}),

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

			gifts = React.createElement(optionsGroup, {
				Position = UDim2.fromScale(0.0371, 0.35),
				elements = gifts,
			}),

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
				Size = styles.selected:map(function(val)
					return UDim2.fromScale(0.608, 0.0582):Lerp(UDim2.fromScale(0.608 * 1.1, 0.0582 * 1.1), val)
				end),
				Rotation = styles.selected:map(function(val)
					return val * 5
				end),
				[React.Event.MouseEnter] = function()
					api.start({
						selected = 1,
						config = {
							tension = 300,
							friction = 30,
						},
					})
				end,
				[React.Event.MouseLeave] = function()
					api.start({
						selected = 0,
						config = {
							tension = 300,
							friction = 30,
						},
					})
				end,
			}, {
				uIAspectRatioConstraint5 = React.createElement("UIAspectRatioConstraint", {
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
					Text = valid and "BUY" or "ERROR",
					TextColor3 = styles.valid:map(function(val)
						return Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(255, 158, 158), 1 - val)
					end),
					TextScaled = true,
					TextSize = 14,
					TextWrapped = true,
					[React.Event.Activated] = function()
						if not valid then
							return
						end
						local productId = giftConfig[selectedGift].id
						print(productId)
						MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
					end,
				}, {
					uIAspectRatioConstraint6 = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 4.38,
					}),
				}),
			}),
		}),
	})
end
