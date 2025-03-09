local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local cameraController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local camerashaker = require(game.ReplicatedStorage.sharedPackages.camerashaker)

local camShake = camerashaker.new(Enum.RenderPriority.Camera.Value + 1, function(cf)
	local camera = workspace.CurrentCamera
	camera.CFrame = camera.CFrame * cf
end)

local camTrove

function cameraController.startShake()
	camShake:Start()
	camTrove = Trove.new()
	camShake:Shake(camerashaker.Presets.Explosion)
end

function cameraController.removeTracker()
	camShake:Stop()
	camTrove:Destroy()
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
