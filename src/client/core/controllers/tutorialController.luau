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

local nextPageSignal = Signal.new()

local tutorialItems

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
				print("Toggle event received:", toggle)
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
	toggleEvent:Fire(false)
	if tutorialItems then
		tutorialItems:Destroy()
	end

	oldActionTrove = nil
end

function tutorialController.startTutorial()
	if RAN_TUTORIAL then
		return
	end
	RAN_TUTORIAL = true
	if toggleEvent then
		toggleEvent:Fire(true)
	else
		loadedSignal:Connect(function()
			toggleEvent:Fire(true)
		end)
	end
	local currentIndex = 1
	tutorialItems = ReplicatedStorage.assets.tutorial:Clone()
	tutorialItems.Parent = workspace

	nextPageSignal:Connect(function()
		currentIndex += 1
		tutorialController.loadPage(currentIndex)
	end)

	local rainbowTrove = Trove.new()
	local startedTime = tick()

	rainbowTrove:BindToRenderStep("rainbowTutorial", Enum.RenderPriority.Last.Value, function(dt)
		if tutorialItems and tutorialItems.beam then
			tutorialItems.beam.Color = ColorSequence.new(reactUtil.getSmoothColorFromElapsedTime(tick() - startedTime))
		end
	end)

	tutorialController.loadPage(currentIndex)

	task.wait()
	tutorialItems.Parent = workspace
	rainbowTrove:AttachToInstance(tutorialItems)
end

function tutorialController.start()
	loadedSignal = Signal.new()

	task.delay(0.25, function()
		local container = ReactRoblox.createRoot(Instance.new("Folder"))
		container:render(
			ReactRoblox.createPortal(React.createElement(app), Players.LocalPlayer.PlayerGui, "tutorialUI")
		)

		local connection

		connection = dataController.dataChanged:Connect(function(newData)
			if newData.firstTime then
				connection:Disconnect()
				tutorialController.startTutorial()
			end
		end)

		loadedSignal:Wait()
	end)

	--Set up guiding beam
	local guiderModel = ReplicatedStorage.assets.guiding:Clone()
	guiderModel.Parent = workspace
	guiderModel.Name = "initialGuider"
	local start = tick()
	RunService:BindToRenderStep("guidingBeam", Enum.RenderPriority.Last.Value + 1, function()
		if RAN_TUTORIAL then
			guiderModel.beam.Enabled = false
			return
		end
		local character = Players.LocalPlayer.Character
		if not character then
			guiderModel.beam.Enabled = false
			return
		end
		if character:GetAttribute("inCannon") then
			guiderModel.beam.Enabled = false
			return
		end

		local localPlayerPlatform = workspace.playerPlatforms:WaitForChild(Players.LocalPlayer.Name)
		local currentData = dataController.getData()
		local targetCFrame
		local shouldEnableBeam = true -- Flag to control beam visibility

		-- Condition 1: Disable if cannon level is 20 or higher
		if currentData.cannon >= 20 then
			shouldEnableBeam = false
		end

		-- Determine target only if beam might be enabled
		if shouldEnableBeam then
			local canAffordCannon = currentData.money
				>= cannonConfig.costFormula(currentData.cannon + 1, currentData.boughtLevels)
			local canAffordFloor = currentData.money
				>= floorsConfig.costFormula(currentData.floors + 1, currentData.boughtFloors)

			if canAffordCannon then
				targetCFrame = localPlayerPlatform.platforms:WaitForChild("cannon").CFrame
			elseif canAffordFloor then
				targetCFrame = localPlayerPlatform.platforms:WaitForChild("floor").CFrame
				-- Condition 2: If target is floor AND player is viewing another tower, point to cannon instead
				if localPlayerPlatform:GetAttribute("currentTower") ~= Players.LocalPlayer.Name then
					targetCFrame = localPlayerPlatform:WaitForChild("cannonPosition", true).CFrame -- Point to cannon
					-- Beam remains enabled (shouldEnableBeam is not set to false here)
				end
			else
				-- Cannot afford either upgrade, point to cannon entrance
				targetCFrame = localPlayerPlatform:WaitForChild("cannonPosition", true).CFrame
			end
		end

		-- Set beam properties based on final decision
		guiderModel.beam.Enabled = shouldEnableBeam
		if shouldEnableBeam then
			guiderModel.beam.Color = ColorSequence.new(reactUtil.getSmoothColorFromElapsedTime(tick() - start, 1))
			guiderModel.beamPart.start.WorldCFrame = character.HumanoidRootPart.CFrame
			guiderModel.beamPart.target.WorldCFrame = targetCFrame
		end
	end)
end

return tutorialController
