local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents
local Trove = require(sharedPackages.Trove)
local Sift = require(sharedPackages.Sift)

local product = require(components.mainUI.shop.product)

local gamepassConfig = require(ReplicatedStorage.shared.config.gamepassConfig)

local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)

local function productsGroup(props)
	return React.createElement("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Selectable = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 9,
	}, {
		groupOne = React.createElement("ScrollingFrame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
			Selectable = false,
			Size = UDim2.fromScale(1, 1),
			ScrollingEnabled = props.transparency:map(function(val)
				return val == 0
			end),
			ScrollBarThickness = props.transparency:map(function(val)
				return val < 1 and 10 or 0
			end),
			ZIndex = 9,
		}, {
			uIListLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Wraps = true,
			}),
			React.createElement(React.Fragment, nil, props.products),
		}),
	})
end

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { cannons = 0, floors = 1, gamepasses = 1 }
	end)

	local sections = React.useMemo(function()
		local _sections = {}
		for gamepassName, info in pairs(gamepassConfig) do
			if info.shouldAppear == false then
				continue
			end
			if not info.id then
				continue
			end
			if not _sections[info.type] then
				_sections[info.type] = {}
			end
			local gamepassInfo = type(info.id) == "number" and marketplaceUtil.getProductInfo(info.id, info.infoType)
				or marketplaceUtil.getProductInfo(info.id[1], info.infoType)
			table.insert(
				_sections[info.type],
				React.createElement(
					product,
					Sift.Dictionary.merge(props, {
						productKey = gamepassName,
						price = gamepassInfo.PriceInRobux,
						name = gamepassInfo.Name,
						image = gamepassInfo.IconImageAssetId,
						transparency = styles[info.type],
						type = info.type,
						cannonName = info.cannonName,
						id = info.id,
						tier2Name = info.tier2Name,
						specialFloorTiers = info.specialFloorTiers,
						playerEvent = marketplaceUtil.getPlayerEvent(Players.LocalPlayer),
						onActivated = function()
							if info.floorTiers then
								local playerData = props.getData()
								local tierIndex = info.getId(playerData)
								MarketplaceService:PromptProductPurchase(Players.LocalPlayer, info.id[tierIndex])
							elseif info.tiers then
								local currentData = props.getData()
								if currentData.productTiers.products[info.type] then
									if currentData.productTiers.products[info.type] >= 5 then
										local tier2Info = gamepassConfig[info.tier2Name]
										MarketplaceService:PromptProductPurchase(Players.LocalPlayer, tier2Info.id)
									else
										MarketplaceService:PromptProductPurchase(Players.LocalPlayer, info.id)
									end
								else
									MarketplaceService:PromptProductPurchase(Players.LocalPlayer, info.id)
								end
							else
								if info.infoType == Enum.InfoType.GamePass then
									MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, info.id)
								else
									MarketplaceService:PromptProductPurchase(Players.LocalPlayer, info.id)
								end
							end
						end,
						tiers = info.tiers == true,
					})
				)
			)
		end
		return _sections
	end, {
		props,
		styles,
	})

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(props.selectSectionEvent:Connect(function(group)
			api.start({
				cannons = group == "cannons" and 0 or 1,
				gamepasses = group == "gamepasses" and 0 or 1,
				floors = group == "floors" and 0 or 1,
				config = {
					tension = 900,
					friction = 50,
				},
			})
		end))

		return function()
			uiTrove:Destroy()
		end
	end, {})

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.554),
		Selectable = false,
		Size = UDim2.fromScale(0.956, 0.873),
		ZIndex = 9,
	}, {
		cannons = React.createElement(productsGroup, { products = sections["cannons"], transparency = styles.cannons }),
		floors = React.createElement(productsGroup, { products = sections["floors"], transparency = styles.floors }),
		gamepasses = React.createElement(
			productsGroup,
			{ products = sections["gamepasses"], transparency = styles.gamepasses }
		),
	})
end
