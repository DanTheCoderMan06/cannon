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

local effectsUi = require(ReplicatedStorage.client.reactComponents.generics.effectText)
local finishedPath = require(ReplicatedStorage.client.reactComponents.generics.finishedPath)

local currentHighScore = 0

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
			spr.target(Lighting, 1, 0.25, {
				ClockTime = if currentAltitude > config.nightSky then 23.9 else 12,
			})
		end
		local adjustedAltitude = math.fmod(currentAltitude, config.cloudSky)

		if math.round(clouds.Cover * 100) / 100 == 1 or math.round(clouds.Cover * 100) / 100 == 0 then
			local cloudTarget = 0
			if adjustedAltitude == currentAltitude then
				if currentAltitude > config.cloudSky - config.cloudSkyLerp then
					cloudTarget = 1
				end
			else
				if adjustedAltitude < config.cloudSkyLerp then
					cloudTarget = 1
				end
				if currentAltitude > config.cloudSky - config.cloudSkyLerp then
					cloudTarget = 1
				end
			end
			spr.target(clouds, 1, 0.25, {
				Cover = cloudTarget,
			})
		end
	end)

	effectsController.updateHighscore()
end

function effectsController.finishedPath(results)
	local character = Players.LocalPlayer.Character
	local finishedPathEffects = ReplicatedStorage.assets.finishedPath:Clone()
	local container = ReactRoblox.createRoot(Instance.new("Folder"))
	local isHighscore = effectsController.getHighScore().Value < math.round(results.distance)

	container:render(ReactRoblox.createPortal(
		React.createElement("BillboardGui", {
			ResetOnSpawn = false,
			AlwaysOnTop = true,
			StudsOffset = Vector3.new(0, 5, 0),
			Size = UDim2.fromScale(6, 7.5),
			Adornee = finishedPathEffects,
		}, {
			main = React.createElement(finishedPath, {
				isHighscore = isHighscore,
				distance = math.round(results.distance),
				reward = math.round(cannonConfig.rewardFormula(results.distance)),
			}),
		}),
		Players.LocalPlayer.PlayerGui,
		"finishedGUI"
	))

	finishedPathEffects:PivotTo(CFrame.new(character.PrimaryPart.Position * Vector3.new(1, 0, 1)))
	finishedPathEffects.Parent = workspace

	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	spr.target(workspace.CurrentCamera, 1, 2.5, {
		CFrame = CFrame.new(character.PrimaryPart.Position * Vector3.new(1, 20, 1), character.PrimaryPart.Position),
	})

	SoundService.effects.victory:Play()

	task.delay(1, function()
		effectsController.blackScreen(1, function()
			spr.stop(workspace.CurrentCamera, "CFrame")
			container:unmount()
			finishedPathEffects:Destroy()
			zap.requestLoad.Fire()
			local newCharacter = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
			workspace.CurrentCamera.CameraSubject = newCharacter
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			effectsController.updateHighscore()
		end)
	end)
end

return effectsController
