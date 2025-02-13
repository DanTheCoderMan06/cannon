local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local effectsController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local React = require(game.ReplicatedStorage.sharedPackages.React)
local ReactRoblox = require(game.ReplicatedStorage.sharedPackages.ReactRoblox)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local camTrove

local config = require(ReplicatedStorage.shared.config.effectsConfig)
local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)

local effectsUi = require(ReplicatedStorage.client.reactComponents.generics.effectText)

function effectsController.getHighScore()
	for _, v in pairs(Players.LocalPlayer:WaitForChild("leaderstats"):GetChildren()) do
		if v:GetAttribute("statName") == "highscore" then
			return v.Value
		end
	end
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
end

function effectsController.finishedPath(results)
	local character = Players.LocalPlayer.Character
	local finishedPathEffects = ReplicatedStorage.assets.finishedPath:Clone()
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	finishedPathEffects:PivotTo(CFrame.new(character.PrimaryPart.Position * Vector3.new(1, 0, 1)))
	finishedPathEffects:FindFirstChild("finishedGUI", true).content.distance.Text = math.round(results.distance) .. "m"
	finishedPathEffects:FindFirstChild("finishedGUI", true).content.money.Text = math.round(
		cannonConfig.rewardFormula(results.distance)
	) .. "$"
	finishedPathEffects:FindFirstChild("finishedGUI", true).content.record.Visible = effectsController.getHighScore()
		< results.distance
	finishedPathEffects.Name = "finishedPlace"
	if workspace:FindFirstChild("finishedPlace") then
		workspace:FindFirstChild("finishedPlace"):Destroy()
	end
	finishedPathEffects.Parent = workspace
	spr.target(workspace.CurrentCamera, 1, 2.5, {
		CFrame = CFrame.new(character.PrimaryPart.Position * Vector3.new(1, 15, 1), character.PrimaryPart.Position),
	})
	task.delay(2, function()
		finishedPathEffects:Destroy()
		spr.stop(workspace.CurrentCamera, "CFrame")
		local newCharacter = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
		workspace.CurrentCamera.CameraSubject = newCharacter
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	end)
end

return effectsController
