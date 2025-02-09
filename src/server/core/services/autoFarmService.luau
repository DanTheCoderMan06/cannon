local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local playerBase = DataStoreService:GetDataStore("playerBase")
local dataService = require(ServerStorage.server.services.dataService)

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

local autoFarmService = {}

local zap = require(ServerStorage.zap)
local startTimes = {}

local function onPlayerAdded(player)
	local joinData = player:GetJoinData()
	local teleportData = joinData.TeleportData or {}
	player:SetAttribute("autoFarming", teleportData.autoFarming)
	startTimes[player.Name] = os.time()
end

local function onPlayerRemoving(player)
	startTimes[player.Name] = nil
end

function autoFarmService.migrate(player)
	local teleportOptions = Instance.new("TeleportOptions")
	local teleportData = {
		autoFarming = true,
	}
	teleportOptions:SetTeleportData(teleportData)
	TeleportService:TeleportAsync(game.PlaceId, { player }, teleportOptions)
end

function autoFarmService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	zap.toggleAutoFarm.SetCallback(function(player)
		startTimes[player.Name] = os.time()
		player:SetAttribute("autoFarming", not player:GetAttribute("autoFarming"))
		return true
	end)
	task.spawn(function()
		while true do
			task.wait(60)
			for _, v in pairs(Players:GetPlayers()) do
				if os.time() - startTimes[v.Name] > 20 or RunService:IsStudio() then
					autoFarmService.migrate(v)
				end
			end
		end
	end)
end

return autoFarmService
