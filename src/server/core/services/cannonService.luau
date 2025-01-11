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

local cannon = require(ServerStorage.server.objects.cannon)

local Trove = require(ReplicatedStorage.sharedPackages.Trove)

function cannonService.start()
	Players.PlayerAdded:Connect(function(player)
		local playerData = dataService.getPlayerData(player)
		local targetCannon =
			ReplicatedStorage.assets.cannons:FindFirstChild(cannonConfig.getCannon(playerData.cannon)):Clone()
		targetCannon.Name = player.Name
		local cTrove = Trove.new()
		cTrove:Add(
			cannon.new({
				owner = player,
				model = targetCannon:FindFirstChildWhichIsA("Model"),
				power = cannonConfig.getPower(playerData.cannon),
			}),
			"destroy"
		)
		targetCannon.Parent = playerPlatforms:WaitForChild(player.Name)
		targetCannon
			:FindFirstChildWhichIsA("Model")
			:PivotTo(playerPlatforms:WaitForChild(player.Name):FindFirstChild("cannonPosition").CFrame)
		cTrove:AttachToInstance(targetCannon)
	end)
	Players.PlayerRemoving:Connect(function(player)
		if playerCannons:FindFirstChild(player.Name) then
			playerCannons:FindFirstChild(player.Name):Destroy()
		end
	end)
end

return cannonService
