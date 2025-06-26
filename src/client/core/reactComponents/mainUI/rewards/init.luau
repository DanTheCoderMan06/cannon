local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local Trove = require(sharedPackages.Trove)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents
local reactUtil = require(shared.utilities.reactUtil)

local rewards = ReplicatedStorage.client.reactComponents.mainUI.rewards

local rewardsFrame = require(rewards.rewardsFrame)
local closeButton = require(rewards.closeButton)

local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local dataController = require(ReplicatedStorage.client.controllers.dataController)

local firstClaim = false
local firstTime = false

local uiON = false

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 1 }
	end)

	local timeLeft, settTimeLeft = React.useBinding(0)
	local lastClaimed, setLastClaimed = React.useBinding(0)

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(props.selectedUIEvent:Connect(function(uiName)
			local target = 1
			if uiName == "rewards" then
				if not uiON then
					target = 0
				end
			elseif uiON then
				if firstTime or RunService:IsStudio() then
					firstTime = false
					if ExperienceNotificationService:CanPromptOptInAsync() then
						ExperienceNotificationService:PromptOptIn()
					end
				end
			end
			uiON = not uiON
			api.start({
				transparency = target,
				config = {
					tension = 400,
					friction = 25,
				},
			})
		end))

		uiTrove:Add(dataController.dataChanged:Connect(function(data)
			if data.firstTimeRewards then
				firstTime = true
			end
		end))

		uiTrove:Add(props.claimedItemEvent:Connect(function(itemDay)
			if itemDay == 1 then
				firstClaim = true
			end
		end))

		uiTrove:Add(
			dataController.dataChanged:Connect(function(data)
				setLastClaimed(data.lastClaimed)
			end),
			"Disconnect"
		)

		uiTrove:Add(task.spawn(function()
			while true do
				task.wait(1)
				local seconds = 24 * 60 * 60 - (os.time() - lastClaimed:getValue())
				settTimeLeft(seconds)
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
		Visible = styles.transparency:map(function(val)
			return val < 1
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
			rewardsFrameContainer = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				ClipsDescendants = true,
			}, {
				rewardsFrame = React.createElement(rewardsFrame, props),
			}),
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
					Thickness = reactUtil.scalePixelSize(4),
				}),
			}),

			uIAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 3.56,
			}),

			timerFrame = React.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = "rbxassetid://85156488647867",
				LayoutOrder = 3,
				Position = UDim2.fromScale(0.497602, 1.075),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.216564, 0.304808),
			}, {
				untilNextReward = React.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
					Position = UDim2.fromScale(0.505682, 0.492131),
					Size = UDim2.fromScale(1.19, 0.658147),
					Text = timeLeft:map(function(val)
						if val == 0 then
							return "Processing"
						else
							return reactUtil.secondsToHHMMSS(val)
						end
					end),
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}, {
					iAspectRatioConstraint3 = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 4.38,
					}),

					uIStroke = React.createElement("UIStroke", {
						Thickness = 1.6,
					}),
				}),

				iAspectRatioConstraint2 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 2.77,
				}),

				clicker = React.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.50787),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1.09514),
					ZIndex = 10,
				}),

				iScale = React.createElement("UIScale"),
			}),
		}),
	})
end
