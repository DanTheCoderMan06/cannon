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

local dataController = require(ReplicatedStorage.client.controllers.dataController)
local stateController = require(ReplicatedStorage.client.controllers.stateController)
local keysController = require(ReplicatedStorage.client.controllers.keysController)

local reactUtil = require(ReplicatedStorage.shared.utilities.reactUtil)

local currentHighScore = 0

local billboardContainer = ReactRoblox.createRoot(Instance.new("Folder"))

local preloadedUI

function effectsController.preloadedContainer(results)
	local isHighscore, setIsHighScore = React.createBinding(false)
	local reward, setReward = React.createBinding(0)
	local targetColor, setTargetColor = React.createBinding(Color3.new())
	local timeElapsed, setTimeElapsed = React.createBinding(0)

	preloadedUI = {
		billboardRef = React.createRef(),
		isHighscore = isHighscore,
		setIsHighScore = setIsHighScore,
		reward = reward,
		setReward = setReward,
		targetColor = targetColor,
		setTargetColor = setTargetColor,
		setTime = setTimeElapsed,
	}

	billboardContainer:render(ReactRoblox.createPortal(
		React.createElement("BillboardGui", {
			ResetOnSpawn = false,
			AlwaysOnTop = true,
			StudsOffset = Vector3.new(0, 4, 0),
			Size = UDim2.fromScale(16, 8),
			Adornee = Players.LocalPlayer.Character.Head,
			ref = preloadedUI.billboardRef,
			Enabled = false,
		}, {
			main = React.createElement(finishedPath, {
				isHighscore = isHighscore,
				distance = math.round(results.distance),
				reward = reward,
				targetColor = targetColor,
				duration = timeElapsed,
				floors = dataController.getData().floors,
			}),
		}),
		Players.LocalPlayer.PlayerGui,
		"finishedGUI"
	))
end

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
		api.start({
			transparency = 0,
			config = {
				tension = 300,
				friction = 30,
			},
		})
		task.delay(0.6, function()
			if props.callback then
				props.callback()
			end
		end)
		task.wait(0.6)
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
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
	})
end

local blackScreenContainer = ReactRoblox.createRoot(Instance.new("Folder"))

function effectsController.blackScreen(duration, callback)
	blackScreenContainer:render(ReactRoblox.createPortal(
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

	task.delay(2, function()
		blackScreenContainer:unmount()
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

	-- Continuous Altitude-Based Lighting
	RunService:BindToRenderStep("altitudeLightingUpdater", Enum.RenderPriority.Last.Value + 1, function()
		local character = localPlayer.Character
		if not character then
			return
		end
		local part = character.PrimaryPart
		if not part then
			return
		end

		local currentAltitude = part.Position.Y -- Use current Y position

		local clockTime
		if currentAltitude < config.NIGHT_TRANSITION_START_ALTITUDE then
			clockTime = config.DAY_CLOCK_TIME
		elseif currentAltitude >= config.NIGHT_TRANSITION_END_ALTITUDE then
			clockTime = config.NIGHT_CLOCK_TIME
		else
			local alpha = math.clamp(
				(currentAltitude - config.NIGHT_TRANSITION_START_ALTITUDE)
					/ (config.NIGHT_TRANSITION_END_ALTITUDE - config.NIGHT_TRANSITION_START_ALTITUDE),
				0,
				1
			)
			clockTime = config.DAY_CLOCK_TIME + (config.NIGHT_CLOCK_TIME - config.DAY_CLOCK_TIME) * alpha
		end

		-- Optional: Add a small tolerance check to avoid unnecessary updates if ClockTime is already very close
		if math.abs(Lighting.ClockTime - clockTime) > 0.01 then
			spr.target(Lighting, 1, 1, { ClockTime = clockTime })
		end
	end)

	effectsController.updateHighscore()
end

function effectsController.finishedPath(results, track, animationInstance)
	local character = Players.LocalPlayer.Character
	local isHighscore = effectsController.getHighScore().Value < math.round(results.distance)
	local playerData = dataController.currentData
	local reward = cannonConfig.rewardFormula(results.distance, playerData.floors or 0)
	local startTime = tick()

	if playerData.doubleMoney then
		reward *= 2
	end

	-- Create the effects part
	local finishedPathEffects = ReplicatedStorage.assets.finishedPath:Clone()
	finishedPathEffects.PrimaryPart.Position = character.PrimaryPart.Position * Vector3.new(1, 0, 1)
	finishedPathEffects.PrimaryPart.Orientation = Vector3.new(0, 0, 90)
	finishedPathEffects.Parent = workspace

	-- Set up the trove for animations and cleanup
	local partTrove = Trove.new()
	partTrove:AttachToInstance(finishedPathEffects)

	-- Check for first floor purchase bonus
	-- Assumes 'boughtFloorYet' boolean exists in playerData, otherwise this check might grant bonus repeatedly.
	if not playerData.boughtFloorYet then
		local firstFloorCost = floorConfig.costFormula(playerData.floors, 0) -- Cost for level 1 from level 0
		reward += firstFloorCost
	end

	if not playerData.boughtCannonYet then
		local firstCannon = cannonConfig.costFormula(playerData.cannon, 0) -- Cost for level 1 from level 0
		reward += firstCannon
	end

	-- If we have a preloaded UI, use it
	preloadedUI.setReward(reward)
	preloadedUI.setTime(results.time)
	preloadedUI.setIsHighScore(isHighscore)
	preloadedUI.billboardRef:getValue().Enabled = true

	-- Set up animation for the effects
	partTrove:BindToRenderStep("moveCircle", Enum.RenderPriority.Last.Value, function(dt)
		local increaseFactor = math.sin(math.rad((tick() - startTime) * 167)) * 1
		finishedPathEffects:FindFirstChildWhichIsA("BasePart").CFrame *= CFrame.Angles(math.rad(0.5), 0, 0)
		finishedPathEffects:FindFirstChildWhichIsA("BasePart").Size =
			Vector3.new(0.7, 12 + increaseFactor, 12 + increaseFactor)
		finishedPathEffects:FindFirstChildWhichIsA("BasePart").Color =
			reactUtil.getSmoothColorFromElapsedTime(tick() - startTime, 2)
		preloadedUI.setTargetColor(reactUtil.getSmoothColorFromElapsedTime(tick() - startTime, 2))
	end)

	SoundService.effects.victory:Play()

	task.wait(2)

	preloadedUI.billboardRef:getValue().Enabled = false

	billboardContainer:unmount()

	preloadedUI = nil

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

return effectsController
