local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents

local zap = require(ReplicatedStorage.zap)

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { toggle = 1, hover = 0 }
	end)
	local enabled, setEnabled = React.useBinding(false)

	React.useEffect(function()
		local joinData = TeleportService:GetLocalPlayerTeleportData() or {}
		local autoFarmingEnabled = joinData.autoFarming
		setEnabled(autoFarmingEnabled)
		api.start({ toggle = autoFarmingEnabled and 0 or 1, config = { friction = 30, tension = 300 } })
	end, {})

	return React.createElement("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = styles.toggle:map(function(val)
			return Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), val)
		end),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
		Position = UDim2.fromScale(0.918, 0.597),
		Size = styles.hover:map(function(val)
			return UDim2.fromScale(0.135, 0.0499):Lerp(UDim2.fromScale(0.135 * 1.1, 0.0499 * 1.1), val)
		end),
		Text = enabled:map(function(val)
			return val == 0 and "Stop Farm" or "Auto Farm"
		end),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
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
		Rotation = styles.hover:map(function(val)
			return val * 6
		end),
	}, {
		uICorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0.3, 0),
		}),

		uIPadding = React.createElement("UIPadding", {
			PaddingBottom = UDim.new(0.1, 0),
			PaddingLeft = UDim.new(0.1, 0),
			PaddingRight = UDim.new(0.1, 0),
			PaddingTop = UDim.new(0.1, 0),
		}),

		uIStroke = React.createElement("UIStroke", {
			Thickness = 2,
		}),

		uIStroke1 = React.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 2,
		}),

		textLabel = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0, -0.2),
			Size = UDim2.fromScale(0.438, 0.6),
			Text = "FREE!",
			TextColor3 = Color3.fromRGB(21, 208, 11),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
		}, {
			uIStroke2 = React.createElement("UIStroke", {
				Color = Color3.fromRGB(12, 86, 4),
				Thickness = 2.5,
			}),
		}),
		clicker = React.createElement("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Text = "",
			TextColor3 = Color3.fromRGB(21, 208, 11),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			ZIndex = 100,
			[React.Event.Activated] = function()
				SoundService.effects.click:Play()
				local success = zap.toggleAutoFarm.Call()
				if success then
					api.start({ toggle = not enabled:getValue() and 0 or 1 })
					setEnabled(not enabled:getValue())
				end
			end,
		}, {}),
	})
end
