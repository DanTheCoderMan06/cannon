local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
-- Removed Trove require

local generics = ReplicatedStorage.client.reactComponents.generics

local button = require(generics.genericButton)

local isMobile = UserInputService.TouchEnabled

local startTime = tick() -- Restored module-level startTime

local function claimVIPButton(props)
	local styles, api = ReactSpring.useSpring(function()
		return { gold = 0, rotate = 0 }
	end)

	-- Removed startTime binding
	React.useEffect(function()
		-- Removed Trove initialization and management
		props.selectedUIEvent:Connect(function(name)
			if not props.vipClaimAvailable:getValue() then
				return
			end
			if name == "claimVIP" then
				startTime = math.huge -- Use module-level startTime
			else
				startTime = tick() -- Use module-level startTime
			end
		end)
		task.spawn(function()
			while true do
				task.wait(1)
				if not props.menuReadyForDisplay:getValue() then
					startTime = tick()
				end
				if tick() - startTime > 60 then -- Use module-level startTime
					props.setVipClaimAvailable(false)
				end
			end
		end)
		-- Removed Trove destroy
	end, {}) -- Removed props.vipButtonReadyForNewPlayer dependency

	return React.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.182, 0.278),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.12, 0.157),
		Rotation = -7.5,
		Visible = props.vipClaimAvailable, -- Reverted Visible prop
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
			Visible = props.menuReadyForDisplay, -- Second chek
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
					[React.Event.MouseButton1Down] = function()
						SoundService.effects.uiClick:Play()
						task.spawn(function()
							if startTime < 2 * tick() then
								props.selectedUIEvent:Fire("claimVIP")
							else
								props.selectedUIEvent:Fire("")
							end
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
					ZIndex = 23,
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
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, {
		vipButton = React.createElement(claimVIPButton, props),
		shop = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0, 0.5),
			Size = UDim2.fromScale(0.0521, 0.0926),
		}, {
			uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),

			uIListLayout = React.createElement("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			shop = React.createElement("ImageButton", {
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
					overlayImage = "rbxassetid://102670220460799",
					buttonText = "Shop",
					image = "rbxassetid://134400435773268",
					onActivated = function()
						props.selectedUIEvent:Fire("shop")
					end,
				}),
			}),

			uIPadding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0.8, 0),
			}),

			uIScale = React.createElement("UIScale", {
				Scale = isMobile and 1.5 or 1.1,
			}),
		}),
	})
end
