local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local serverPackages = ServerStorage.serverPackages

local profileStore = require(serverPackages.ProfileStore)

local Players = game:GetService("Players")

local profileTemplate = require(ServerStorage.server.modules.profileTemplate)
local PlayerStore = profileStore.New("PlayerDataStoreDEV5", profileTemplate)
local Profiles = {}

local dataService = {}

local zap = require(ServerStorage.zap)

local Sift = require(sharedPackages.Sift)
local Signal = require(sharedPackages.Signal)

local notificationConfig = require(ReplicatedStorage.shared.config.notificationConfig)
local gamepasses = require(ReplicatedStorage.shared.config.gamepasses)

local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)
dataService.dailyReward = Signal.new()

function dataService.giveRewards(player)
	local profile = Profiles[player]
	if os.time() - profile.Data.lastClaimed >= 24 * 60 * 60 then
		profile.Data.lastClaimed = os.time()
		profile.Data.daysPlayed += 1
		zap.dataChanged.Fire(player, profile.Data)
	end
	for _, v in pairs(profile.Data.notificationQueue) do
		local notificationInfo = notificationConfig.notifications[v]
		notificationInfo.callback(profile)
	end
	table.clear(profile.Data.notificationQueue)
end

function dataService.getGlobalPlayerData(user)
	if Players:GetPlayerByUserId(user) and RunService:IsStudio() == false then
		return Profiles[Players:GetPlayerByUserId(user)]
	end
	local playerData = PlayerStore:GetAsync("Player_" .. tostring(user))
	return playerData
end

function dataService.overwriteUserData(playerData)
	playerData:SetAsync()
end

function dataService.loadGamepasses(player)
	local playerProfile = Profiles[player]

	for _, v in pairs(gamepasses) do
		if v.cannonName then
			if marketplaceUtil.userOwnsGamepass(player, v.id) then
				if not table.find(playerProfile.Data.cannons, v.cannonName) then
					table.insert(playerProfile.Data.cannons, v.cannonName)
				end
			end
		end
	end
end

function dataService.start()
	local function PlayerAdded(player)
		task.wait(0)
		local profile = PlayerStore:StartSessionAsync(`Player_{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		if profile ~= nil then
			profile:AddUserId(player.UserId)
			profile:Reconcile()
			profile.OnSessionEnd:Connect(function()
				Profiles[player] = nil
				player:Kick(`Profile session end - Please rejoin`)
			end)
			if player.Parent == Players then
				Profiles[player] = profile
				local connection
				connection = Players.PlayerRemoving:Connect(function(playerLeaving)
					if player ~= playerLeaving then
						return
					end
					if profile ~= nil then
						profile:EndSession()
					end
					profile = nil
					connection:Disconnect()
				end)

				print(`Profile loaded for {player.DisplayName}!`)

				profile.Data.lastEntered = os.time()
				if RunService:IsStudio() then
					profile.Data.daysClaimed = {}
					profile.Data.cannonTier = 0
					profile.Data.doubleMoney = false
				end

				dataService.loadGamepasses(player)

				local leaderstats = ReplicatedStorage.assets.statsFolder:Clone()
				leaderstats.Name = "leaderstats"
				leaderstats.Parent = player
				dataService.updateLeaderstats(player)

				dataService.giveRewards(player)
				zap.dataChanged.Fire(player, profile.Data)

				profile.Data.firstTimeRewards = false
				profile.Data.firstTime = false
			else
				profile:EndSession()
			end
		else
			player:Kick(`Profile load fail - Please rejoin`)
		end
	end

	for _, player in Players:GetPlayers() do
		task.spawn(PlayerAdded, player)
	end

	Players.PlayerAdded:Connect(PlayerAdded)

	task.spawn(function()
		while true do
			task.wait(30)
			for player, profile in pairs(Profiles) do
				dataService.giveRewards(player)
			end
		end
	end)
end

function dataService.updateLeaderstats(player)
	for key, value in pairs(Profiles[player].Data) do
		for i, v in pairs(player:WaitForChild("leaderstats"):GetChildren()) do
			if key == v:GetAttribute("statName") then
				v.Value = value
				break
			end
		end
	end
end

function dataService.updatePlayerData(player: Player, newData)
	Profiles[player].Data = newData
	zap.dataChanged.Fire(player, newData)
	dataService.updateLeaderstats(player)
end

function dataService.getPlayerData(player: Player)
	repeat
		task.wait()
	until Profiles[player] ~= nil
	return Sift.Dictionary.copyDeep(Profiles[player].Data)
end

return dataService
