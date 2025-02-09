local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Signal = require(ReplicatedStorage.sharedPackages.Signal)
local controlsController = {}

local function constantMovement(dt)
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	local playerPlatform = workspace:WaitForChild("playerPlatforms"):FindFirstChild(Players.LocalPlayer.Name)
	if not playerPlatform then
		return
	end
	local cannonPart = playerPlatform:FindFirstChild("cannonPart", true)
	if not cannonPart then
		return
	end
	character:WaitForChild("Humanoid"):MoveTo(cannonPart.Position)
end

function controlsController.start()
	local Player = Players.LocalPlayer

	local RagdollEvent

	local function Ragdoll(bool)
		if Player.Character.Humanoid.Health > 0 then
			print(bool)
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
		ContextActionService:BindAction("ragdoll", ActivateRagdoll, true, Enum.KeyCode.F, Enum.KeyCode.ButtonX)
		ContextActionService:SetTitle("ragdoll", "Doll")
		ContextActionService:SetPosition("ragdoll", UDim2.new(0.5, 0, 0, 0))
	end

	Players.LocalPlayer:GetAttributeChangedSignal("autoFarming"):Connect(function()
		local isFarming = Players.LocalPlayer:GetAttribute("autoFarming")

		local FREEZE_ACTION = "freezeMovement"

		if isFarming then
			ContextActionService:BindAction(FREEZE_ACTION, function()
				return Enum.ContextActionResult.Sink
			end, false, unpack(Enum.PlayerActions:GetEnumItems()))
			RunService:BindToRenderStep("moveCharacter", Enum.RenderPriority.Last.Value, constantMovement)
		else
			ContextActionService:UnbindAction(FREEZE_ACTION)
			RunService:UnbindFromRenderStep("moveCharacter")
		end
	end)
end

return controlsController
