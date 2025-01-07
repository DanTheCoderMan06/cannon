local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local controlsController = {}

function controlsController.start()
	local Player = Players.LocalPlayer

	local RagdollEvent

	local function Ragdoll(bool)
		if Player.Character.Humanoid.Health > 0 then
			RagdollEvent:Fire(bool)
		end
	end

	local function ActivateRagdoll(actionName, actionState, inputObj)
		if actionState == Enum.UserInputState.Begin then
			local State = Player.Character.Humanoid:GetState()
			print(State)
			if State ~= Enum.HumanoidStateType.Physics then
				Ragdoll(true)
			else
				Ragdoll(false)
			end
		end
	end

	RagdollEvent = require(ReplicatedStorage.client.controllers.stateController).getEvents().radgollEvent

	if RunService:IsStudio() then
		print("Ragdoll Support")
		CAS:BindAction("ragdoll", ActivateRagdoll, true, Enum.KeyCode.F, Enum.KeyCode.ButtonX)
		CAS:SetTitle("ragdoll", "Doll")
		CAS:SetPosition("ragdoll", UDim2.new(0.5, 0, 0, 0))
	end
end

return controlsController
