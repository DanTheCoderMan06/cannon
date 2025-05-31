local Lighting = game:GetService("Lighting")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local cannonController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local ReactRoblox = require(game.ReplicatedStorage.sharedPackages.ReactRoblox)
local React = require(game.ReplicatedStorage.sharedPackages.React)
local Sift = require(game.ReplicatedStorage.sharedPackages.Sift)
local Signal = require(game.ReplicatedStorage.sharedPackages.Signal)

local zap = require(ReplicatedStorage.zap)

local Player = Players.LocalPlayer

local castleFolder = workspace:WaitForChild("castles")
local castleFloor = ReplicatedStorage.assets:WaitForChild("playerCastleAssets").castleFloor
local floorHeight = 22 -- castleFloor:FindFirstChild("ceiling", true).Position.Y - castleFloor:FindFirstChild("floor", true).Position.Y

local forceUtil = require(ReplicatedStorage.shared.utilities.forceUtil)

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local effectsConfig = require(ReplicatedStorage.shared.config.effectsConfig)

local reactComponents = ReplicatedStorage.client.reactComponents

local cannonChangedSignal = Signal.new()
local canLaunchPlayer = true

local stateController = require(ReplicatedStorage.client.controllers.stateController)
local windController = require(ReplicatedStorage.client.controllers.windController)
local effectsController = require(ReplicatedStorage.client.controllers.effectsController)
local cameraController = require(ReplicatedStorage.client.controllers.cameraController)
local dataController = require(ReplicatedStorage.client.controllers.dataController)
local keysController = require(ReplicatedStorage.client.controllers.keysController)

local MAX_TIME = 20
local MAX_IMPACT = 200
local MAX_ALLOWED_HEIGHT = 12000 -- Maximum allowed projectile height in units
local GRAVITY = workspace.Gravity

function cannonController.toggleEntrance(toggle)
	canLaunchPlayer = toggle
end

