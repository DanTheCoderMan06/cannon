local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local cameraController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local camTrove
function cameraController.trackObject(target, offset)
	workspace.CurrentCamera.CameraType = "Scriptable"
	spr.target(workspace.CurrentCamera, 0.25, 2.5, { FieldOfView = 120 })
	camTrove = Trove.new()
	camTrove:BindToRenderStep("trackObject", Enum.RenderPriority.Camera.Value, function(dt)
		workspace.CurrentCamera.CFrame = CFrame.new(target.CFrame.Position + offset, target.CFrame.Position)
	end)
end

function cameraController.removeTracker()
	camTrove:Destroy()
end

return cameraController
