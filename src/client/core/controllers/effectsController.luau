local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local effectsController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local camTrove

local config = require(ReplicatedStorage.shared.config.effectsConfig)

function effectsController.start()
	local localPlayer = Players.LocalPlayer
	RunService:BindToRenderStep("effectsHandler", Enum.RenderPriority.Camera.Value, function()
		local character = localPlayer.Character
		if not character then
			return
		end
		local part = character.PrimaryPart
		if not part then
			return
		end
		local currentAltitude = part.Position.Y
		local timeOfDay = (math.max(0, currentAltitude - (config.nightSky - config.nightSkyLerp)))
				/ config.nightSkyLerp
				* 12
			+ 11.99
		print(timeOfDay)
		Lighting.ClockTime = timeOfDay
	end)
end

return effectsController
