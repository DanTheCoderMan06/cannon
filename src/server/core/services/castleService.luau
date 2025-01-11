local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local serverPackages = ServerStorage.serverPackages

local Players = game:GetService("Players")
local FriendService = game:GetService("FriendService")

local castleService = {}

local Sift = require(sharedPackages.Sift)

local castleFolder = workspace:WaitForChild("castles")
local dataService = require(ServerStorage.server.services.dataService)

local castleFloor = ReplicatedStorage.assets:WaitForChild("castleFloor")
local floorHeight = castleFloor.ceiling.Position.Y - castleFloor.floor.Position.Y

local playerPlatforms = workspace:WaitForChild("playerPlatforms")

local zap = require(ServerStorage.zap)

function castleService.updateTower(player)
	local playerData = dataService.getPlayerData(player)
	local playerSpot = castleFolder:FindFirstChild(player.Name)
	local playerCastle = playerSpot:FindFirstChildWhichIsA("Folder")
	for i = 0, playerData.floors do
		if not playerCastle:FindFirstChild(i) then
			local newfloor = castleFloor:Clone()
			newfloor.Name = i
			newfloor:PivotTo(playerSpot.CFrame * CFrame.new(0, floorHeight * (i + 0.5), 0))
			newfloor.Parent = playerCastle
		end
	end
	for _, v in pairs(playerPlatforms:GetChildren()) do
		if v:GetAttribute("currentTower") == player.Name then
			castleService.updatePlatform(Players:FindFirstChild(v.Name), playerSpot)
		end
	end
end

function castleService.findSpot()
	for i, v in pairs(castleFolder:GetChildren()) do
		if v.Name == "spot" then
			return v
		end
	end
end

function castleService.updatePlatform(player, newspot)
	local targetCFrame = newspot.CFrame
		* CFrame.new(
			0,
			(dataService.getPlayerData(Players:FindFirstChild(newspot.Name)).floors + 1) * floorHeight - 1,
			0
		)
	playerPlatforms:FindFirstChild(player.Name):PivotTo(targetCFrame)
	player.RespawnLocation = playerPlatforms:FindFirstChild(player.Name):FindFirstChildWhichIsA("SpawnLocation")
	player:LoadCharacter()
	playerPlatforms
		:FindFirstChild(player.Name)
		:SetAttribute("currentTower", newspot:FindFirstChildWhichIsA("Folder").Name)
end
--TODO: Check if function works correctly
function castleService.updateTowerPrivacy(player, newStatus)
	local playerTower = castleFolder:FindFirstChild(player.Name):FindFirstChildWhichIsA("Folder")
	playerTower:SetAttribute("status", newStatus)
	if newStatus == 1 then
		for _, v in pairs(playerPlatforms:GetChildren()) do
			if v.Name == "spot" then
				continue
			end
			if v:GetAttribute("currentTower") == player.Name then
				local platformPlayer = Players:FindFirstChild(v.Name)
				if platformPlayer == player then
					continue
				end
				if not player:IsFriendsWith(platformPlayer.UserId) then
					castleService.updatePlatform(platformPlayer, castleFolder:FindFirstChild(platformPlayer.Name))
				end
			end
		end
	elseif newStatus == 2 then
		for _, v in pairs(playerPlatforms:GetChildren()) do
			if v.Name == "spot" then
				continue
			end
			if v:GetAttribute("currentTower") == player.Name then
				local platformPlayer = Players:FindFirstChild(v.Name)
				if platformPlayer == player then
					continue
				end
				castleService.updatePlatform(platformPlayer, castleFolder:FindFirstChild(platformPlayer.Name))
			end
		end
	end
end

function castleService.start()
	Players.PlayerAdded:Connect(function(player)
		local newCastle = Instance.new("Folder")
		newCastle.Name = player.Name
		local newSpot = castleService.findSpot()
		newSpot.Name = player.Name
		newCastle.Parent = newSpot
		castleService.updateTower(player)
		local newplatform = ReplicatedStorage.assets.playerPlatform:Clone()
		newplatform.Name = player.Name
		newplatform.Parent = playerPlatforms
		castleService.updatePlatform(player, newSpot)
		local playerData = dataService.getPlayerData(player)
		newCastle:SetAttribute("status", playerData.towerStatus)
		--[[
		task.delay(6, function()
			print("Test tower!")
			local oldData = dataService.getPlayerData(player)
			oldData.floors += 1
			dataService.updatePlayerData(player, oldData)
			castleService.updateTower(player)
		end)
		--]]
	end)
	Players.PlayerRemoving:Connect(function(player)
		playerPlatforms:FindFirstChild(player.Name):Destroy()
		for i, v in pairs(castleFolder:GetChildren()) do
			if v:FindFirstChildWhichIsA("Folder") and v.Name == player.Name then
				v:ClearAllChildren()
				v.Name = "spot"
			end
		end

		for _, v in pairs(playerPlatforms:GetChildren()) do
			if v.Name == "spot" then
				continue
			end
			if v:GetAttribute("currentTower") == player.Name then
				local platformPlayer = Players:FindFirstChild(v.Name)
				castleService.updatePlatform(platformPlayer, castleFolder:FindFirstChild(platformPlayer.Name))
			end
		end
	end)
	zap.changePrivacy.SetCallback(function(player, newState)
		local playerData = dataService.getPlayerData(player)
		playerData.towerStatus += 1
		if playerData.towerStatus > 2 then
			playerData.towerStatus = 0
		end
		task.spawn(function()
			dataService.updatePlayerData(player, playerData)
		end)
		castleService.updateTowerPrivacy(player, playerData.towerStatus)
		return true
	end)
	zap.selectPlatform.SetCallback(function(player, targetPlayer)
		targetPlayer = targetPlayer or player
		local targetPlayerData = dataService.getPlayerData(targetPlayer)
		if targetPlayerData.towerStatus == 2 then
			if player ~= targetPlayer then
				return
			end
		elseif targetPlayerData.towerStatus == 1 then
			if not player:IsFriendsWith(targetPlayer.UserId) then
				return
			end
		end
		print(targetPlayer.Name)
		castleService.updatePlatform(player, castleFolder:FindFirstChild(targetPlayer.Name))
		return true
	end)
end

return castleService
