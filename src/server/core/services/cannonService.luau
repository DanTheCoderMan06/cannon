local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local serverPackages = ServerStorage.serverPackages

local Players = game:GetService("Players")

local cannonService = {}

local Sift = require(sharedPackages.Sift)

local castleFolder = workspace:WaitForChild("castles")
local dataService = require(ServerStorage.server.services.dataService)

local castleFloor = ReplicatedStorage.assets:WaitForChild("castleFloor")
local floorHeight = castleFloor.ceiling.Position.Y - castleFloor.floor.Position.Y

local playerPlatforms = workspace:WaitForChild("playerPlatforms")

local playerCannons = workspace:WaitForChild("playerCannons")

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)

local physicsUtil = require(ReplicatedStorage.shared.utilities.physicsUtil)

local Trove = require(ReplicatedStorage.sharedPackages.Trove)

local zap = require(ServerStorage.zap)

local simulatedPaths = {}

function cannonService.addCannon(player, cannonName)
	playerPlatforms:WaitForChild(player.Name):FindFirstChild("cannonPosition"):ClearAllChildren()
	local targetCannon = ReplicatedStorage.assets.cannons:FindFirstChild(cannonName):Clone()
	local cTrove = Trove.new()
	targetCannon
		:FindFirstChildWhichIsA("Model")
		:PivotTo(playerPlatforms:WaitForChild(player.Name):FindFirstChild("cannonPosition").CFrame)
	targetCannon:SetAttribute("cannonName", cannonName)
	targetCannon.Parent = playerPlatforms:WaitForChild(player.Name):FindFirstChild("cannonPosition")

	cTrove:AttachToInstance(targetCannon)
end

function cannonService.launchPlayer(player)
	local playerCannon = playerPlatforms
		:WaitForChild(player.Name)
		:FindFirstChild("cannonPosition")
		:FindFirstChildWhichIsA("Folder", true)
		:GetAttribute("cannonName")
	print(playerCannon)
	local cannonPower = cannonConfig.cannons[playerCannon].power
	local playerData = dataService.getPlayerData(player)
	if not cannonPower then
		cannonPower = cannonConfig.getPower(playerData.cannon)
	end
	local playerHeight = math.abs(
		playerPlatforms:WaitForChild(player.Name):FindFirstChild("cannonPosition").Position.Y
			- castleFolder:FindFirstChild(player.Name).Position.Y
	)
	local simulatedPhysics = physicsUtil.getVariables(playerHeight, cannonPower)

	print("Player Fired ")
	print(simulatedPhysics)

	zap.simulatePhysics.Fire(player, simulatedPhysics)

	simulatedPaths[player.Name] = simulatedPhysics
end

function cannonService.awardPlayer(player, playerPath)
	local playerData = dataService.getPlayerData(player)
	local award = cannonConfig.rewardFormula(playerPath.horizontalVelocity)
	playerData.money += award
	dataService.updatePlayerData(player, playerData)
end

function cannonService.start()
	Players.PlayerAdded:Connect(function(player)
		local playerData = dataService.getPlayerData(player)
		cannonService.addCannon(player, cannonConfig.getCannon(playerData.cannon))
	end)
	Players.PlayerRemoving:Connect(function(player)
		if playerCannons:FindFirstChild(player.Name) then
			playerCannons:FindFirstChild(player.Name):Destroy()
		end
		simulatedPaths[player.Name] = nil
	end)
	zap.enterCannon.SetCallback(function(player)
		local character = player.Character
		if not character then
			return
		end
		if character:GetAttribute("inCannon") then
			return
		end
		simulatedPaths[player.Name] = nil
		character:SetAttribute("inCannon", true)
		if workspace:FindFirstChild(player.Name .. "_Motion") then
			workspace:FindFirstChild(player.Name .. "_Motion"):Destroy()
		end
		cannonService.launchPlayer(player)
	end)
	zap.finishedPath.SetCallback(function(player)
		local character = player.Character
		if not character then
			return
		end
		if not character:GetAttribute("inCannon") then
			return
		end
		if not simulatedPaths[player.Name] then
			return
		end
		local path = Sift.Dictionary.copyDeep(simulatedPaths[player.Name])
		simulatedPaths[player.Name] = nil
		print("Finished Path!")
		print(path)
		cannonService.awardPlayer(player, path)
		player:LoadCharacter()
	end)
end

return cannonService
