local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local zap = require(ReplicatedStorage.zap)

local cmdrController = {}

local cmdrConfig = require(ReplicatedStorage.cmdrConfig)

local function hasMod()
	if
		table.find(cmdrConfig.admins, Players.LocalPlayer.Name)
		or table.find(cmdrConfig.admins, Players.LocalPlayer.UserId)
	then
		return true
	end

	for _, group in pairs(cmdrConfig.groups) do
		if table.find(group.ranks, Players.LocalPlayer:GetRankInGroup(group)) then
			return true
		end
	end

	return false
end

function cmdrController.start()
	if not hasMod() then
		return
	end
	cmdr:SetActivationKeys({ game:GetService("RunService"):IsStudio() and Enum.KeyCode.M or Enum.KeyCode.F2 })
	zap.watchTarget.SetCallback(function(target)
		workspace.CurrentCamera.CameraSubject = target or game.Players.LocalPlayer.Character
	end)
end

return cmdrController
