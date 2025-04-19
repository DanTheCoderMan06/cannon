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
local floorConfig = require(ReplicatedStorage.shared.config.floorConfig) -- Added require
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
	player:SetAttribute("currentCannon", cannonName)
	if player.Character then
		player.Character:MoveTo(
			playerPlatforms:WaitForChild(player.Name):FindFirstChildWhichIsA("SpawnLocation", true).Position
				+ Vector3.new(0, 5, 0)
		)
	end
end

function cannonService.launchPlayer(player)
	local playerCannon = player:GetAttribute("currentCannon")
	local cannonPower = cannonConfig.cannons[playerCannon]
	local playerData = dataService.getPlayerData(player)
	if cannonPower then
		cannonPower = cannonConfig.getPower(playerData.cannon)
	else
		cannonPower = cannonConfig.specialCannons[playerCannon].power
	end

	-- Calculate height based on the tower the player is currently on
	local playerPlatform = playerPlatforms:WaitForChild(player.Name)
	local cannonPosition = playerPlatform:FindFirstChild("cannonPosition")
	local currentTowerName = playerPlatform:GetAttribute("currentTower") or player.Name -- Default to own tower if attribute missing
	local targetCastleSpot = castleFolder:FindFirstChild(currentTowerName)

	local playerHeight = 0
	if cannonPosition and targetCastleSpot then
		playerHeight = math.abs(cannonPosition.Position.Y - targetCastleSpot.Position.Y)
	else
		warn(
			string.format(
				"[CannonService] Could not determine height for %s on tower %s",
				player.Name,
				currentTowerName
			)
		)
		-- Fallback or default height if needed, e.g., using player's own tower base as before or a fixed value
		local ownCastleSpot = castleFolder:FindFirstChild(player.Name)
		if cannonPosition and ownCastleSpot then
			playerHeight = math.abs(player.Character.PrimaryPart.Position.Y - ownCastleSpot.Position.Y)
		end
	end

	if player:GetAttribute("isVIP") then
		cannonPower *= 1.5
		print(
			string.format("[CannonService Debug] Player %s VIP bonus applied. New power: %f", player.Name, cannonPower)
		)
	end

	if playerData.doubleDistance then
		cannonPower *= 2
		print(
			string.format(
				"[CannonService Debug] Player %s doubleDistance bonus applied. New power: %f",
				player.Name,
				cannonPower
			)
		)
	end

	if player.MembershipType == Enum.MembershipType.Premium then
		cannonPower *= cannonConfig.premiumMultiplier
		print(
			string.format(
				"[CannonService Debug] Player %s Premium bonus (x%f) applied. New power: %f",
				player.Name,
				cannonConfig.premiumMultiplier,
				cannonPower
			)
		)
	end

	for _, v in pairs(tierConfig.cannonTiers) do
		if v.tier == playerData.cannonTier then
			cannonPower *= v.power
			print(
				string.format(
					"[CannonService Debug] Player %s Cannon Tier %d bonus (x%f) applied. New power: %f",
					player.Name,
					v.tier,
					v.power,
					cannonPower
				)
			)
		end
	end

	cannonPower += playerHeight / 5

	local simulatedPhysics = physicsUtil.getVariables(playerHeight, cannonPower)

	print("Player Fired ")
	print(simulatedPhysics)

	zap.simulatePhysics.Fire(player, simulatedPhysics)

	simulatedPaths[player.Name] = simulatedPhysics
end

function cannonService.awardPlayer(player, playerPath)
	local playerData = dataService.getPlayerData(player)
	local bonusAward = 0
	local grantedBonus = false -- Flag to track if any bonus was given this time

	-- Check for first cannon purchase bonus
	-- Assumes 'boughtCannonYet' boolean exists in playerData, otherwise this check might grant bonus repeatedly.

	-- Check for first floor purchase bonus
	-- Assumes 'boughtFloorYet' boolean exists in playerData, otherwise this check might grant bonus repeatedly.
	if not playerData.boughtCannonYet then
		local firstCannonCost = cannonConfig.costFormula(playerData.cannon + 1, 0) -- Cost for level 1 from level 0
		bonusAward += firstCannonCost
		playerData.boughtCannonYet = true -- Set flag to true after granting
		grantedBonus = true
		print(string.format("[CannonService] Granted first cannon bonus (%d) to %s", firstCannonCost, player.Name))
	end

	if not playerData.boughtFloorYet then
		local firstFloorCost = floorConfig.costFormula(playerData.floors + 1, 0) -- Cost for level 1 from level 0
		bonusAward += firstFloorCost
		playerData.boughtFloorYet = true -- Set flag to true after granting
		grantedBonus = true
		print(string.format("[CannonService] Granted first floor bonus (%d) to %s", firstFloorCost, player.Name))
	end

	-- Add any granted bonus to player money
	if grantedBonus then
		playerData.money += bonusAward
		-- Note: Consider if this bonus should also be affected by doubleMoney. Currently, it's added before the doubleMoney check.
	end

	-- Calculate normal reward based on distance and floors
	local normalAward = cannonConfig.rewardFormula(playerPath.distance, playerData.floors)

	-- Apply double money gamepass if owned (applies only to normal reward)
	if playerData.doubleMoney then
		normalAward *= 2
		print(
			string.format(
				"[CannonService Debug] Player %s doubleMoney bonus applied. New normal award: %f",
				player.Name,
				normalAward
			)
		)
	end

	-- Add normal award to player money
	playerData.money += normalAward

	-- Update highscore
	playerData.highscore = math.max(playerData.highscore, math.round(playerPath.distance))

	-- Save updated player data (includes potential flag changes and money updates)
	-- Force save the data immediately after awarding to prevent data loss
	dataService.updatePlayerData(player, playerData, true)
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
