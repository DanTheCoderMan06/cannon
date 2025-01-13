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
		local w = Instance.new("Weld")
		w.Part0 = movePart
		w.Part1 = character.PrimaryPart
		w.Parent = movePart
		movePart.CFrame = cannonPosition:FindFirstChild("characterPosition", true).WorldCFrame
		movePart.Parent = character
		pTrove:Add(w)
		pTrove:Add(movePart)

		task.wait(cannonConfig.cannonFirePeriod)

		local startPosition = CFrame.new(
			cannonPosition:FindFirstChild("characterPosition", true).WorldPosition,
			cannonPosition:FindFirstChild("fireDirection", true).WorldPosition
		)
		local startTime = tick()

		local events = stateController.getEvents()

		local lastFixed
		local timeElapsed
		local newPosition
		local finishedSignal = Signal.new()

		pTrove:BindToRenderStep("physics_" .. os.time(), Enum.RenderPriority.Last.Value, function()
			timeElapsed = tick() - startTime
			if timeElapsed > physics.time + 1 then
				pTrove:Destroy()
				return
			end
			local actualHorizontal = timeElapsed * physics.horizontalVelocity
			local fixedHorizontal = math.fmod(actualHorizontal, cannonConfig.maxDistance)
			lastFixed = fixedHorizontal
			newPosition = startPosition
				* CFrame.new(
					0,
					(timeElapsed * physics.verticalVelocity + 0.5 * -workspace.Gravity * math.pow(timeElapsed, 2)),
					-fixedHorizontal
				)
			if fixedHorizontal > lastFixed then
				spr.target(movePart, 1, 10, { CFrame = newPosition })
			else
				spr.target(movePart, 1, 200, { CFrame = newPosition })
			end
			if timeElapsed >= physics.time - 2 then
				local rayTest = workspace:Raycast(Player.Character.PrimaryPart.Position, -Vector3.new(0, 100, 0))
				if rayTest then
					if math.abs(rayTest.Position.Y - Player.Character.PrimaryPart.Position.Y) < 15 then
						pTrove:Destroy()
						finishedSignal:Fire()
					end
				end
			end
		end)

		finishedSignal:Connect(function()
			events.radgollEvent:Fire(true)
			local actualHorizontal = physics.time * physics.horizontalVelocity
			local fixedHorizontal = math.fmod(actualHorizontal, cannonConfig.maxDistance)
			local targetPosition = startPosition
				* CFrame.new(
					0,
					(physics.time * physics.verticalVelocity + 0.5 * -workspace.Gravity * math.pow(physics.time, 2)),
					-fixedHorizontal
				)
			print(targetPosition.Position - newPosition.Position)
			forceUtil:OnApplyForce(
				Player.Character.PrimaryPart,
				(targetPosition.Position - newPosition.Position).Unit * 25,
				0,
				newPosition.Position
			)
			zap.finishedPath.Fire()
			finishedSignal:Destroy()
		end)
	end)
end

return cannonController
