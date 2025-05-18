local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local Trove = require(sharedPackages.Trove)

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
-- Removed zap require
local reactUtil = require(shared.utilities.reactUtil)

local taskFrame = require(script.task)
local closeButton = require(script.closeButton)
local vipTaskConfig = require(shared.config.vipClaimConfig)
local uiON = false

local ExperienceNotificationService = game:GetService("ExperienceNotificationService")

return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 1 }
	end)

	local canPromptIn, setCanPromptIn = React.createBinding(true)

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

		uiTrove:Add(ExperienceNotificationService.OptInPromptClosed:Connect(function()
			task.wait(2)
			local canPromptInNew = true
			pcall(function()
				canPromptInNew = ExperienceNotificationService:CanPromptOptInAsync()
			end)
			setCanPromptIn(canPromptInNew)
		end))

		local canPromptInNew = true
		pcall(function()
			canPromptInNew = ExperienceNotificationService:CanPromptOptInAsync()
		end)
		setCanPromptIn(canPromptInNew)

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
		Visible = props.vipClaimAvailable,
		Size = styles.transparency:map(function(val)
			return UDim2.fromScale(1 - val, 1 - val)
		end),
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

			iScale = React.createElement("UIScale"),

			iAspectRatioConstraint3 = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 0.804,
			}),

			vipIcon = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.02),
				Size = UDim2.fromScale(0.43, 0.34),
			}, {
				container = React.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Rotation = -7.5,
					Size = UDim2.fromScale(1, 1),
				}, {
					button = React.createElement("ImageButton", {
						BackgroundTransparency = 1,
						Image = "rbxassetid://113506016578458",
						Size = UDim2.fromScale(1, 1),
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
							iTextSizeConstraint = React.createElement("UITextSizeConstraint", {
								MaxTextSize = 17,
							}),

							stroke2 = React.createElement("UIStroke", {
								Color = Color3.fromRGB(12, 86, 4),
								Thickness = 3.99583,
							}),
						}),
					}),

					shadow = React.createElement("ImageButton", {
						BackgroundTransparency = 1,
						Image = "rbxassetid://113506016578458",
						ImageColor3 = Color3.new(),
						Position = UDim2.fromScale(0, 0.03),
						Size = UDim2.fromScale(1, 1),
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
							iTextSizeConstraint = React.createElement("UITextSizeConstraint", {
								MaxTextSize = 17,
							}),

							stroke2 = React.createElement("UIStroke", {
								Color = Color3.fromRGB(12, 86, 4),
								Thickness = 3.99583,
							}),
						}),
					}),

					shadow2 = React.createElement("ImageButton", {
						BackgroundTransparency = 1,
						Image = "rbxassetid://113506016578458",
						ImageColor3 = Color3.new(),
						Position = UDim2.fromScale(0, 0.03),
						Size = UDim2.fromScale(1, 1),
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
							iTextSizeConstraint = React.createElement("UITextSizeConstraint", {
								MaxTextSize = 17,
							}),

							stroke2 = React.createElement("UIStroke", {
								Color = Color3.fromRGB(12, 86, 4),
								Thickness = 3.99583,
							}),
						}),
					}),
				}),
			}),
			var_task = React.createElement("TextLabel", {
				BackgroundColor3 = props.tasksDone:map(function(val)
					if val == #vipTaskConfig.tasks then
						return Color3.fromRGB(117, 184, 117)
					else
						return Color3.fromRGB(255, 247, 187)
					end
				end), -- Color3.fromRGB(255, 247, 187)
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.448, 0.055),
				Size = UDim2.fromScale(0.482, 0.322),
				Text = props.tasksDone:map(function(val)
					if val == #vipTaskConfig.tasks then
						return "TASKS DONE! WAIT 24 HOURS!"
					else
						return val .. "/" .. #vipTaskConfig.tasks .. " Tasks"
					end
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
					Thickness = reactUtil.scalePixelSize(4),
				}),

				uIStroke2 = React.createElement("UIStroke"),
			}),

			title = React.createElement("TextLabel", {
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
					Thickness = reactUtil.scalePixelSize(5),
				}),

				iAspectRatioConstraint2 = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 4.38,
				}),
			}),

			tasks = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.87549, 0.172),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}, {
				uIGridLayout = React.createElement("UIGridLayout", {
					CellPadding = UDim2.fromScale(0, 0.1),
					CellSize = UDim2.fromScale(1.1, 1.1),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				React.createElement(React.Fragment, nil, tasks),
			}),

			button = React.createElement("TextButton", {
				BackgroundColor3 = Color3.fromRGB(67, 255, 57),
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.143, 0.822),
				Size = UDim2.fromScale(0.714, 0.131),
				Text = "ENABLE",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					props.selectedUIEvent:Fire("")
					if props.promptIn then -- Ensure it still exists before calling
						props.promptIn()
					end
				end,
				Visible = canPromptIn,
			}, {
				uIStroke = React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.fromRGB(25, 115, 0),
					Thickness = reactUtil.scalePixelSize(4),
				}),

				uICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0.025, 8),
				}),

				uIStroke2 = React.createElement("UIStroke"), -- This stroke doesn't have a Thickness defined, so it's not scaled.
			}) or nil, -- Render nil if props.promptIn is nil
		}),
	})
end
