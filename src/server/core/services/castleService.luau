local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local serverPackages = ServerStorage.serverPackages

local Players = game:GetService("Players")
local FriendService = game:GetService("FriendService")

local castleService = {}

local Sift = require(sharedPackages.Sift)

local castleFolder = workspace:WaitForChild("castles")
local dataService = require(ServerStorage.server.services.dataService)

local objectcache = require(sharedPackages.objectcache)

local castleFloor = ReplicatedStorage.assets:WaitForChild("castleFloor")
local floorHeight = 22 -- castleFloor:FindFirstChild("ceiling", true).Position.Y - castleFloor:FindFirstChild("floor", true).Position.Y

local playerPlatforms = workspace:WaitForChild("playerPlatforms")

local zap = require(ServerStorage.zap)

local floorStorage = Instance.new("Folder")
floorStorage.Name = "floorStorage"
floorStorage.Parent = ServerStorage

local floors = objectcache.new({ Template = castleFloor, CacheParent = floorStorage })
local topFloors = objectcache.new({ Template = ReplicatedStorage.assets.topFloor, CacheParent = floorStorage })

local CHUNK_SIZE = 10

function castleService.updateTower(player)
	local playerData = dataService.getPlayerData(player)
	local playerSpot = castleFolder:FindFirstChild(player.Name)
	local playerCastle = playerSpot:FindFirstChildWhichIsA("Model")

	local totalFloors = playerData.floors

	-- Run the creation in the background so it doesn't block instantly
	task.spawn(function()
		local currentFloor = 0
		while currentFloor <= totalFloors - 1 do
			-- Create a small batch each frame to avoid a huge spike
			for i = 1, CHUNK_SIZE do
				if currentFloor > totalFloors - 1 then
					break
				end
				if not playerCastle:FindFirstChild(currentFloor) then
					if #floors._FreeObjects < i then
						floors:ExpandCache(50)
					end
					local newFloor =
						floors:Get(playerSpot.CFrame * CFrame.new(0, floorHeight * (currentFloor + 0.5), 0))
					newFloor.Name = tostring(currentFloor)
					newFloor.Parent = playerCastle
				end
				currentFloor += 1
			end
			task.wait()
		end
	end)

	-- Update platforms in the same function call if you need immediate updates
	for _, v in pairs(playerPlatforms:GetChildren()) do
		if v:GetAttribute("currentTower") == player.Name then
			castleService.updatePlatform(Players:FindFirstChild(v.Name), playerSpot)
		end
	end

	if not playerCastle:FindFirstChild("topFloor") then
		local playerTopFloor = topFloors:Get(playerSpot.CFrame * CFrame.new(0, floorHeight * (totalFloors + 0.5), 0))
		playerTopFloor.Name = "topFloor"
		playerTopFloor.Parent = playerCastle
	else
		playerCastle
			:FindFirstChild("topFloor")
			:PivotTo(playerSpot.CFrame * CFrame.new(0, floorHeight * (totalFloors + 0.5), 0))
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
	playerPlatforms
		:FindFirstChild(player.Name)
		:SetAttribute("currentTower", newspot:FindFirstChildWhichIsA("Model").Name)
	if player.Character then
		if not player.Character:GetAttribute("inCannon") then
			player:LoadCharacter()
		end
	end
end
--TODO: Check if function works correctly
function castleService.updateTowerPrivacy(player, newStatus)
	local playerTower = castleFolder:FindFirstChild(player.Name):FindFirstChildWhichIsA("Model")
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
		local newCastle = Instance.new("Model")
		newCastle.Name = player.Name
		local newSpot = castleService.findSpot()
		newSpot.Name = player.Name
		newCastle.Parent = newSpot
		castleService.updateTower(player)
		local newplatform = ReplicatedStorage.assets.playerPlatform:Clone()
		newplatform:AddPersistentPlayer(player)
		newplatform.Name = player.Name
		newplatform.Parent = playerPlatforms
		castleService.updatePlatform(player, newSpot)
		local playerData = dataService.getPlayerData(player)
		newCastle:SetAttribute("status", playerData.towerStatus)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerPlatforms:WaitForChild(player.Name):Destroy()
		for i, v in pairs(castleFolder:GetChildren()) do
			if v:FindFirstChildWhichIsA("Model") and v.Name == player.Name then
				for countItem, floorItem in pairs(v:GetChildren()) do
					if floorItem:GetAttribute("isFloor") then
						if countItem % 10 == 0 then
							task.wait()
						end
						floors:Return(floorItem)
					end
					if floorItem.Name == "topFloor" then
						topFloors:Return(floorItem)
					end
				end
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
		castleService.updatePlatform(player, castleFolder:FindFirstChild(targetPlayer.Name))
		return true
	end)
end

return castleService
