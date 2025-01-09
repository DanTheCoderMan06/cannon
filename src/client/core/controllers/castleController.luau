local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local castleController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local ReactRoblox = require(game.ReplicatedStorage.sharedPackages.ReactRoblox)
local React = require(game.ReplicatedStorage.sharedPackages.React)
local Sift = require(game.ReplicatedStorage.sharedPackages.Sift)
local Signal = require(game.ReplicatedStorage.sharedPackages.Signal)

local Player = Players.LocalPlayer

local castleFolder = workspace:WaitForChild("castles")
local castleFloor = ReplicatedStorage.assets.castleFloor
local floorHeight = castleFloor.ceiling.Position.Y - castleFloor.floor.Position.Y

local platformConfig = require(ReplicatedStorage.shared.config.platformConfig)

local reactComponents = ReplicatedStorage.client.reactComponents

local platformUI = require(reactComponents.platform)

function castleController.animateFloor(floor)
	local models = {}
	for _, v in pairs(floor:GetDescendants()) do
		if v:IsA("Model") then
			if v:GetAttribute("dir") then
				table.insert(models, v)
			end
			for i, z in pairs(v:GetChildren()) do
				z.Transparency = 1
			end
		else
			if v.Parent == floor or v:IsA("Texture") then
				v.Transparency = 1
				task.delay(1.2, function()
					spr.target(v, 0.8, 2.5, { Transparency = 0 })
				end)
			end
		end
	end

	for _, v in pairs(models) do
		local offset = Vector3.new()
		if v:GetAttribute("dir") == "south" then
			offset = Vector3.new(-35, 0, 0)
		elseif v:GetAttribute("dir") == "north" then
			offset = Vector3.new(35, 0, 0)
		elseif v:GetAttribute("dir") == "east" then
			offset = Vector3.new(0, 0, 35)
		else
			offset = Vector3.new(0, 0, -35)
		end
		for e, z in pairs(v:GetChildren()) do
			local targetCFrame = z.CFrame
			z.CFrame *= CFrame.new(offset)
			task.delay(1, function()
				spr.target(z, 0.8, 2.5, { CFrame = targetCFrame, Transparency = 0 })
			end)
		end
	end
end

function castleController.getFloors(targetPlayer)
	local pstats = targetPlayer:WaitForChild("leaderstats")
	for i, v in pairs(pstats:GetChildren()) do
		if v:GetAttribute("statName") == "floors" then
			return v.Value
		end
	end
end

function castleController.getCannonLevel(targetPlayer)
	local pstats = targetPlayer:WaitForChild("leaderstats")
	for i, v in pairs(pstats:GetChildren()) do
		if v:GetAttribute("statName") == "cannon" then
			return v.Value
		end
	end
end

function castleController.setupPlatform(targetPlatform)
	local container = ReactRoblox.createRoot(Instance.new("Folder"))
	container:render(ReactRoblox.createPortal(
		React.createElement("BillboardGui", {
			Active = true,
			AlwaysOnTop = true,
			ClipsDescendants = true,
			StudsOffset = Vector3.new(0, 4, 0),
			LightInfluence = 1,
			MaxDistance = 100,
			Size = UDim2.fromScale(12, 6),
			Adornee = targetPlatform,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			React.createElement(
				platformUI,
				Sift.Dictionary.merge(platformConfig[targetPlatform.Name], { name = targetPlatform.Name })
			),
		}),
		Players.LocalPlayer.PlayerGui,
		targetPlatform.Name
	))
end

function castleController.start()
	local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)

	for platformName, platform in pairs(platformConfig) do
		task.spawn(function()
			castleController.setupPlatform(playerPlatform.platforms:WaitForChild(platformName))

			local newPurchase = ReplicatedStorage.assets.purchasePlatform:Clone()
			newPurchase.Parent = playerPlatform.platforms
			newPurchase:PivotTo(playerPlatform.platforms:WaitForChild(platformName).CFrame)

			if typeof(platform.initModel) == "Instance" then
				local updateTrove = Trove.new()
				local modelFolder = Instance.new("Folder")
				modelFolder.Name = platformName .. "_Model"
				modelFolder.Parent = newPurchase
				updateTrove:AttachToInstance(modelFolder)

				local newModel = platform.initModel:Clone()
				newModel:PivotTo(newPurchase:FindFirstChild("modelPlatform", true).WorldCFrame)
				newModel.Parent = modelFolder
			elseif typeof(platform.initModel) == "function" then
				local updateTrove = Trove.new()
				local updateSignal = Signal.new()
				local modelFolder = Instance.new("Folder")
				modelFolder.Name = platformName .. "_Model"
				modelFolder.Parent = newPurchase
				updateTrove:AttachToInstance(modelFolder)

				updateTrove:Add(
					updateSignal:Connect(function(newModel)
						modelFolder:ClearAllChildren()
						newModel:PivotTo(newPurchase:FindFirstChild("modelPlatform", true).WorldCFrame)
						newModel.Parent = modelFolder
					end),
					"Disconnect"
				)

				updateTrove:Add(updateSignal, "Destroy")

				task.defer(function()
					platform.initModel(updateTrove, updateSignal)
				end)
			end
		end)
	end

	local startingFloors = castleController.getFloors(Player)

	local playerCastle = castleFolder:WaitForChild(Player.Name):FindFirstChildWhichIsA("Folder")

	playerCastle.ChildAdded:Connect(function(child)
		if tonumber(child.Name) > startingFloors then
			castleController.animateFloor(child)
		end
	end)

	local pTrove = Trove.new()
	pTrove:AttachToInstance(playerPlatform)

	pTrove:BindToRenderStep("rotateModels", Enum.RenderPriority.Last.Value, function(dt)
		local targetModels = {}
		local targetCFrames = {}
		for _, v in pairs(playerPlatform.platforms:GetChildren()) do
			if v:IsA("Model") and v:FindFirstChildWhichIsA("Folder", true) then
				local model = v:FindFirstChildWhichIsA("Folder", true):FindFirstChildWhichIsA("Model")
				table.insert(targetModels, model.PrimaryPart)
				table.insert(targetCFrames, model.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(1), 0))
			end
		end
		workspace:BulkMoveTo(targetModels, targetCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end)
end

return castleController
