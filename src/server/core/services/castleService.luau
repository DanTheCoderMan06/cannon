local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local serverPackages = ServerStorage.serverPackages

local profileStore = require(serverPackages.ProfileStore)

local Players = game:GetService("Players")

local castleService = {}

local Sift = require(sharedPackages.Sift)

local castleFolder = workspace:WaitForChild("castles")
local dataService = require(ServerStorage.server.services.dataService)

function castleService.updateTower(player)
	local playerData = dataService.getPlayerData(player)
end

function castleService.findSpot()
	for i, v in pairs(castleFolder:GetChildren()) do
		if v.name == "spot" then
			return v
		end
	end
end

function castleService.start()
	Players.PlayerAdded:Connect(function(player)
		local newCastle = Instance.new("Folder")
		newCastle.Name = player.Name
		local newSpot = castleService.findSpot()
		newSpot.name = player.Name
		castleService.updateTower(player, newSpot)
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
