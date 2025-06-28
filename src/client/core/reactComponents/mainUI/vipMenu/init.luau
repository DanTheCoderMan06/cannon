local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local Trove = require(sharedPackages.Trove)

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
-- Removed zap require
local reactUtil = require(shared.utilities.reactUtil)
local dataController = require(ReplicatedStorage.client.controllers.dataController)
local debugUtil = require(ReplicatedStorage.shared.utilities.debugUtil)

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
	local timeLeftString, setTimeLeftString = React.useBinding("00:00:00")

	React.useEffect(function()
		local uiTrove = Trove.new()
		local timeStart = dataController.getData().timeCreated

		uiTrove:Add(task.spawn(function()
			while true do
				local timeElapsed = 24 * 60 * 60 - (os.time() - timeStart)
				local hours = math.floor(timeElapsed / (60 * 60))
				local minutes = math.floor((timeElapsed % (60 * 60)) / 60)
				local seconds = math.floor(timeElapsed % 60)
				if timeElapsed > 0 then
					setTimeLeftString(string.format("%02d:%02d:%02d", hours, minutes, seconds))
				else
					setTimeLeftString("You will recieve a notification shortly!")
				end

				task.wait(1)
			end
		end))

		return function()
			uiTrove:Destroy()
		end
	end, {})

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
			debugUtil.log(canPromptInNew)
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
		Visible = styles.transparency:map(function(val)
			return val < 1
		end),
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
		mainContent = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://93180824709042",
			Position = UDim2.fromScale(0.49982, 0.499818),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(0.286203, 0.697235),
			Visible = props.vipClaimAvailable,
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
				Position = UDim2.fromScale(-0.0103464, -0.00776214),
				Rotation = -7.5,
				Size = UDim2.fromScale(0.384209, 0.280895),
			}, {
				imageButton = React.createElement("ImageButton", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://84399549169895",
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
						iStroke2 = React.createElement("UIStroke", {
							Color = Color3.fromRGB(12, 86, 4),
							Thickness = 2.4974,
						}),
					}),
				}),
			}),
			var_task = React.createElement("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(255, 247, 187), -- Color3.fromRGB(255, 247, 187)
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.448, 0.055),
				Size = UDim2.fromScale(0.482, 0.322),
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
				Visible = props.tasksDone:map(function(val)
					return val ~= #vipTaskConfig.tasks
				end),
			}, {
				uIGridLayout = React.createElement("UIGridLayout", {
					CellPadding = UDim2.fromScale(0, 0.1),
					CellSize = UDim2.fromScale(1.1, 1.1),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				React.createElement(React.Fragment, nil, tasks),
			}),

			timerFrame = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Visible = props.tasksDone:map(function(val)
					return val == #vipTaskConfig.tasks
				end),
			}, {
				explain = React.createElement("TextLabel", {
					BackgroundColor3 = Color3.fromRGB(238, 238, 238),
					FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
					Position = UDim2.fromScale(0.0590274, 0.43196),
					Size = UDim2.fromScale(0.872775, 0.212053),
					Text = "Play tomorrow to get your VIP!",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}, {
					uICorner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0.025, 8),
					}),

					uIStroke = React.createElement("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(63, 63, 63),
						Thickness = 1.4,
					}),

					uIStroke2 = React.createElement("UIStroke"),
				}),

				timer = React.createElement("TextLabel", {
					BackgroundColor3 = Color3.fromRGB(167, 217, 255),
					FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
					Position = UDim2.fromScale(0.0963714, 0.675428),
					Size = UDim2.fromScale(0.803095, 0.159694),
					Text = timeLeftString,
					TextColor3 = Color3.fromRGB(142, 193, 255),
					TextScaled = true,
				}, {
					uICorner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0.025, 8),
					}),

					uIStroke = React.createElement("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(63, 63, 63),
						Thickness = 1.4,
					}),

					uIStroke2 = React.createElement("UIStroke"),
				}),
			}),

			button = React.createElement("TextButton", {
				BackgroundColor3 = Color3.fromRGB(67, 255, 57),
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(0.143, 0.822),
				Size = UDim2.fromScale(0.714, 0.131),
				Text = canPromptIn:map(function(val)
					return val and "Turn On" or "Done"
				end),
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					props.selectedUIEvent:Fire("")
					if props.promptIn then -- Ensure it still exists before calling
						props.promptIn()
					end
				end,
				Visible = props.tasksDone:map(function(val)
					return val ~= #vipTaskConfig.tasks
				end),
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
				iAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 4.38,
				}),
			}) or nil, -- Render nil if props.promptIn is nil
		}),
	})
end