function cannonController.playLaunchSound(multiplier, physicsTime)
	SoundService.effects.explosion:Play()
	local launchSound = SoundService.launch:GetChildren()[math.random(1, #SoundService.launch:GetChildren())]
	launchSound:Play()
	task.delay(1, function()
		local fallingSound = SoundService.effects.falling
		-- PlaybackSpeed will not be adjusted here; sound stops on landing.
		fallingSound:Play()
	end)
end

function cannonController.createCannon(cannonName: string)
	local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
	local playerData = dataController.getData()
	playerPlatform:FindFirstChild("cannonPosition"):ClearAllChildren()
	local targetCannon =
		ReplicatedStorage.assets.cannons:FindFirstChild(cannonName):FindFirstChildWhichIsA("Model"):Clone()
	local cTrove = Trove.new()
	targetCannon.PrimaryPart.CFrame = playerPlatform:FindFirstChild("cannonPosition").CFrame
	targetCannon:SetAttribute("cannonName", cannonName)
	local baseScale = targetCannon:GetScale()
	require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
		"NEW SCALE: " .. baseScale * (playerData.cannonTier * 0.1 + 1)
	)
	local multiplier = 1
	if playerData.cannonTier == 1 then
		multiplier = 1.25
	elseif playerData.cannonTier == 2 then
		multiplier = 1.5
	elseif playerData.cannonTier == 3 then
		multiplier = 1.75
	elseif playerData.cannonTier == 4 then
		multiplier = 2
	elseif playerData.cannonTier == 5 then
		multiplier = 2.25
	end

	local baseCannonPartSize = Vector3.new(17, 13, 22)
	playerPlatform:WaitForChild("cannonPart").Size = baseCannonPartSize * multiplier

	targetCannon:ScaleTo(targetCannon:GetScale() * multiplier)
	targetCannon.Parent = playerPlatform:FindFirstChild("cannonPosition")
	cTrove:AttachToInstance(targetCannon)
end

function cannonController.start()
	local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
	local cannonPart = playerPlatform:WaitForChild("cannonPart", true)
	local cannonPosition = playerPlatform:WaitForChild("cannonPosition")

	RunService:BindToRenderStep("teleportBack", Enum.RenderPriority.Last.Value + 1, function()
		local character = Players.LocalPlayer.Character
		if not character then
			return
		end
		if character:GetAttribute("inCannon") then
			return
		end
		local spawnPosition = playerPlatform:FindFirstChildWhichIsA("SpawnLocation", true).Position
		if (character.PrimaryPart.Position - spawnPosition).Magnitude > 50 then
			character:MoveTo(spawnPosition)
		end
	end)

	local lastTriggered = 0
	cannonPart.Touched:Connect(function(part)
		-- require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log("Cannon Touched") -- Optional: Keep for debugging if needed
		if not Players.LocalPlayer.Character then
			return
		end
		if not part:IsDescendantOf(Players.LocalPlayer.Character) then
			return
		end
		-- Debounce check
		if tick() - lastTriggered < 1 then
			return
		end
		if not canLaunchPlayer then
			return
		end
		lastTriggered = tick()
		zap.enterCannon.Fire()
	end)

	cannonPosition.ChildAdded:Connect(function(child)
		if child:GetAttribute("cannonName") then
			cannonController.currentCannon = child:GetAttribute("cannonName")
			cannonChangedSignal:Fire(cannonController.currentCannon)
		end
	end)

	zap.simulatePhysics.SetCallback(function(physics)
		while not cannonPosition:FindFirstChild("characterPosition", true) do
			task.wait()
		end

		effectsController.preloadedContainer(physics)

		physics.time += dataController.getData().floors / 50
		physics.time /= 10

		local character = Players.LocalPlayer.Character
		local pTrove = Trove.new()
		pTrove:AttachToInstance(character)
		local movePart = ReplicatedStorage.assets.effects.movePart:Clone()
		movePart.CFrame = character.PrimaryPart.CFrame

		movePart.CFrame = cannonPosition:FindFirstChild("characterPosition", true).WorldCFrame
			* CFrame.Angles(0, math.rad(-90), 0)
		movePart.Parent = character
		pTrove:Add(movePart)

		local w = Instance.new("Weld")
		w.Part0 = movePart
		w.Part1 = character.PrimaryPart
		w.Parent = movePart
		w.C0 = CFrame.Angles(0, math.rad(90), 0)

		for _, v in pairs(character:GetDescendants()) do
			if v:IsA("BasePart") then
				v:SetAttribute("oldTransparency", v.Transparency)
				v.Transparency = 1
			end
		end

		SoundService.effects.getIn:Play()

		task.wait(cannonConfig.cannonFirePeriod)

		for _, v in pairs(character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Transparency = v:GetAttribute("oldTransparency") or 0
			end
		end

		local startPosition = CFrame.new(cannonPosition:FindFirstChild("characterPosition", true).WorldPosition)
			* CFrame.Angles(0, math.rad(-90), 0)
		local startTime = tick()

		local events = stateController.getEvents()

		local oldPosition = startPosition -- Initialize oldPosition here
		local timeElapsed
		local newPosition
		local finishedSignal = Signal.new()
		events.radgollEvent:Fire(true)

		local targetParams = RaycastParams.new()
		targetParams.FilterType = Enum.RaycastFilterType.Exclude
		targetParams.FilterDescendantsInstances = { character }
		windController.toggle(true)

		local trailEffects = ReplicatedStorage.assets.effects.trailEffects
		local characterTrails = {}

		for _, attachmentName in pairs(effectsConfig.attachToAttachments) do
			for i = 1, 1 do
				local start = character:FindFirstChild(attachmentName, true)
				local newAtt = start:Clone()
				newAtt.CFrame *= CFrame.new(0, 0, 2)
				newAtt.Parent = start.Parent
				newAtt.Name = attachmentName .. "Trail"
				local trail = trailEffects.Trail:Clone()
				trail.Attachment0 = start
				trail.Attachment1 = newAtt
				trail.Parent = start.Parent
				table.insert(characterTrails, trail)
			end
		end

		cameraController.startShake()

		cameraController.startAir()

		cannonController.playLaunchSound(1, 5)

		-- Pre-calculate theoretical max height and scale velocity if needed
		local initialVerticalVelocity = physics.verticalVelocity
		-- Formula: peak_height = (V * sin(angle))^2 / (2 * g)
		-- Here, initialVerticalVelocity already incorporates V * sin(angle)
		local theoreticalMaxHeight = (initialVerticalVelocity * initialVerticalVelocity) / (2 * GRAVITY)

		if theoreticalMaxHeight > MAX_ALLOWED_HEIGHT then
			local velocityScaleFactor = math.sqrt(MAX_ALLOWED_HEIGHT / theoreticalMaxHeight)
			require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
				string.format(
					"Height limit exceeded (%.2f > %d). Scaling velocity by %.3f",
					theoreticalMaxHeight,
					MAX_ALLOWED_HEIGHT,
					velocityScaleFactor
				)
			)
			physics.verticalVelocity = physics.verticalVelocity * velocityScaleFactor
		end

		-- Calculate multiplier AFTER potential velocity scaling
		local multiplier = math.max(physics.verticalVelocity / 1000, 3) --/ physics.time
		if character.Head.Position.Y > 22 * 300 then
			multiplier /= character.Head.Position.Y / (22 * 300)
		end

		local prevFixH -- Used for trail clearing logic
		local lastCFrameUpdateTime = 0 -- Track time for server updates

		pTrove:BindToRenderStep("pathPhysics", Enum.RenderPriority.First.Value, function()
			timeElapsed = (tick() - startTime) * multiplier
			local actualHorizontal = timeElapsed * physics.horizontalVelocity
			local fixedHorizontal = math.fmod(actualHorizontal, cannonConfig.maxDistance) + 200

			local verticalComponent = (
				timeElapsed * physics.verticalVelocity + 0.5 * -GRAVITY * math.pow(timeElapsed, 2)
			)

			-- Calculate the character's actual vertical position for this frame, clamped by MAX_ALLOWED_HEIGHT
			local fixedVertical

			fixedVertical = math.min(verticalComponent, MAX_ALLOWED_HEIGHT)

			if prevFixH then
				if prevFixH > fixedHorizontal then
					for _, v in pairs(characterTrails) do
						v:Clear()
					end
				end
			end

			prevFixH = fixedHorizontal

			local calculatedPosition = startPosition
				* CFrame.new(0, fixedVertical, -fixedHorizontal) -- Clamp max height
				* CFrame.Angles(-math.rad(math.fmod(timeElapsed * 180 / multiplier, 360)), 0, 0)

			for _, v in pairs(character.PrimaryPart:GetDescendants()) do
				if not v:GetAttribute("targetDistance") then
					continue
				end
				if verticalComponent > v:GetAttribute("targetDistance") then
					v.Enabled = true
					v:SetAttribute("targetDistance", nil)
				end
			end

			if not character.PrimaryPart then
				pTrove:Destroy()
				finishedSignal:Fire()
				return
			end

			-- Lighting.ClockTime =

			if calculatedPosition.Position.Y < 70 then
				require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log("destroy")
				pTrove:Destroy()
				Player.Character.PrimaryPart.Anchored = true
				finishedSignal:Fire()
				return
			else
				oldPosition = newPosition
				newPosition = calculatedPosition
				character:PivotTo(newPosition)

				-- Send CFrame update to server periodically
				if tick() - lastCFrameUpdateTime >= 0.3 then
					zap.updateServerCFrame.Fire(newPosition)
					lastCFrameUpdateTime = tick()
				end
			end

			workspace.CurrentCamera.FieldOfView = 70 + timeElapsed * 16
		end)

		finishedSignal:Connect(function() --TODO: Use raycast + spr to  finish up dummy falling
			local track, animationInstance = effectsController.playDanceAnimation()

			cameraController.endAir()
			SoundService.effects.falling:Stop() -- Stop the airtime sound
			spr.target(workspace.CurrentCamera, 1, 0.25, { FieldOfView = 70 })
			cameraController.shakeBump()
			local mapParams = RaycastParams.new()
			mapParams.FilterDescendantsInstances = { workspace.Map }
			mapParams.FilterType = Enum.RaycastFilterType.Include
			local direction = (newPosition.Position - oldPosition.Position).Unit * 1000
			local endPosition = workspace:Raycast(newPosition.Position, direction, mapParams)
			if not endPosition then
				endPosition = { Position = newPosition.Position * Vector3.new(1, 0, 1) } -- No direction found?
			end
			character:PivotTo(
				CFrame.new(newPosition.Position, endPosition.Position):Lerp(
					CFrame.new(newPosition.Position, endPosition.Position)
						* CFrame.new(0, 0, -(endPosition.Position - newPosition.Position).Magnitude),
					0.5
				)
			)

			for _, v in pairs(character:GetDescendants()) do
				if v:IsA("BasePart") then
					v.AssemblyLinearVelocity = (endPosition.Position - newPosition.Position).Unit
							* math.clamp(
								(endPosition.Position - newPosition.Position).Magnitude,
								MAX_IMPACT / 2,
								MAX_IMPACT
							)
						+ Vector3.new(40, 0, 0)
					v.AssemblyLinearVelocity = v.AssemblyLinearVelocity * Vector3.new(2, 0, 2) --TODO: Edit variables here to make character bounce forward
						+ Vector3.new(0, -math.min(70, v.AssemblyLinearVelocity.Y), 0)
					v.AssemblyAngularVelocity = Vector3.new(1, 1, 1) * MAX_IMPACT
				end
			end

			-- Play impact sound only if velocity magnitude is high enough
			SoundService.effects.hitFloor:Play()

			character.PrimaryPart.Anchored = false

			RunService:BindToRenderStep("noFallThrough", Enum.RenderPriority.Character.Value + 1, function(dt)
				local currentPos = Players.LocalPlayer.Character.PrimaryPart.Position
				if currentPos.Y > 0 then
					return
				end
				for _, v in pairs(character:GetDescendants()) do
					if v:IsA("BasePart") then
						v.AssemblyLinearVelocity = Vector3.new()
					end
				end
				Players.LocalPlayer.Character:PivotTo(
					CFrame.new(currentPos * Vector3.new(1, 0, 1) + Vector3.new(0, 20, 0) - Vector3.new(1, 0, 1))
				)
			end)

			local startWait = tick()
			task.delay(1, function() -- Reduced outer delay
				repeat
					task.wait()
				until not character
					or (
						(character.PrimaryPart.AssemblyLinearVelocity.Magnitude < 5 or tick() - startWait > 4) -- Reduced inner timeout
						and character.PrimaryPart.Position.Y <= 2
					)
				SoundService.effects.falling:Stop() -- Stop the airtime sound
				cameraController.endShake()
				RunService:UnbindFromRenderStep("noFallThrough")
				RunService:UnbindFromRenderStep("fallSound")
				finishedSignal:Destroy()

				for _, v in pairs(characterTrails) do
					v.Enabled = false
				end
				task.delay(5, function()
					for _, v in pairs(characterTrails) do
						v:Destroy()
					end
				end)
				windController.toggle(false)

				keysController.freezeMovement(true)
				task.wait()

				-- Play dance animation first

				for _, v in pairs(SoundService.launch:GetChildren()) do
					v:Stop()
				end

				for _, v in pairs(SoundService.hitFloor:GetChildren()) do
					v:Stop()
				end

				SoundService.effects.hitFloor:Stop()

				task.wait()

				-- Then unragdoll
				stateController.getEvents().radgollEvent:Fire(false)

				-- Then move character up
				character.PrimaryPart.Anchored = true
				character:PivotTo(
					CFrame.new(
						character.PrimaryPart.Position + Vector3.new(0, 2, 0),
						character.PrimaryPart.Position
							+ Vector3.new(0, 2, 0)
							- (workspace.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1))
					)
				)

				-- Pass the track and animation instance to finishedPath
				physics.time = tick() - startTime
				zap.finishedPath.Fire()
				effectsController.finishedPath(physics, track, animationInstance)
			end)
		end)
	end)

	local function updateCannon()
		local newCannonName = Players.LocalPlayer:GetAttribute("currentCannon")
		if not newCannonName then
			task.delay(2, function()
				updateCannon()
			end)
			return
		end
		cannonController.createCannon(newCannonName)
	end

	Players.LocalPlayer:GetAttributeChangedSignal("currentCannon"):Connect(updateCannon)
	updateCannon()

	local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
	playerPlatform:FindFirstChild("cannonPosition", true):GetPropertyChangedSignal("CFrame"):Connect(function()
		if not playerPlatform:FindFirstChild("cannonPosition", true):FindFirstChildWhichIsA("Model", true) then
			return
		end
		playerPlatform:FindFirstChild("cannonPosition", true):FindFirstChildWhichIsA("Model", true).PrimaryPart.CFrame =
			playerPlatform:FindFirstChild("cannonPosition", true).CFrame
	end)

	local currentTier = dataController.getData().cannonTier
	dataController.dataChanged:Connect(function(newData)
		if newData.cannonTier == currentTier then
			return
		end
		currentTier = newData.cannonTier
		updateCannon()
	end)

	zap.updateClientsCFrame.SetCallback(function(incomingData)
		if incomingData.character == Players.LocalPlayer then
			return
		end
		local character = incomingData.character.Character
		if not character then
			return
		end
		character:PivotTo(incomingData.target)
	end)
end

return cannonController
