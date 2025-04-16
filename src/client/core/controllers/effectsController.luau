local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local effectsController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local React = require(game.ReplicatedStorage.sharedPackages.React)
local ReactSpring = require(game.ReplicatedStorage.sharedPackages.ReactSpring)
local ReactRoblox = require(game.ReplicatedStorage.sharedPackages.ReactRoblox)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local zap = require(ReplicatedStorage.zap)

local config = require(ReplicatedStorage.shared.config.effectsConfig)
local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local floorConfig = require(ReplicatedStorage.shared.config.floorConfig)

local effectsUi = require(ReplicatedStorage.client.reactComponents.generics.effectText)
local finishedPath = require(ReplicatedStorage.client.reactComponents.generics.finishedPath)

-- Store references to preloaded UI elements
local preloadedUI = {
	container = nil,
	billboardRef = nil,
	mounted = false,
}

local dataController = require(ReplicatedStorage.client.controllers.dataController)
local stateController = require(ReplicatedStorage.client.controllers.stateController)
local keysController = require(ReplicatedStorage.client.controllers.keysController)

local reactUtil = require(ReplicatedStorage.shared.utilities.reactUtil)

local currentHighScore = 0

function effectsController.playDanceAnimation()
	local newAnim = ReplicatedStorage.assets.animations.dance
		:GetChildren()[math.random(1, #ReplicatedStorage.assets.animations.dance:GetChildren())]
		:Clone()

	local track = Players.LocalPlayer.Character:FindFirstChildWhichIsA("Animator", true):LoadAnimation(newAnim)
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = true
	track:Play()
	return track, newAnim -- Return track and animation instance
end

function effectsController.getHighScore()
	for _, v in pairs(Players.LocalPlayer:WaitForChild("leaderstats"):GetChildren()) do
		if v:GetAttribute("statName") == "highscore" then
			return v
		end
	end
end

function app(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 1 }
	end)

	React.useEffect(function()
		print("start")
		api.start({
			transparency = 0,
			config = {
				tension = 300,
				friction = 30,
			},
		})
		task.delay(1, function()
			if props.callback then
				props.callback()
			end
		end)
		task.wait(props.duration + 1.5)
		api.start({
			transparency = 1,
			config = {
				tension = 300,
				friction = 30,
			},
		})
	end, {})

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 0.0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = styles.transparency,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.),
		Size = UDim2.fromScale(1, 1),
	})
end

function effectsController.blackScreen(duration, callback)
	local newBlackScreen = ReactRoblox.createRoot(Instance.new("Folder"))
	newBlackScreen:render(ReactRoblox.createPortal(
		React.createElement("ScreenGui", {
			ResetOnSpawn = false,
			Enabled = true,
			IgnoreGuiInset = true,
			DisplayOrder = 10000,
		}, {
			main = React.createElement(app, { duration = duration, callback = callback }),
		}),
		Players.LocalPlayer.PlayerGui,
		"blackScreen"
	))

	task.delay(duration + 6, function()
		newBlackScreen:unmount()
	end)
end

function effectsController.updateHighscore()
	local newHighScore = effectsController.getHighScore().Value
	if newHighScore <= currentHighScore then
		return
	end
	currentHighScore = newHighScore
	local hsArea = workspace:FindFirstChild("highscorePlate")
	if not hsArea then
		hsArea = ReplicatedStorage.assets:WaitForChild("highscorePlate")
		hsArea.Parent = workspace
	end
	hsArea:FindFirstChild("record", true).Text = newHighScore .. " studs"
	local calculatedPosition = CFrame.new(workspace.castles:WaitForChild(Players.LocalPlayer.Name).Position)
		* CFrame.new(0, 0, -math.fmod(newHighScore, cannonConfig.maxDistance))
	hsArea:PivotTo(calculatedPosition)
end

function effectsController.rewardPopup(location: Vector3, text: string)
	local p = ReplicatedStorage.assets.effectRewardPart:Clone()
	p.Position = location
	p.Parent = workspace

	local container = ReactRoblox.createRoot(Instance.new("Folder"))
	container:render(
		ReactRoblox.createPortal(
			React.createElement(effectsUi, { Adornee = p, text = text }, {}),
			Players.LocalPlayer.PlayerGui,
			"point: " .. tostring(location)
		)
	)

	task.delay(0.4, function()
		for _, v in pairs(p:GetChildren()) do
			v.Enabled = false
		end
	end)

	task.delay(2, function()
		container:unmount()
		p:Destroy()
	end)
end

