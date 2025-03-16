local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local cameraController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local camerashaker = require(game.ReplicatedStorage.sharedPackages.camerashaker)

local camShake = camerashaker.new(Enum.RenderPriority.Camera.Value + 1, function(cf)
	local camera = workspace.CurrentCamera
	camera.CFrame = camera.CFrame * cf
end)

function miniBump()
	local c = camerashaker.CameraShakeInstance.new(2.5 / 3, 4 / 3, 0.1, 0.75)
	c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
	c.RotationInfluence = Vector3.new(1, 1, 1)
	return c
end

local camTrove

function cameraController.startShake()
	camShake:Start()
	camTrove = Trove.new()
	camShake:Shake(camerashaker.Presets.Explosion)

	local lastShook = 0
	local cI = 1
	RunService:BindToRenderStep("bounceCamera", Enum.RenderPriority.Character.Value, function()
		if Players.LocalPlayer.Character then
			if
				Players.LocalPlayer.Character.PrimaryPart.Position.Y > 2
				or Players.LocalPlayer.Character.PrimaryPart.Position.Y < 1
			then
				return
			end
			if Players.LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity.Magnitude < 6 then
				lastShook = tick() * 2
				return
			end
		end
		if tick() - lastShook < 0.2 then
			return
		end
		lastShook = tick()
		camShake:Shake(miniBump())
		cI += 1
		if not SoundService.hitFloor:FindFirstChild(tostring(cI)) then
			cI = 1
		end
		SoundService.hitFloor:FindFirstChild(tostring(cI)):Play()
	end)
end

function cameraController.shakeBump()
	camShake:Shake(camerashaker.Presets.Bump)
end

function cameraController.endShake()
	camShake:Stop()
	camTrove:Destroy()
	RunService:UnbindFromRenderStep("bounceCamera")
end

function cameraController.removeTracker()
	task.delay(0.3, function()
		spr.target(workspace.CurrentCamera, 1, 5, { FieldOfView = 70 })
	end)
end

function cameraController.start()
	print("[CameraController]: " .. "Track Camera!")
	workspace.CurrentCamera.CameraType = Enum.CameraType.Track
	task.delay(2, function()
		workspace.CurrentCamera.CameraType = Enum.CameraType.Track
	end)
end

return cameraController
