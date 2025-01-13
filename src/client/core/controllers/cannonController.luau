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

		local startPosition = cannonPosition:FindFirstChild("characterPosition", true).WorldCFrame
		local startTime = tick()

		local events = stateController.getEvents()
		events.radgollEvent:Fire(true)

		local lastFixed
		w:Destroy()
		pTrove:BindToRenderStep("physics_" .. os.time(), Enum.RenderPriority.Last.Value, function()
			local timeElapsed = tick() - startTime
			if timeElapsed > physics.time then
				pTrove:Destroy()
				return
			end
			local actualHorizontal = timeElapsed * physics.horizontalVelocity
			local fixedHorizontal = math.fmod(actualHorizontal, cannonConfig.maxDistance)
			lastFixed = fixedHorizontal
			local newPosition = startPosition
				* CFrame.new(
					fixedHorizontal,
					(timeElapsed * physics.verticalVelocity + 0.5 * -workspace.Gravity * math.pow(timeElapsed, 2)),
					0
				)
			--[[
			if fixedHorizontal > lastFixed then
				spr.target(movePart, 1, 10, { CFrame = newPosition })
			else
				spr.target(movePart, 1, 200, { CFrame = newPosition })
			end
			--]]
			character.PrimaryPart.CFrame = newPosition
		end)
		task.delay(physics.time, function()
			zap.finishedPath.Fire()
		end)
	end)
end

return cannonController