function effectsController.start()
	local localPlayer = Players.LocalPlayer
	local clouds = Instance.new("Clouds")
	clouds.Parent = workspace.Terrain
	clouds.Cover = 0
	RunService:BindToRenderStep("effectsHandler", Enum.RenderPriority.Last.Value, function()
		local character = localPlayer.Character
		if not character then
			return
		end
		local part = character.PrimaryPart
		if not part then
			return
		end
		local currentAltitude = math.abs(part.Position.Y)
		if math.round(Lighting.ClockTime * 10) / 10 == 12 or math.round(Lighting.ClockTime * 10) / 10 > 22 then
			spr.target(Lighting, 1, 0.75, {
				ClockTime = if currentAltitude > config.nightSky then 23.9 else 12,
			})
		end

		-- Cloud logic to match the step pattern: 0 -> 100% -> 0 for each interval
		local cloudBand = math.floor(currentAltitude / config.cloudSky)
		local adjustedAltitude = currentAltitude - (cloudBand * config.cloudSky)
		local cloudTarget = 0

		-- Divide the interval into 4 equal parts
		local segmentSize = config.cloudSky / 4

		if adjustedAltitude < segmentSize then
			-- First segment - starts at 0, transitions to 100%
			cloudTarget = (adjustedAltitude / segmentSize)
		elseif adjustedAltitude < segmentSize * 3 then
			-- Middle segments - maintain 100% cloud cover
			cloudTarget = 1.0
		else
			-- Final segment - transitions from 100% back to 0
			cloudTarget = 1.0 - ((adjustedAltitude - segmentSize * 3) / segmentSize)
		end

		-- Clamp values between 0 and 1 to handle any edge cases
		cloudTarget = math.clamp(cloudTarget, 0, 1)

		-- Only update cloud cover if it needs to change significantly
		if math.abs(clouds.Cover - cloudTarget) > 0.01 then
			spr.target(clouds, 1, 0.75, {
				Cover = cloudTarget,
			})
		end
	end)

	effectsController.updateHighscore()
end

-- Preload the finishedPathUI so it's ready to be displayed when needed
function effectsController.preloadFinishedPathUI(results)
	-- Validate results before proceeding
	if not results or typeof(results.distance) ~= "number" then
		print("Warning: Invalid results data passed to preloadFinishedPathUI. Skipping preload.", results)
		preloadedUI.mounted = false -- Ensure mounted is false if preload fails
		return -- Exit early
	end

	local character = Players.LocalPlayer.Character
	local isHighscore = effectsController.getHighScore().Value < math.round(results.distance)
	local playerData = dataController.currentData
	local reward = cannonConfig.rewardFormula(results.distance, playerData.floors or 0)
	local targetColor, setTargetColor = React.createBinding(Color3.new())
	local startTime = tick()

	if not playerData.boughtCannonYet then
		local firstCannonCost = cannonConfig.costFormula(playerData.cannon, 1) -- Cost for level 1 from level 0
		reward += firstCannonCost
	end

	-- Check for first floor purchase bonus
	-- Assumes 'boughtFloorYet' boolean exists in playerData, otherwise this check might grant bonus repeatedly.
	if not playerData.boughtFloorYet then
		local firstFloorCost = floorConfig.costFormula(playerData.floors, 0) -- Cost for level 1 from level 0
		reward += firstFloorCost
	end

	local newMoney = reward
	if playerData.doubleMoney then
		newMoney += reward
	end

	local gainedFloors = 0
	while newMoney > 0 and gainedFloors < 100 do
		local newFloors = 1
		local floorCost = floorConfig.costFormula(playerData.floors + gainedFloors, playerData.boughtLevels)
		if floorCost > newMoney then
			gainedFloors += math.round(newMoney / floorCost * 10) / 10
			break
		end
		newMoney -= floorCost
		gainedFloors += 1
	end

	-- Clean up previous preloaded UI if it exists
	if preloadedUI.container then
		preloadedUI.container:unmount()
	end

	-- Create a ref for the billboard
	local billboardRef = React.createRef()
	preloadedUI.billboardRef = billboardRef

	-- Create and mount the UI but don't set an adornee yet
	local timeBinding, setTimeBinding = React.createBinding(0)
	preloadedUI.setTimeBinding = setTimeBinding
	-- Create a new container
	preloadedUI.container = ReactRoblox.createRoot(Instance.new("Folder"))
	preloadedUI.container:render(ReactRoblox.createPortal(
		React.createElement("BillboardGui", {
			ref = preloadedUI.billboardRef,
			ResetOnSpawn = false,
			AlwaysOnTop = true,
			StudsOffset = Vector3.new(0, 0, 0),
			Size = UDim2.fromScale(16, 8),
			Enabled = true,
		}, {
			main = React.createElement(finishedPath, {
				isHighscore = isHighscore or true,
				distance = math.round(results.distance),
				reward = math.round(reward),
				targetColor = targetColor,
				duration = timeBinding,
				floors = gainedFloors,
			}),
		}),
		Players.LocalPlayer.PlayerGui,
		"finishedGUI"
	))

	preloadedUI.mounted = true
	print("Preloaded finishedPathUI")
