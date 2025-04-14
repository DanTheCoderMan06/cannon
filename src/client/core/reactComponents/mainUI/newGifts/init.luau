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

local closeButton = require(components.mainUI.newGifts.closeButton)
local playerFrame = require(components.mainUI.newGifts.player)

local marketplaceUtil = require(shared.utilities.marketplaceUtil)

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 1, selected = 0, valid = 0 }
	end)

	local allPlayers, setAllPlayers = React.useState({})
	local currentTier, setCurrentTier = React.useBinding(1)

	local valid, setValid = React.useBinding(false)

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(props.selectedUIEvent:Connect(function(uiName)
			local target = 1
			if uiName == "newGifts" then
				target = 0
			end
			api.start({
				transparency = target,
				config = {
					tension = 400,
					friction = 25,
				},
			})
		end))

		return function()
			uiTrove:Destroy()
		end
	end, {})

	local players = React.useMemo(function()
		local _players = {}

		for i, player in pairs(allPlayers) do
			if player.Name == Players.LocalPlayer.Name then
				continue
			end
			local userThumbnail = marketplaceUtil.getPlayerImage(player)
			table.insert(
				_players,
				React.createElement(playerFrame, {
					image = userThumbnail,
					id = player.Name,
					userid = player.UserId,
					selectedGift = props.selectedGift,
					onActivated = function()
						local productId = giftConfig[props.selectedGift:getValue()].id
						if giftConfig[props.selectedGift:getValue()].tiers then
							if currentTier:getValue() > 1 then
								productId = giftConfig[giftConfig[props.selectedGift:getValue()].tier2Name].id
							end
						end
						MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
						props.selectedUIEvent:Fire("")
					end,
				})
			)
		end

		return _players
	end, { allPlayers })

	React.useEffect(function()
		-- Don't run if no gift is selected
		if props.selectedGift:getValue() == "" then
			return
		end

		-- Validate giftType
		local giftType = giftConfig[props.selectedGift:getValue()]
		if not giftType then
			warn("newGifts: Invalid selectedGift:", props.selectedGift:getValue())
			task.delay(1, function()
				props.selectedUIEvent:Fire("") -- Close UI if gift config is missing
			end)
			return
		end

		-- Validate currentData and necessary nested tables
		local currentData = props.getData()
		if not currentData or not currentData.productTiers or not currentData.productTiers.gifts then
			warn("newGifts: Missing player data (productTiers or productTiers.gifts)")
			props.selectedUIEvent:Fire("") -- Close UI if data is missing
			return
		end

		-- Now it's safe to access giftType.type and currentData.productTiers.gifts
		local newTier = 1
		if currentData.productTiers.gifts[giftType.type] then
			newTier = currentData.productTiers.gifts[giftType.type] >= 5 and 2 or 1
		end
		setCurrentTier(newTier)

		local uiTrove = Trove.new()

		-- Connect to data changes
		uiTrove:Add(props.dataChanged:Connect(function(newData)
			-- Re-validate necessary data structures in callback as well
			if not newData or not newData.productTiers or not newData.productTiers.gifts then
				warn("newGifts (dataChanged): Missing player data")
				-- Optionally close UI here too, or just prevent update
				return
			end
			-- giftType should still be valid here because the effect reruns if props.selectedGift changes
			local newTier = 1
			if newData.productTiers.gifts[giftType.type] then
				newTier = newData.productTiers.gifts[giftType.type] >= 5 and 2 or 1
			end
			setCurrentTier(newTier)
		end))

		return function()
			uiTrove:Destroy()
		end
	end, {})

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
	end, {})

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
		React.createElement("ImageLabel", {
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

			content = React.createElement("ScrollingFrame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.474),
				ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
				Selectable = false,
				Size = UDim2.fromScale(0.956, 0.888),
			}, {
				uIListLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Wraps = true,
				}),
				React.createElement(React.Fragment, nil, players),
			}),

			text1 = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.0496, -0.0156),
				Rotation = -12,
				Size = UDim2.fromScale(0.494, 0.0911),
				Text = "Gifts",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
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

			tierText = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.496, 0.957),
				Size = UDim2.fromScale(0.494, 0.0639),
				Text = currentTier:map(function(val)
					return "TIER " .. val
				end),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
			}, {
				uIAspectRatioConstraint4 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 4.38,
				}),

				uIStroke1 = React.createElement("UIStroke", {
					Thickness = 4,
				}),
			}),
		}),
	})
end
