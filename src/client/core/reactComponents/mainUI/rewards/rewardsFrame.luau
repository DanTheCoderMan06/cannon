local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local components = ReplicatedStorage.client.reactComponents
local Trove = require(sharedPackages.Trove)
local Sift = require(sharedPackages.Sift)

local genericButton = require(components.generics.genericButton)

local rewardConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

local dataController = require(ReplicatedStorage.client.controllers.dataController)

local rewardFrame = require(ReplicatedStorage.client.reactComponents.mainUI.rewards.reward)

local zap = require(ReplicatedStorage.zap)

local function viewportFrame(props)
	local viewportRef = React.useRef()

	React.useEffect(function()
		local uiTrove = Trove.new()

		local camera = Instance.new("Camera")
		camera.CameraType = "Scriptable"
		camera.CFrame = CFrame.new()

		local targetFrame = viewportRef:getValue()
		targetFrame.CurrentCamera = camera
		uiTrove:Add(camera)

		local newModel = props.targetModel:FindFirstChildWhichIsA("Model"):Clone()
		newModel:ScaleTo(props.targetModel:GetAttribute("miniSize"))
		newModel:PivotTo(CFrame.new())
		newModel.Parent = targetFrame
		uiTrove:Add(newModel)

		local offsetAngle = 0
		camera.CFrame = CFrame.new() * CFrame.Angles(0, math.rad(-180), 0) * CFrame.new(0, 0, 10)

		uiTrove:BindToRenderStep("rotateViewport" .. tick(), Enum.RenderPriority.Last.Value + 1, function()
			offsetAngle += 0.5
			camera.CFrame = CFrame.new() * CFrame.Angles(0, math.rad(-180 + offsetAngle), 0) * CFrame.new(0, 0, 5)
		end)

		return function()
			uiTrove:Destroy()
		end
	end, {})

	return React.createElement("ViewportFrame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ref = viewportRef,
	})
end

local function imageFrame(props)
	return React.createElement("ImageLabel", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Image = props.image,
	})
end

local rewardsLoaded = false

return function(props)
	local currentData = dataController.getData()
	local rewards = React.useMemo(function()
		local newRewards = {}
		for i, v in pairs(rewardConfig.rewards) do
			local children = {}

			if v.type == "viewport" then
				table.insert(
					children,
					React.createElement(viewportFrame, {
						targetModel = v.model,
					})
				)
			else
				table.insert(
					children,
					React.createElement(imageFrame, {
						image = v.image,
					})
				)
			end

			local isLocked = currentData.daysPlayed < v.day
			local isClaimed = table.find(currentData.daysClaimed, v.day) ~= nil

			table.insert(
				newRewards,
				React.createElement(
					rewardFrame,
					Sift.Dictionary.merge({
						index = v.day,
						onActivated = function()
							SoundService.effects.click:Play()
							zap.claimDailyReward.Fire(v.day)
						end,
						isLocked = isLocked,
						isClaimed = isClaimed,
						name = v.name,
						day = v.day,
						image = children,
					}, props)
				)
			)
		end
		return newRewards
	end, { props, currentData }) -- list dependencies that, when changed, should re-run the computation

	return React.createElement("ScrollingFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(3, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		Selectable = false,
		Size = UDim2.fromScale(0.963, 0.84),
	}, {
		uIListLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0.01, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 4.08,
		}),
		React.createElement(React.Fragment, nil, rewards),
	})
end