end

function effectsController.finishedPath(results, track, animationInstance)
	local character = Players.LocalPlayer.Character
	local isHighscore = effectsController.getHighScore().Value < math.round(results.distance)
	local playerData = dataController.currentData
	local reward = cannonConfig.rewardFormula(results.distance, playerData.floors or 0)
	local targetColor, setTargetColor = React.createBinding(Color3.new())
	local startTime = tick()

	if playerData.doubleMoney then
		reward *= 2
	end

	-- Create the effects part
	local finishedPathEffects = ReplicatedStorage.assets.finishedPath:Clone()
	finishedPathEffects:PivotTo(
		CFrame.new(character.PrimaryPart.Position * Vector3.new(1, 0, 1) + Vector3.new(0, 1.2, 0))
	)
	finishedPathEffects.Parent = workspace

	-- Set up the trove for animations and cleanup
	local partTrove = Trove.new()
	partTrove:AttachToInstance(finishedPathEffects)

	-- If we have a preloaded UI, use it
	print(preloadedUI)
	if preloadedUI.mounted and preloadedUI.billboardRef.current then
		-- Update the billboard properties
		local billboard = preloadedUI.billboardRef.current
		billboard.Adornee = character.Head
		billboard.Enabled = true

		preloadedUI.setTimeBinding(math.round(results.time * 10) / 10)
	else
		-- Fallback if preloaded UI isn't available
		print("Warning: Preloaded UI not available, creating new one")
		local container = ReactRoblox.createRoot(Instance.new("Folder"))
		container:render(ReactRoblox.createPortal(
			React.createElement("BillboardGui", {
				ResetOnSpawn = false,
				AlwaysOnTop = true,
				StudsOffset = Vector3.new(0, 0, 0),
				Size = UDim2.fromScale(16, 8),
				Adornee = finishedPathEffects,
			}, {
				main = React.createElement(finishedPath, {
					isHighscore = isHighscore or true,
					distance = math.round(results.distance),
					reward = math.round(reward),
					targetColor = targetColor,
					duration = math.round(results.time * 10) / 10,
				}),
			}),
			Players.LocalPlayer.PlayerGui,
			"finishedGUI"
		))

		-- Store for cleanup
		preloadedUI.container = container
	end

	-- Set up animation for the effects
	partTrove:BindToRenderStep("moveCircle", Enum.RenderPriority.Last.Value, function(dt)
		local increaseFactor = math.sin(math.rad((tick() - startTime) * 167)) * 1
		finishedPathEffects:FindFirstChildWhichIsA("BasePart").CFrame *= CFrame.Angles(math.rad(0.5), 0, 0)
		finishedPathEffects:FindFirstChildWhichIsA("BasePart").Size =
			Vector3.new(0.7, 12 + increaseFactor, 12 + increaseFactor)
		finishedPathEffects:FindFirstChildWhichIsA("BasePart").Color =
			reactUtil.getSmoothColorFromElapsedTime(tick() - startTime, 2)
		setTargetColor(reactUtil.getSmoothColorFromElapsedTime(tick() - startTime, 2))
	end)

	SoundService.effects.victory:Play()

	task.wait(2)

	-- Disable the billboard but don't unmount it
	if preloadedUI.billboardRef.current then
		preloadedUI.billboardRef.current.Enabled = false
		preloadedUI.billboardRef.current.Adornee = nil
	end

	-- Clean up the effects
	finishedPathEffects:Destroy()
	partTrove:Destroy()

	character.PrimaryPart.Anchored = false
	character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	task.wait()
	zap.requestLoad.Fire()

	keysController.freezeMovement(false)
	keysController.updateFarming()
	if track then
		track:Stop()
		track:Destroy() -- Destroy the track
	end
	if animationInstance then
		animationInstance:Destroy() -- Destroy the animation instance
	end

	task.wait(1)
	effectsController.updateHighscore()
end

-- Clean up preloaded UI when no longer needed
function effectsController.cleanupPreloadedUI()
	if preloadedUI.container then
		preloadedUI.container:unmount()
		preloadedUI.container = nil
		preloadedUI.billboardRef = nil
		preloadedUI.mounted = false
	end
	print("cleaned up preloaded UI")
end

return effectsController
