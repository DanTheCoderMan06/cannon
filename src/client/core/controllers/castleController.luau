local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local castleController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)

local Player = Players.LocalPlayer

local castleFolder = workspace:WaitForChild("castles")
local castleFloor = ReplicatedStorage.assets.castleFloor
local floorHeight = castleFloor.ceiling.Position.Y - castleFloor.floor.Position.Y

local currentCastle
local currentPlatform

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

function castleController.updatePlatform()
	if not currentPlatform then
		currentPlatform = ReplicatedStorage.assets.playerPlatform:Clone()
		Player.RespawnLocation = currentPlatform:FindFirstChildWhichIsA("SpawnLocation")
		currentPlatform.Parent = workspace
	end
	currentPlatform:PivotTo(
		currentCastle.CFrame
			* CFrame.new(
				0,
				(castleController.getFloors(Players:FindFirstChild(currentCastle.Name)) + 1) * floorHeight,
				0
			)
	)
end

function castleController.start()
	local startingFloors = castleController.getFloors(Player)

	local playerCastle = castleFolder:WaitForChild(Player.Name):FindFirstChildWhichIsA("Folder")
	currentCastle = playerCastle.Parent

	playerCastle.ChildAdded:Connect(function(child)
		if tonumber(child.Name) > startingFloors then
			castleController.animateFloor(child)
		end
	end)

	castleController.updatePlatform()
end

return castleController
