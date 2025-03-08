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

local playerPlatforms = workspace:WaitForChild("playerPlatforms")

local playerCannons = workspace:WaitForChild("playerCannons")

local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local tierConfig = require(ReplicatedStorage.shared.config.tierConfig)

local physicsUtil = require(ReplicatedStorage.shared.utilities.physicsUtil)
local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)

local Trove = require(ReplicatedStorage.sharedPackages.Trove)

local zap = require(ServerStorage.zap)

local simulatedPaths = {}

function cannonService.addCannon(player, cannonName)
	if not playerPlatforms:WaitForChild(player.Name):FindFirstChild("cannonPosition") then
		warn("[CannonService]: Attempted to give null player cannon!")
		return
	end
	local playerData = dataService.getPlayerData(player)
	playerPlatforms:WaitForChild(player.Name):FindFirstChild("cannonPosition"):ClearAllChildren()
	local targetCannon = ReplicatedStorage.assets.cannons:FindFirstChild(cannonName):Clone()
	local cTrove = Trove.new()
	targetCannon
		:FindFirstChildWhichIsA("Model")
		:PivotTo(playerPlatforms:WaitForChild(player.Name):FindFirstChild("cannonPosition").CFrame)
	targetCannon:SetAttribute("cannonName", cannonName)
	targetCannon
		:FindFirstChildWhichIsA("Model")
		:ScaleTo(targetCannon:FindFirstChildWhichIsA("Model"):GetScale() * (playerData.cannonTier * 0.1 + 1))
	targetCannon.Parent = playerPlatforms:WaitForChild(player.Name):FindFirstChild("cannonPosition")

	cTrove:AttachToInstance(targetCannon)
end

function cannonService.launchPlayer(player)
	local playerCannon = playerPlatforms
		:WaitForChild(player.Name)
		:FindFirstChild("cannonPosition")
		:FindFirstChildWhichIsA("Folder", true)
		:GetAttribute("cannonName")
	local cannonPower = cannonConfig.cannons[playerCannon]
	local playerData = dataService.getPlayerData(player)
	if cannonPower then
		cannonPower = cannonConfig.getPower(playerData.cannon)
	else
		cannonPower = cannonConfig.specialCannons[playerCannon].power
	end
	local playerHeight = math.abs(
		playerPlatforms:WaitForChild(player.Name):FindFirstChild("cannonPosition").Position.Y
			- castleFolder:FindFirstChild(player.Name).Position.Y
	)

	if player:GetAttribute("isVIP") then
		cannonPower *= 1.5
	end

	if playerData.doubleDistance then
		cannonPower *= 2
	end

	for _, v in pairs(tierConfig.cannonTiers) do
		if v.tier == playerData.cannonTier then
			cannonPower *= v.power
		end
	end

	local simulatedPhysics = physicsUtil.getVariables(playerHeight, cannonPower)

	print("Player Fired ")
	print(simulatedPhysics)

	zap.simulatePhysics.Fire(player, simulatedPhysics)

	simulatedPaths[player.Name] = simulatedPhysics
end

function cannonService.awardPlayer(player, playerPath)
	local playerData = dataService.getPlayerData(player)
	local award = cannonConfig.rewardFormula(playerPath.horizontalVelocity)
	if playerData.doubleMoney then
		award *= 2
	end
	playerData.money += award
	playerData.highscore = math.max(playerData.highscore, math.round(playerPath.distance))
	dataService.updatePlayerData(player, playerData)
end

function cannonService.start()
	Players.PlayerAdded:Connect(function(player)
		local playerData = dataService.getPlayerData(player)
		cannonService.addCannon(player, cannonConfig.getCannon(playerData.cannon), true)
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
		if not simulatedPaths[player.Name] then
			return
		end
		if tick() - simulatedPaths[player.Name].timeCreated < 3 then
			print("Anti Exploit")
			return
		end
		local path = Sift.Dictionary.copyDeep(simulatedPaths[player.Name])
		simulatedPaths[player.Name] = nil
		cannonService.awardPlayer(player, path)
	end)

	zap.toggleCannon.SetCallback(function(player, target)
		local playerData = dataService.getPlayerData(player)
		print(target)
		if target ~= "default" then
			if not table.find(playerData.cannons, target) then
				return
			end
			local cannonFolder = ReplicatedStorage.assets.cannons:FindFirstChild(target)
			if not cannonFolder then
				return
			end
			cannonService.addCannon(player, target, true)
		else
			cannonService.addCannon(player, cannonConfig.getCannon(playerData.cannon), true)
		end

		return true
	end)

	zap.requestLoad.SetCallback(function(player)
		local character = player.Character
		if not character then
			return
		end

		if not character:GetAttribute("inCannon") then
			return
		end

		character:SetAttribute("inCannon", nil)

		character:MoveTo(
			playerPlatforms:WaitForChild(player.Name):FindFirstChildWhichIsA("SpawnLocation", true).Position
				+ Vector3.new(0, 5, 0)
		)
	end)
end

return cannonService
