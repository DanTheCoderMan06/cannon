local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

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
local floorHeight = castleFloor.ceiling.Position.Y - castleFloor.floor.Position.Y

local forceUtil = require(ReplicatedStorage.shared.utilities.forceUtil)

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)

local reactComponents = ReplicatedStorage.client.reactComponents

local cannonChangedSignal = Signal.new()

local stateController = require(ReplicatedStorage.client.controllers.stateController)
local windController = require(ReplicatedStorage.client.controllers.windController)
local cameraController = require(ReplicatedStorage.client.controllers.cameraController)

function cannonController.start()
	local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
	local cannonPart = playerPlatform:WaitForChild("cannonPart", true)
	local cannonPosition = playerPlatform:WaitForChild("cannonPosition", true)
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

		task.wait(cannonConfig.cannonFirePeriod)

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
		cameraController.trackObject(Players.LocalPlayer.Character.PrimaryPart, Vector3.new(0, 10, 0))
		movePart:Destroy()

		local multiplier = 1
		if physics.time > 10 then
			multiplier = physics.time / 10
		elseif physics.time < 2 then
			multiplier = physics.time / 2
		end
		local min = math.huge

		pTrove:BindToRenderStep("physics_" .. os.time(), Enum.RenderPriority.First.Value, function()
			timeElapsed = (tick() - startTime) * multiplier
			local actualHorizontal = timeElapsed * physics.horizontalVelocity
			local fixedHorizontal = math.fmod(actualHorizontal, cannonConfig.maxDistance)
			oldPosition = newPosition
			newPosition = startPosition
				* CFrame.new(
					0,
					(timeElapsed * physics.verticalVelocity + 0.5 * -workspace.Gravity * math.pow(timeElapsed, 2)),
					-fixedHorizontal
				)
				* CFrame.Angles(-math.rad(math.fmod(timeElapsed * 180 / multiplier, 360)), 0, 0)
			if newPosition.Position.Y > 0 then
				min = math.min(newPosition.Position.Y, min)
			end
			if not character.PrimaryPart then
				pTrove:Destroy()
				finishedSignal:Fire()
				return
			end
			if
				math.abs(newPosition.Position.Y) < math.max(physics.verticalVelocity * 0.1, 10)
				and timeElapsed > physics.time / multiplier
			then
				print("destroy")
				pTrove:Destroy()
				Player.Character.PrimaryPart.Anchored = true
				finishedSignal:Fire()
				return
			else
				character:PivotTo(newPosition)
			end
		end)

		finishedSignal:Connect(function() --TODO: Use raycast + spr to  finish up dummy falling
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
						* math.min((endPosition.Position - newPosition.Position).Magnitude, 30) --(endPosition.Position - newPosition.Position) * multiplier * 0.5
					v.AssemblyAngularVelocity = Vector3.new(1, 0, 1)
				end
			end

			character.PrimaryPart.Anchored = false
			task.delay(3, function()
				repeat
					task.wait()
				until not character or character.PrimaryPart.AssemblyLinearVelocity.Magnitude < 2

				zap.finishedPath.Fire()
				finishedSignal:Destroy()
				windController.toggle(false)
			end)
		end)
	end)
end

return cannonController
