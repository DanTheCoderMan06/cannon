local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local reactUtil = require(shared.utilities.reactUtil)

local generics = ReplicatedStorage.client.reactComponents.generics

local button = require(generics.genericButton)

local isMobile = UserInputService.TouchEnabled

local function claimVIPButton(props)
	local styles, api = ReactSpring.useSpring(function()
		return { gold = 0, rotate = 0 }
	end)

	print("render")

	return React.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(1, 1),
		Visible = props.vipClaimAvailable,
		[React.Event.MouseEnter] = function()
			api.start({
				rotate = 1,
				config = {
					tension = 900,
					friction = 15,
				},
			})
		end,
		[React.Event.MouseLeave] = function()
			api.start({
				rotate = 0,
				config = {
					tension = 900,
					friction = 15,
				},
			})
		end,
	}, {
		content = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = props.image,
			ImageColor3 = Color3.new(1, 1, 1),
			Position = styles.gold:map(function(val)
				return UDim2.fromScale(0.5, 0.5):Lerp(UDim2.fromScale(0.5, 0.55), val)
			end),
			Rotation = styles.rotate:map(function(val)
				return val * 14
			end),
			ScaleType = Enum.ScaleType.Fit,
			Size = styles.rotate:map(function(val)
				return UDim2.fromScale(0.9, 0.9):Lerp(UDim2.fromScale(1, 1), 1 - val)
			end),
			[React.Event.MouseButton1Down] = function()
				SoundService.effects.uiClick:Play()
				task.spawn(function()
					props.selectedUIEvent:Fire("claimVIP")
					api.start({
						gold = 1,
						config = {
							tension = 700,
							friction = 30,
						},
					})
					task.delay(0.05, function()
						api.start({
							gold = 0,
							config = {
								tension = 700,
								friction = 30,
							},
						})
					end)
				end)
			end,
			ZIndex = 5,
		}, {
			uIAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint"),

			React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, {
				imageButton = React.createElement("ImageButton", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://113506016578458",
					Size = UDim2.fromScale(1, 0.904461),
				}, {
					label = React.createElement("TextLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
						Position = UDim2.fromScale(0.83, 1.005),
						Size = UDim2.fromScale(0.498, 0.21),
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
				}),

				shadow = React.createElement("ImageButton", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://113506016578458",
					ImageColor3 = Color3.new(),
					Position = UDim2.fromScale(0, 0.0271335),
					Size = UDim2.fromScale(1, 0.90446),
					ZIndex = 0,
				}, {
					label = React.createElement("TextLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
						Position = UDim2.fromScale(0.83, 1.005),
						Size = UDim2.fromScale(0.498, 0.21),
						Text = "FREE!",
						TextColor3 = Color3.fromRGB(7, 59, 3),
						TextScaled = true,
						ZIndex = 2,
					}, {
						iStroke2 = React.createElement("UIStroke", {
							Color = Color3.fromRGB(12, 86, 4),
							Thickness = 2.4974,
						}),
					}),
				}),

				shadow2 = React.createElement("ImageButton", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://113506016578458",
					ImageColor3 = Color3.new(),
					Position = UDim2.fromScale(0, 0.0271335),
					Size = UDim2.fromScale(1, 0.90446),
					ZIndex = 0,
				}, {
					label = React.createElement("TextLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
						Position = UDim2.fromScale(0.83, 1.005),
						Size = UDim2.fromScale(0.498, 0.21),
						Text = "FREE!",
						TextColor3 = Color3.fromRGB(7, 59, 3),
						TextScaled = true,
						ZIndex = 2,
					}, {
						iStroke2 = React.createElement("UIStroke", {
							Color = Color3.fromRGB(12, 86, 4),
							Thickness = 2.4974,
						}),
					}),
				}),
			}),
		}),
	})
end

return function(props)
	print("Go!!")
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.01, 0.4),
		Size = UDim2.fromScale(0.0521, 0.0926),
	}, {
		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),

		uIListLayout = React.createElement("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		claimVIPButtonFrame = React.createElement(claimVIPButton, props),

		rewardsButton = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(5.76, 1.08),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(6.51, 1.43),
		}, {
			content = React.createElement(button, {
				overlayImage = "rbxassetid://116797538593247",
				buttonText = "Gifts",
				image = "rbxassetid://109156736467684",
				onActivated = function()
					props.selectedUIEvent:Fire("gifts")
				end,
			}),
		}),

		uIPadding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0.8, 0),
		}),

		uIScale = React.createElement("UIScale", {
			Scale = isMobile and 1.5 or 1.1,
		}),
	})
end
