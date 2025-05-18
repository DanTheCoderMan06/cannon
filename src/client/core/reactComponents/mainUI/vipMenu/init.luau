local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local Trove = require(sharedPackages.Trove)

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)

local taskFrame = require(script.task)
local closeButton = require(script.closeButton)
local vipTaskConfig = require(shared.config.vipClaimConfig)
local uiON = false

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 1 }
	end)

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(props.selectedUIEvent:Connect(function(uiName)
			local target = 1
			if uiName == "claimVIP" then
				if not uiON then
					target = 0
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

		return function()
			uiTrove:Destroy()
		end
	end, {})

	local tasks = React.useMemo(function()
		local _tasks = {}

		for _, v in pairs(vipTaskConfig.tasks) do
			table.insert(
				_tasks,
				React.createElement(taskFrame, {
					eventCompleted = props.eventCompleted,
					name = v.name,
					taskText = v.taskText,
				})
			)
		end

		return _tasks
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
		React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://93180824709042",
			Position = UDim2.fromScale(0.49982, 0.499818),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(0.286203, 0.697235),
		}, {
			closeButton = React.createElement(closeButton, {
				onActivated = function()
					props.selectedUIEvent:Fire("")
				end,
			}),
			button = React.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.984, -0.00141),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.129, 0.238),
				ZIndex = 5,
			}, {
				iAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),

				content = React.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "rbxassetid://123565630442478",
					Position = UDim2.fromScale(0.5, 0.5),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(0.95, 0.95),
					ZIndex = 5,
				}, {
					text = React.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Image = "rbxassetid://91168667582185",
						Position = UDim2.fromScale(0.503, 0.469),
						Rotation = 5,
						ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.fromScale(0.532, 0.645),
						ZIndex = 7,
					}, {
						iAspectRatioConstraint1 = React.createElement("UIAspectRatioConstraint", {
							AspectRatio = 0.872,
						}),
					}),
				}),
			}),

			iScale = React.createElement("UIScale"),

			iAspectRatioConstraint3 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 0.804,
			}),

			text1 = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.0496, -0.0156),
				Rotation = -12,
				Size = UDim2.fromScale(0.494, 0.0911),
				Text = "VIP",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}, {
				iStroke = React.createElement("UIStroke", {
					Thickness = 2.6,
				}),

				iAspectRatioConstraint2 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 4.38,
				}),
			}),

			vIPpopup = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.0178565, 0.0171159),
				Rotation = -7.5,
				Size = UDim2.fromScale(0.238738, 0.193984),
			}, {
				imageButton = React.createElement("ImageButton", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://113506016578458",
					Position = UDim2.fromScale(0.000321816, 0.000382973),
					Size = UDim2.fromScale(0.992717, 1.00326),
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

						uITextSizeConstraint = React.createElement("UITextSizeConstraint", {
							MaxTextSize = 17,
						}),
					}),
				}),

				shadow = React.createElement("ImageButton", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://113506016578458",
					ImageColor3 = Color3.new(),
					Position = UDim2.fromScale(0.000279814, 0.0305231),
					Size = UDim2.fromScale(0.992717, 1.00326),
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

						uITextSizeConstraint = React.createElement("UITextSizeConstraint", {
							MaxTextSize = 17,
						}),
					}),
				}),

				shadow2 = React.createElement("ImageButton", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://113506016578458",
					ImageColor3 = Color3.new(),
					Position = UDim2.fromScale(0.000279814, 0.0305231),
					Size = UDim2.fromScale(0.992717, 1.00326),
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

						uITextSizeConstraint = React.createElement("UITextSizeConstraint", {
							MaxTextSize = 17,
						}),
					}),
				}),

				uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),
			}),

			var_task = React.createElement("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(255, 247, 187),
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.372377, 0.122822),
				Size = UDim2.fromScale(0.482156, 0.0577395),
				Text = props.tasksDone:map(function(val)
					return val .. "/" .. #vipTaskConfig.tasks .. " Tasks"
				end),
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}, {
				uICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0.025, 8),
				}),

				uIStroke = React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.fromRGB(157, 154, 71),
					Thickness = 2,
				}),

				uIStroke2 = React.createElement("UIStroke"),
			}),

			label = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.617849, 0.0784711),
				Size = UDim2.fromScale(0.472024, 0.105442),
				Text = "VIP PROGRESS",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}, {
				iAspectRatioConstraint4 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 4.38,
				}),

				iStroke1 = React.createElement("UIStroke", {
					Thickness = 2,
				}),
			}),

			tasks = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.0617816, 0.226555),
				Size = UDim2.fromScale(0.87549, 0.133739),
			}, {
				uIGridLayout = React.createElement("UIGridLayout", {
					CellPadding = UDim2.fromScale(0, 0.1),
					CellSize = UDim2.fromScale(1, 1),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				React.createElement(React.Fragment, nil, tasks),
			}),

			turnon = React.createElement("TextButton", {
				BackgroundColor3 = Color3.fromRGB(67, 255, 57),
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.293973, 0.908046),
				Size = UDim2.fromScale(0.411065, 0.0624597),
				Visible = props.completed,
				Text = "CLAIM",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}, {
				uIStroke = React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.fromRGB(25, 115, 0),
					Thickness = 2,
				}),

				uICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0.025, 8),
				}),

				uIStroke2 = React.createElement("UIStroke"),
			}),
		}),
	})
end
