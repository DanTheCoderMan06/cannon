local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local serverPackages = ServerStorage.serverPackages

local profileStore = require(serverPackages.ProfileStore)

local Players = game:GetService("Players")

local profileTemplate = require(ServerStorage.server.modules.profileTemplate)
local PlayerStore = profileStore.New("PlayerStoreV2", profileTemplate)
local Profiles = {}

local dataService = {}

local zap = require(ServerStorage.zap)

local Sift = require(sharedPackages.Sift)

function dataService.start()
	local function PlayerAdded(player)
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
				print(`Profile loaded for {player.DisplayName}!`)

				local leaderstats = ReplicatedStorage.assets.statsFolder:Clone()
				leaderstats.Name = "leaderstats"
				leaderstats.Parent = player
				dataService.updateLeaderstats(player)
				profile.Data.cannon = 204
				zap.dataChanged.Fire(player, profile.Data)
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

	Players.PlayerRemoving:Connect(function(player)
		local profile = Profiles[player]
		if profile ~= nil then
			profile:EndSession()
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
