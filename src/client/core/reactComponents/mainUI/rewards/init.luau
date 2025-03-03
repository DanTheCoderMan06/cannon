local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local Trove = require(sharedPackages.Trove)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents

local rewards = ReplicatedStorage.client.reactComponents.mainUI.rewards

local rewardsFrame = require(rewards.rewardsFrame)
local closeButton = require(rewards.closeButton)

local firstClaim = false

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 1 }
	end)

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(props.selectedUIEvent:Connect(function(uiName)
			print(uiName)
			local target = 1
			if uiName == "rewards" then
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

		uiTrove:Add(props.claimedItemEvent:Connect(function(itemDay)
			if itemDay == 1 then
				firstClaim = true
			end
		end))

		return function()
			uiTrove:Destroy()
		end
	end, {})

	return React.createElement("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		GroupTransparency = styles.transparency,
		Size = UDim2.fromScale(1, 1),
		Rotation = styles.transparency:map(function(val)
			return 0 * val
		end),
		ZIndex = 10,
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
			Image = "rbxassetid://113193148642368",
			Position = UDim2.fromScale(0.5, 0.5),
			ScaleType = Enum.ScaleType.Fit,
			Size = styles.transparency:map(function(val)
				return UDim2.fromScale(0.638 * math.max(0.2, 1 - val), 0.318 * math.max(0.2, 1 - val))
			end),
		}, {
			rewardsFrame = React.createElement(rewardsFrame, props),
			closeButton = React.createElement(closeButton, {
				styles = styles,
				onActivated = function()
					props.selectedUIEvent:Fire("")
					if firstClaim then
						firstClaim = false
						props.promptIn()
					end
				end,
			}),
			uIScale = React.createElement("UIScale", {
				Scale = 1.1,
			}),

			text = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.206, -0.0156),
				Size = UDim2.fromScale(0.46, 0.3),
				Text = "Daily Rewards",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
			}, {
				uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 4.38,
				}),

				uIStroke = React.createElement("UIStroke", {
					Thickness = 4,
				}),
			}),

			uIAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 3.56,
			}),
		}),
	})
end
