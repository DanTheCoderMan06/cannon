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
local Zone = require(game.ReplicatedStorage.sharedPackages.Zone)

local zap = require(ReplicatedStorage.zap)

local Player = Players.LocalPlayer

local castleFolder = workspace:WaitForChild("castles")
local castleFloor = ReplicatedStorage.assets.castleFloor
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

function cannonController.toggleEntrance(toggle)
	canLaunchPlayer = toggle
end

function cannonController.playLaunchSound(multiplier, physicsTime)
	SoundService.effects.explosion:Play()
	local launchSound = SoundService.launch:GetChildren()[math.random(1, #SoundService.launch:GetChildren())]
	launchSound:Play()
	task.delay(1, function()
		local fallingSound = SoundService.effects.falling
		local flightDuration = physicsTime / multiplier
		fallingSound.PlaybackSpeed = fallingSound.TimeLength / flightDuration
		fallingSound:Play()
	end)
end

function cannonController.start()
	local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
	local cannonPart = playerPlatform:WaitForChild("cannonPart", true)
	local cannonPosition = playerPlatform:WaitForChild("cannonPosition", true)
	task.delay(2, function()
		local cannonZone = Zone.new(cannonPart)
		local lastTriggered = 0

		cannonZone.partEntered:Connect(function(part)
			if not Players.LocalPlayer.Character then
				return
			end
			if not part:IsDescendantOf(Players.LocalPlayer.Character) then
				return
			end
			if tick() - lastTriggered < 1 then
				return
			end
			if not canLaunchPlayer then
				return
			end
			lastTriggered = tick()
			zap.enterCannon.Fire()
		end)

		cannonPart:GetPropertyChangedSignal("CFrame"):Connect(function()
			cannonZone:destroy()
			local cannonZone = Zone.new(cannonPart)
			local lastTriggered = 0

			cannonZone.partEntered:Connect(function(part)
				if not Players.LocalPlayer.Character then
					return
				end
				if not part:IsDescendantOf(Players.LocalPlayer.Character) then
					return
				end
				if tick() - lastTriggered < 1 then
					return
				end
				lastTriggered = tick()
				zap.enterCannon.Fire()
			end)
		end)
	end)

	cannonPosition.ChildAdded:Connect(function(child)
		if child:GetAttribute("cannonName") then
			cannonController.currentCannon = child:GetAttribute("cannonName")
			cannonChangedSignal:Fire(cannonController.currentCannon)
		end
	end)

	zap.simulatePhysics.SetCallback(function(physics)
		local character = Players.LocalPlayer.Character
		local pTrove = Trove.new()
		pTrove:AttachToInstance(character)
		local movePart = ReplicatedStorage.assets.movePart:Clone()
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

		local startPosition = CFrame.new(
			cannonPosition:FindFirstChild("characterPosition", true).WorldPosition
			--cannonPosition:FindFirstChild("fireDirection", true).WorldPosition
		) * CFrame.Angles(0, math.rad(-90), 0)
		local startTime = tick()

		local events = stateController.getEvents()

		local oldPosition
		local timeElapsed
		local newPosition
		local finishedSignal = Signal.new()
		events.radgollEvent:Fire(true)

		local targetParams = RaycastParams.new()
		targetParams.FilterType = Enum.RaycastFilterType.Exclude
		targetParams.FilterDescendantsInstances = { character }
		windController.toggle(true)

		local multiplier = 1
		if physics.time > 10 then
			multiplier = physics.time / 10
		elseif physics.time < 2 then
			multiplier = physics.time / 2
		end

		local trailEffects = ReplicatedStorage.assets.trailEffects
		local characterTrails = {}

		for _, attachmentName in pairs(effectsConfig.attachToAttachments) do
			local start = character:FindFirstChild(attachmentName, true)
			local newAtt = start:Clone()
			newAtt.CFrame *= CFrame.new(0, 0, -0.2)
			newAtt.Parent = start.Parent
			newAtt.Name = attachmentName .. "Trail"
			local trail = trailEffects.Trail:Clone()
			trail.Attachment0 = start
			trail.Attachment1 = newAtt
			trail.Parent = start.Parent
			table.insert(characterTrails, trail)
		end

		cameraController.startShake()

		cannonController.playLaunchSound(multiplier, physics.time)

		pTrove:BindToRenderStep("pathPhysics", Enum.RenderPriority.First.Value, function()
			timeElapsed = (tick() - startTime) * multiplier
			local actualHorizontal = timeElapsed * physics.horizontalVelocity
			local fixedHorizontal = math.fmod(actualHorizontal, cannonConfig.maxDistance)
			local verticalComponent = (
				timeElapsed * physics.verticalVelocity + 0.5 * -workspace.Gravity * math.pow(timeElapsed, 2)
			)
			local calculatedPosition = startPosition
				* CFrame.new(0, verticalComponent, -fixedHorizontal)
				* CFrame.Angles(-math.rad(math.fmod(timeElapsed * 180 / multiplier, 360)), 0, 0)

			local timeElapsed = tick() - startTime
			local progress = math.clamp(timeElapsed / 10, 0, 1)
			local greenBlue = math.floor(255 * (1 - progress))

			for _, v in pairs(characterTrails) do
				v.Color = ColorSequence.new(
					Color3.fromRGB(255, math.clamp(greenBlue, 135, 255), math.clamp(greenBlue, 135, 255))
				)
				v.Transparency = NumberSequence.new(1 - math.clamp(progress + 0.3, 0, 1))
			end

			Color3.fromRGB(255, 199, 199)

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

			if
				(
					math.abs(calculatedPosition.Position.Y) <= math.max(physics.verticalVelocity * 0.1, 10)
					and timeElapsed > physics.time / multiplier
				) or calculatedPosition.Position.Y < 20
			then
				print("destroy")
				pTrove:Destroy()
				Player.Character.PrimaryPart.Anchored = true
				finishedSignal:Fire()
				return
			else
				oldPosition = newPosition
				newPosition = calculatedPosition
				character:PivotTo(newPosition)
			end
		end)

		finishedSignal:Connect(function() --TODO: Use raycast + spr to  finish up dummy falling
			cameraController.removeTracker()

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
					0.9
				)
			)

			for _, v in pairs(character:GetDescendants()) do
				if v:IsA("BasePart") then
					v.AssemblyLinearVelocity = (endPosition.Position - newPosition.Position).Unit
							* math.min((endPosition.Position - newPosition.Position).Magnitude, 200)
						+ Vector3.new(40, 0, 0) --(endPosition.Position - newPosition.Position) * multiplier * 0.5
					v.AssemblyLinearVelocity = v.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
						+ Vector3.new(0, -math.min(70, v.AssemblyLinearVelocity.Y), 0)
					v.AssemblyAngularVelocity = Vector3.new(1, 0, 1)
				end
			end

			SoundService.effects.hitFloor:Play()

			character.PrimaryPart.Anchored = false

			RunService:BindToRenderStep("noFallThrough", Enum.RenderPriority.Character.Value + 1, function(dt)
				local currentPos = Players.LocalPlayer.Character.PrimaryPart.Position
				if currentPos.Y > 0 then
					return
				end
				Players.LocalPlayer.Character:PivotTo(
					CFrame.new(currentPos * Vector3.new(1, 0, 1) + Vector3.new(0, 5, 0))
				)
			end)

			for _, v in pairs(characterTrails) do
				v:Destroy()
			end

			task.delay(3, function()
				repeat
					task.wait()
				until not character or character.PrimaryPart.AssemblyLinearVelocity.Magnitude < 2
				RunService:UnbindFromRenderStep("noFallThrough")
				RunService:UnbindFromRenderStep("fallSound")
				finishedSignal:Destroy()
				windController.toggle(false)
				effectsController.finishedPath(physics)
				zap.finishedPath.Fire()
			end)
		end)
	end)
end

return cannonController
