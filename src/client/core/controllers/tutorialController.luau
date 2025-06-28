local tutorialController = {}

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local sharedPackages = ReplicatedStorage.sharedPackages
local React = require(sharedPackages.React)
local ReactRoblox = require(sharedPackages.ReactRoblox)
local ReactSpring = require(sharedPackages.ReactSpring)

local sharedPackages = ReplicatedStorage.sharedPackages
local Signal = require(sharedPackages.Signal)
local Trove = require(sharedPackages.Trove)
local Sift = require(sharedPackages.Sift)
local tutorialUI = require(ReplicatedStorage.client.reactComponents.tutorial)

local zap = require(ReplicatedStorage.zap)

local toggleEvent
local text, setText = React.createBinding()
local loadedSignal

local oldActionTrove = Trove.new()

local effectsController = require(ReplicatedStorage.client.controllers.effectsController)
local dataController = require(ReplicatedStorage.client.controllers.dataController)
local castleController = require(ReplicatedStorage.client.controllers.castleController)
local cannonController = require(ReplicatedStorage.client.controllers.cannonController)

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local floorsConfig = require(ReplicatedStorage.shared.config.floorConfig)
local tutorialConfig = require(ReplicatedStorage.shared.config.tutorialConfig)

local reactUtil = require(ReplicatedStorage.shared.utilities.reactUtil)
local debugUtil = require(ReplicatedStorage.shared.utilities.debugUtil)

local nextPageSignal = Signal.new()

local tutorialItems
local tutorialArrowTemplate = ReplicatedStorage.assets.effects:WaitForChild("tutorialArrow")

local RAN_TUTORIAL = false

local function app()
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 1 }
	end)

	toggleEvent = Signal.new()

	React.useEffect(function()
		local uiTrove = Trove.new()

		uiTrove:Add(
			toggleEvent:Connect(function(toggle)
				debugUtil.log("Toggle event received:", toggle)
				api.start({
					transparency = toggle and 0 or 1,
					config = {
						tension = 300,
						friction = 30,
					},
				})
			end),
			"Disconnect"
		)

		loadedSignal:Fire()

		return function()
			uiTrove:Destroy()
		end
	end, {})

	return React.createElement("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		DisplayOrder = 1,
		IgnoreGuiInset = true,
	}, {
		content = React.createElement(tutorialUI, {
			styles = styles,
			text = text,
			endTutorial = tutorialController.endTutorial,
			toggleEvent = toggleEvent,
		}),
	})
end

function tutorialController.loadPage(index)
	local pageInfo = tutorialConfig.steps[index]
	if not pageInfo then
		tutorialController.endTutorial()
		return
	end

	setText(pageInfo.text)

	if oldActionTrove then
		oldActionTrove:Destroy()
		oldActionTrove = nil
	end
	oldActionTrove = Trove.new()

	-- Arrow spawning loop for this page
	oldActionTrove:Add(task.spawn(function()
		while true do
			if tutorialItems and tutorialItems.Parent and tutorialItems.beam.Attachment0 and tutorialItems.beam.Attachment1 then
				local arrow = tutorialArrowTemplate:Clone()
				arrow:SetAttribute("timeCreated", tick())
				arrow.Parent = tutorialItems.ArrowsFolder
			end
			task.wait(.2)
		end
	end))

	pageInfo.action(tutorialItems, nextPageSignal, {
		getData = dataController.getData,
		dataChanged = dataController.dataChanged,
		togglePlatform = castleController.togglePlatform,
		toggleAllPlatforms = castleController.toggleAllPlatforms,
		toggleEntrance = cannonController.toggleEntrance,
		trove = oldActionTrove,
	})
end

function tutorialController.endTutorial()
	castleController.toggleAllPlatforms(true)
	cannonController.toggleEntrance(true)
	RAN_TUTORIAL = false
	nextPageSignal:Destroy()
	if tutorialItems then
		tutorialItems:Destroy()
	end

	oldActionTrove = nil
	Players.LocalPlayer:SetAttribute("inTutorial", false)
end

