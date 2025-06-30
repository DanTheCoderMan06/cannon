local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents
local reactUtil = require(shared.utilities.reactUtil)

local zap = require(ReplicatedStorage.zap)

local isMobile = UserInputService.TouchEnabled
local lastCalled = 0

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
		FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
		Position = UDim2.fromScale(0.459128, 0.917391),
		Size = UDim2.fromScale(0.0603059, 0.10727),
		Text = enabled:map(function(val)
			return val and "Stop" or "Auto"
		end),
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
	}, {
		iStroke1 = React.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 2.4,
		}),

		iPadding = React.createElement("UIPadding", {
			PaddingBottom = UDim.new(0.1, 0),
			PaddingLeft = UDim.new(0.1, 0),
			PaddingRight = UDim.new(0.1, 0),
			PaddingTop = UDim.new(0.1, 0),
		}),

		iCorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),

		iStroke = React.createElement("UIStroke", {
			Thickness = 2.4,
		}),

		clicker = React.createElement("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Text = "",
			TextColor3 = Color3.fromRGB(21, 208, 11),
			TextScaled = true,
			ZIndex = 100,
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
				if tick() - lastCalled < 0.5 then
					return
				end
				lastCalled = tick()
				SoundService.effects.uiClick:Play()
				local success = zap.toggleAutoFarm.Call()
				if success then
					api.start({ toggle = not enabled:getValue() and 0 or 1 })
					setEnabled(not enabled:getValue())
				end
			end,
		}),

		label = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.0949146, 0.000780814),
			Size = UDim2.fromScale(0.627832, 1.00156),
			Text = "FREE!",
			TextColor3 = Color3.fromRGB(21, 208, 11),
			TextScaled = true,
			ZIndex = 2,
		}, {
			iStroke2 = React.createElement("UIStroke", {
				Color = Color3.fromRGB(12, 86, 4),
				Thickness = 2.4974,
			}),
		}),

		shadow = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.109249, 0.0508585),
			Size = UDim2.fromScale(0.627832, 1.00156),
			Text = "FREE!",
			TextColor3 = Color3.new(),
			TextScaled = true,
		}, {
			iStroke2 = React.createElement("UIStroke", {
				Thickness = 2.4974,
			}),
		}),

		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),
	})
end
