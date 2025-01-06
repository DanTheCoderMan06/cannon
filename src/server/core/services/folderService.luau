local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--local createUtil = require(ReplicatedStorage.shared.utilities.createUtil)

local folderService = {}

local zap = require(ServerStorage.zap)

local PlayerInfo = {}

function folderService.getPlayerInfo()
	return PlayerInfo
end

function folderService.start()
	Players.PlayerAdded:Connect(function(player)
		print("Player " .. player.Name .. " has joined the game")

		local PersonalFolder = {}
		PlayerInfo[player.Name] = PersonalFolder
		local Motors = {}
		PersonalFolder.Motors = Motors

		player.CharacterAdded:Connect(function(character)
			local Humanoid = character:WaitForChild("Humanoid")
			Humanoid.Died:Connect(function()
				table.clear(PersonalFolder.Motors)
				zap.replicateNewMotors.Fire(player, PersonalFolder.Motors)
			end)
		end)
	end)

	Players.PlayerRemoving:Connect(function(oldPlayer)
		print("Player " .. oldPlayer.Name .. " has left the game")

		local OldFolder = PlayerInfo[oldPlayer.Name]
		if OldFolder then
			PlayerInfo[oldPlayer.Name] = nil
		else
			warn("Player " .. oldPlayer.Name .. " does not have a personal folder")
		end
	end)
end

return folderService
