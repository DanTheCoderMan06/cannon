local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local serverPackages = ServerStorage.serverPackages

local Players = game:GetService("Players")

local castleService = {}

local Sift = require(sharedPackages.Sift)

local castleFolder = workspace:WaitForChild("castles")
local dataService = require(ServerStorage.server.services.dataService)

local castleFloor = ReplicatedStorage.assets:WaitForChild("castleFloor")
local floorHeight = castleFloor.ceiling.Position.Y - castleFloor.floor.Position.Y

function castleService.updateTower(player)
	local playerData = dataService.getPlayerData(player)
	local playerSpot = castleFolder:FindFirstChild(player.Name)
	local playerCastle = playerSpot:FindFirstChildWhichIsA("Folder")
	for i = 0, playerData.floors do
		if not playerCastle:FindFirstChild(i) then
			local newfloor = castleFloor:Clone()
			newfloor.Name = i
			newfloor:PivotTo(playerSpot.CFrame * CFrame.new(0, floorHeight * i, 0))
			newfloor.Parent = playerCastle
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

function castleService.start()
	Players.PlayerAdded:Connect(function(player)
		local newCastle = Instance.new("Folder")
		newCastle.Name = player.Name
		local newSpot = castleService.findSpot()
		newSpot.Name = player.Name
		newCastle.Parent = newSpot
		castleService.updateTower(player)
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
		for i, v in pairs(castleFolder:GetChildren()) do
			if v:FindFirstChildWhichIsA("Folder") and v.Name == player.Name then
				v:ClearAllChildren()
				v.Name = "spot"
			end
		end
	end)
end

return castleService
