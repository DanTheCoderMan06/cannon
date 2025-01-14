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

		local lastFixed
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
		pTrove:BindToRenderStep("physics_" .. os.time(), Enum.RenderPriority.First.Value, function()
			timeElapsed = tick() - startTime
			local actualHorizontal = timeElapsed * physics.horizontalVelocity
			local fixedHorizontal = math.fmod(actualHorizontal, cannonConfig.maxDistance)
			newPosition = startPosition
				* CFrame.new(
					0,
					(timeElapsed * physics.verticalVelocity + 0.5 * -workspace.Gravity * math.pow(timeElapsed, 2)),
					-fixedHorizontal
				)
				* CFrame.Angles(-math.rad(math.fmod(timeElapsed * 180, 360)), 0, 0)
			character:PivotTo(newPosition)
			if character.PrimaryPart.Position.Y < 10 and timeElapsed > physics.time - 2 then
				pTrove:Destroy()
				finishedSignal:Fire()
				return
			end
		end)

		finishedSignal:Connect(function()
			--[[
			local actualHorizontal = physics.time * physics.horizontalVelocity
			local fixedHorizontal = math.fmod(actualHorizontal, cannonConfig.maxDistance)
			local targetPosition = startPosition
				* CFrame.new(
					0,
					(physics.time * physics.verticalVelocity + 0.5 * -workspace.Gravity * math.pow(physics.time, 2)),
					-fixedHorizontal
				)
						forceUtil:OnApplyForce(
				Player.Character.PrimaryPart,
				(targetPosition.Position - newPosition.Position).Unit * 25,
				0,
				newPosition.Position
			)
			--]]
			task.delay(3, function()
				repeat
					task.wait()
				until not character or character.PrimaryPart.Position.Y < 1
				print(((character.PrimaryPart.Position - startPosition.Position) * Vector3.new(1, 0, 1)).Magnitude)
				zap.finishedPath.Fire()
				finishedSignal:Destroy()
				windController.toggle(false)
			end)
		end)
	end)
end

return cannonController
