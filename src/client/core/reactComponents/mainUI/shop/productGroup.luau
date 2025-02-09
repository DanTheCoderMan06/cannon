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

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { cannons = 0, floors = 1, gamepasses = 1 }
	end)

	local sections = {}

	for name, info in pairs(gamepassConfig) do
		if not info.id then
			continue
		end
		local gamepassInfo = marketplaceUtil.getProductInfo(info.id, info.infoType)
		table.insert(
			sections,
			React.createElement(
				product,
				Sift.Dictionary.merge(props, {
					price = gamepassInfo.PriceInRobux,
					name = gamepassInfo.Name,
					image = gamepassInfo.IconImageAssetId,
					transparency = styles[info.type],
					id = info.id,
					onActivated = function()
						MarketplaceService:PromptPurchase(Players.LocalPlayer, info.id)
					end,
				})
			)
		)
	end

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

	return React.createElement("ScrollingFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.554),
		ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		Selectable = false,
		Size = UDim2.fromScale(0.956, 0.873),
		ZIndex = 9,
	}, {
		uIListLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Wraps = true,
		}),
		React.createElement(React.Fragment, nil, sections),
	})
end
