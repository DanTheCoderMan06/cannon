local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local Trove = require(sharedPackages.Trove)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents
local reactUtil = require(shared.utilities.reactUtil)

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { hover = 0, clicked = 0 }
	end)

	local claimed, setIsClaimed = React.useBinding(props.isClaimed)
	local locked, setIsLocked = React.useBinding(props.isLocked)

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(props.claimedItemEvent:Connect(function(itemDay)
			if itemDay == props.day then
				setIsClaimed(true)
			end
		end))

		uiTrove:Add(props.unlockedItemEvent:Connect(function(itemDay)
			if itemDay == props.day then
				setIsLocked(false)
			end
		end))

		uiTrove:Add(props.resetEvent:Connect(function()
			setIsClaimed(true)
			setIsLocked(true)
		end))

		return function()
			uiTrove:Destroy()
		end
	end, {})

	return React.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Image = "rbxassetid://95213254815108",
		LayoutOrder = props.index,
		Position = UDim2.fromScale(0.101, 0.714),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.0641 / 2, 1.1),
	}, {
		day = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.5, 0.0221),
			Size = UDim2.fromScale(0.938, 0.182),
			Text = "Day " .. props.index,
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

		name = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0.5, 0.686),
			Size = UDim2.fromScale(0.86, 0.287),
			Text = props.name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
		}, {
			uIAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 4.38,
			}),

			uIStroke1 = React.createElement("UIStroke", {
				Thickness = reactUtil.scalePixelSize(4),
			}),
		}),

		uIAspectRatioConstraint2 = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 1,
		}),

		ClaimButtonContainer = React.createElement(
			"Frame",
			{ -- This Frame handles position, size, rotation, visibility
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = 3,
				Position = styles.clicked:map(function(val)
					return UDim2.fromScale(0.497, 0.913):Lerp(UDim2.fromScale(0.497, 0.913 + 0.02), val)
				end),
				Size = styles.hover:map(function(val)
					return UDim2.fromScale(0.694 * 0.9, 0.255 * 0.9):Lerp(UDim2.fromScale(0.694, 0.255), val)
				end),
				Visible = locked:map(function(val)
					return not val
				end),
				Rotation = styles.hover:map(function(val)
					return val * 5
				end),
			},
			{
				uIScaleContainer = React.createElement("UIScale", {
					Scale = _G.isMobile and 1.2 or 1,
				}),
				uIAspectRatioConstraintContainer = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 2.73,
				}),

				ShadowImageButton = React.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, reactUtil.scalePixelSize(3)), -- Only vertical offset
					Size = UDim2.fromScale(1, 1),
					Image = claimed:map(function(val)
						return val and "rbxassetid://105652446380406" or "rbxassetid://133893845022134"
					end),
					ImageColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScaleType = Enum.ScaleType.Fit,
					Active = false,
					Selectable = false,
					ZIndex = 1,
				}),

				MainClaimImageButton = React.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Image = claimed:map(function(val)
						return val and "rbxassetid://105652446380406" or "rbxassetid://133893845022134"
					end),
					Position = UDim2.fromScale(0.5, 0.5),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 2,
				}, {
					text = React.createElement("TextLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.723, 0.862),
						Text = claimed:map(function(val)
							return val and "Claimed" or "Claim"
						end),
						TextColor3 = styles.clicked:map(function(val)
							local isClaimedValue = claimed:getValue() -- Get current boolean value
							return Color3.fromRGB(255, 255, 255):Lerp(
								isClaimedValue and Color3.fromRGB(255, 128, 128) or Color3.fromRGB(134, 231, 199),
								val
							)
						end),
						TextScaled = true,
						TextSize = 14,
						TextWrapped = true,
						ZIndex = 3,
					}, {
						uIStroke2 = React.createElement("UIStroke", {
							Thickness = reactUtil.scalePixelSize(4),
						}),
					}),
				}),

				ClickTargetButton = React.createElement("ImageButton", { -- Transparent button for interaction
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1, -- Make image part transparent too
					ZIndex = 10, -- Ensure it's on top for clicks
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
						if claimed:getValue() then
							return
						end -- Don't do anything if already claimed
						SoundService.effects.uiClick:Play()
						task.spawn(function()
							api.start({
								clicked = 1,
								config = {
									tension = 700,
									friction = 30,
								},
							})
							props.onActivated()
							task.delay(0.05, function()
								api.start({
									clicked = 0,
									config = {
										tension = 700,
										friction = 30,
									},
								})
							end)
						end)
					end,
				}),
			}
		),

		image = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.438),
			Size = UDim2.fromScale(0.74, 0.821),
			ZIndex = -1,
		}, {
			uIAspectRatioConstraint4 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1.06,
			}),
			React.createElement(React.Fragment, nil, props.image),
		}),
	})
end
