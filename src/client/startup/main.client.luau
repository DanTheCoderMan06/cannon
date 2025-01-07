local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientModules = ReplicatedStorage.client
local sharedModules = ReplicatedStorage.shared

local startupUtil = require(sharedModules.utilities.startupUtil)

local CONTROLLER_NAME_FORMAT = "Controller$"

task.spawn(function()
	local Players = game:GetService("Players")
	local Player = Players.LocalPlayer

	Player.CharacterAdded:Connect(function()
		task.defer(function()
			startupUtil.startup({
				path = clientModules.character,
				nameFormat = CONTROLLER_NAME_FORMAT,
			})
		end)
	end)
end)

startupUtil.startup({
	path = clientModules.controllers,
	nameFormat = CONTROLLER_NAME_FORMAT,
})