function tutorialController.startTutorial()
	if RAN_TUTORIAL  then
		return
	end
	Players.LocalPlayer:SetAttribute("inTutorial", true)
	RAN_TUTORIAL = true
	if toggleEvent then
		toggleEvent:Fire(true)
	else
		loadedSignal:Connect(function()
			toggleEvent:Fire(true)
		end)
	end
	local currentIndex = 1
	tutorialItems = ReplicatedStorage.assets.effects.tutorial:Clone()
	tutorialItems.Parent = workspace
	tutorialItems.beam.Enabled = false -- Disable the beam

	local arrowsFolder = Instance.new("Folder")
	arrowsFolder.Name = "ArrowsFolder"
	arrowsFolder.Parent = tutorialItems

	nextPageSignal:Connect(function()
		debugUtil.log("Next page!")
		currentIndex += 1
		tutorialController.loadPage(currentIndex)
	end)

	local rainbowTrove = Trove.new()
	local startedTime = tick()
	local LERP_DURATION = 1.5

	rainbowTrove:BindToRenderStep("arrowTutorial", Enum.RenderPriority.Last.Value, function(dt)
		if not tutorialItems or not tutorialItems.Parent then
			rainbowTrove:Destroy()
			return
		end

		local startPos = tutorialItems.beam.Attachment0 and tutorialItems.beam.Attachment0.WorldPosition
		local endPos = tutorialItems.beam.Attachment1 and tutorialItems.beam.Attachment1.WorldPosition

		if not startPos or not endPos or (startPos - endPos).Magnitude < 1 then
			arrowsFolder:ClearAllChildren()
			return
		end

		for _, arrow in ipairs(arrowsFolder:GetChildren()) do
			local timeCreated = arrow:GetAttribute("timeCreated")
			if not timeCreated then
				continue
			end

			local alpha = (tick() - timeCreated) / LERP_DURATION
			if alpha >= 1 then
				arrow:Destroy()
				continue
			end

			arrow.CFrame = CFrame.new(startPos:Lerp(endPos, alpha), endPos) 
			arrow.CFrame *= CFrame.Angles(0,math.rad(135),0)
			arrow.Color = reactUtil.getSmoothColorFromElapsedTime(tick() - startedTime)
		end
	end)

	rainbowTrove:AttachToInstance(tutorialItems)
	tutorialController.loadPage(currentIndex)
end

function tutorialController.start()
	loadedSignal = Signal.new()

	task.delay(0.25, function()
		--[[
		local container = ReactRoblox.createRoot(Instance.new("Folder"))
		container:render(
			ReactRoblox.createPortal(React.createElement(app), Players.LocalPlayer.PlayerGui, "tutorialUI")
		)
		--]]

		local connection

		connection = dataController.dataChanged:Connect(function(newData)
			if newData.cannon == 1 then
				connection:Disconnect()
				tutorialController.startTutorial()
			end
		end)

		loadedSignal:Wait()
	end)

	--Set up guiding beam
	local guiderModel = ReplicatedStorage.assets.effects.guiding:Clone()
	guiderModel.Parent = workspace
	guiderModel.Name = "initialGuider"
	guiderModel.beam.Enabled = false -- Disable the beam

	local guiderArrowsFolder = Instance.new("Folder")
	guiderArrowsFolder.Name = "ArrowsFolder"
	guiderArrowsFolder.Parent = guiderModel

	local lastArrowSpawn = 0
	local start = tick()
	local LERP_DURATION = 1.5

	RunService:BindToRenderStep("guidingBeam", Enum.RenderPriority.Last.Value + 1, function()
		if RAN_TUTORIAL then
			guiderModel:Destroy()
			RunService:UnbindFromRenderStep("guidingBeam") -- Clean up
			return
		end

		local character = Players.LocalPlayer.Character
		if not character or not character.PrimaryPart or character:GetAttribute("inCannon") then
			guiderArrowsFolder:ClearAllChildren()
			return
		end

		local localPlayerPlatform = workspace.playerPlatforms:WaitForChild(Players.LocalPlayer.Name)
		local currentData = dataController.getData()
		local targetCFrame
		local shouldEnableArrows = true

		if currentData.cannon >= 10 then
			shouldEnableArrows = false
		end

		if shouldEnableArrows then
			local canAffordCannon = currentData.money
				>= cannonConfig.costFormula(currentData.cannon + 1, currentData.boughtLevels)
			local canAffordFloor = currentData.money
				>= floorsConfig.costFormula(currentData.floors + 1, currentData.boughtFloors)

			if canAffordCannon then
				targetCFrame = localPlayerPlatform.platforms:WaitForChild("oneLevel").CFrame
			elseif canAffordFloor then
				targetCFrame = localPlayerPlatform.platforms:WaitForChild("upgradeFloor").CFrame
				if localPlayerPlatform:GetAttribute("currentTower") ~= Players.LocalPlayer.Name then
					targetCFrame = localPlayerPlatform:WaitForChild("cannonPosition", true).CFrame
				end
			else
				targetCFrame = localPlayerPlatform:WaitForChild("cannonPosition", true).CFrame
			end
		end

		if not shouldEnableArrows or not targetCFrame then
			guiderArrowsFolder:ClearAllChildren()
			return
		end

		-- Spawn new arrow every 2 seconds
		if tick() - lastArrowSpawn > .2 then
			local arrow = tutorialArrowTemplate:Clone()
			arrow:SetAttribute("timeCreated", tick())
			arrow.Parent = guiderArrowsFolder
			lastArrowSpawn = tick()
		end

		-- Update existing arrows
		local startPos = character.PrimaryPart.Position
		for _, arrow in ipairs(guiderArrowsFolder:GetChildren()) do
			local timeCreated = arrow:GetAttribute("timeCreated")
			if not timeCreated then
				continue
			end

			local alpha = (tick() - timeCreated) / LERP_DURATION
			if alpha >= 1 then
				arrow:Destroy()
				continue
			end

			arrow.CFrame = CFrame.new(startPos:Lerp(targetCFrame.Position, alpha), targetCFrame.Position)
			arrow.CFrame *= CFrame.Angles(0,math.rad(135),0)
			arrow.Color = reactUtil.getSmoothColorFromElapsedTime(tick() - start)
		end
	end)
end

return tutorialController
