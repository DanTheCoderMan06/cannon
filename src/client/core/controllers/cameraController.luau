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

-- Modified miniBump to accept magnitude
function miniBump(magnitude)
	magnitude = magnitude or 1 -- Default magnitude to 1 if not provided
	-- Scale shake parameters based on magnitude
	local baseMagnitude = 2.5 / 3
	local baseRoughness = 4 / 3
	local baseFadeIn = 0.1
	local baseFadeOut = 0.75

	local c = camerashaker.CameraShakeInstance.new(
		baseMagnitude * magnitude,
		baseRoughness * magnitude,
		baseFadeIn / magnitude, -- Faster fade for stronger shakes
		baseFadeOut * math.sqrt(magnitude) -- Longer fade out for stronger shakes
	)
	c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15) * magnitude
	c.RotationInfluence = Vector3.new(1, 1, 1) * magnitude
	return c
end

local camTrove
local LANDING_VELOCITY_THRESHOLD = 15 -- How much vertical velocity change triggers the shake
local MIN_SHAKE_INTERVAL = 0.2 -- Minimum time between landing shakes

function cameraController.startShake()
	camShake:Start()
	camTrove = Trove.new()
	camShake:Shake(camerashaker.Presets.Explosion)

	-- Add velocity tracking for hard landings
	local previousVelocityY = 0
	local lastShakeTime = 0
	local player = Players.LocalPlayer

	local connection = RunService.RenderStepped:Connect(function(dt)
		local character = player.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local hrp = character.PrimaryPart
		if not humanoid or not hrp then
			return
		end

		local currentVelocityY = hrp.AssemblyLinearVelocity.Y
		local deltaVelocityY = previousVelocityY - currentVelocityY -- Positive when stopping a fall

		-- Check if landed (floor material is not air) and impact is hard enough
		if
			humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
			and humanoid.FloorMaterial ~= Enum.Material.Air
			and deltaVelocityY > LANDING_VELOCITY_THRESHOLD
			and tick() - lastShakeTime > MIN_SHAKE_INTERVAL
		then
			local shakeMagnitude = math.clamp(deltaVelocityY / 25, 2, 8) / 2 -- Scale shake based on impact (Increased magnitude)
			camShake:Shake(miniBump(shakeMagnitude))
			lastShakeTime = tick()
			-- Optional: Play a sound effect here too
		end

		previousVelocityY = currentVelocityY
	end)
	camTrove:Add(connection) -- Add connection to Trove for cleanup in endShake
end

function cameraController.shakeBump()
	camShake:Shake(camerashaker.Presets.Bump)
end

function cameraController.endShake()
	camShake:Stop()
	camTrove:Destroy()
	RunService:UnbindFromRenderStep("bounceCamera")
end

function cameraController.startAir()
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
		camShake:Shake(miniBump(1)) -- Use default magnitude for regular bumps
		cI += 1
		if not SoundService.hitFloor:FindFirstChild(tostring(cI)) then
			cI = 1
		end
		SoundService.hitFloor:FindFirstChild(tostring(cI)):Play()
	end)

	local lastAirShake = 0
	RunService:BindToRenderStep("airShake", Enum.RenderPriority.Camera.Value, function()
		if tick() - lastAirShake < 0.1 then
			return
		end
		lastAirShake = tick()
		camShake:Shake(camerashaker.Presets.Bump)
	end)
end

function cameraController.endAir()
	RunService:UnbindFromRenderStep("airShake")
	task.delay(0.3, function()
		spr.target(workspace.CurrentCamera, 1, 5, { FieldOfView = 70 })
	end)
	camShake:Shake(camerashaker.Presets.Explosion)
end

function cameraController.start()
	print("[CameraController]: " .. "Track Camera!")
	workspace.CurrentCamera.CameraType = Enum.CameraType.Track
	task.delay(2, function()
		workspace.CurrentCamera.CameraType = Enum.CameraType.Track
	end)
end

return cameraController
