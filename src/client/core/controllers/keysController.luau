local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Signal = require(ReplicatedStorage.sharedPackages.Signal)
local controlsController = {}

local function constantMovement(dt)
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	if character:GetAttribute("inCannon") then
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

function controlsController.freezeMovement(toggle)
	local FREEZE_ACTION = "freezeMovement"
	if toggle then
		ContextActionService:BindAction(FREEZE_ACTION, function()
			return Enum.ContextActionResult.Sink
		end, false, unpack(Enum.PlayerActions:GetEnumItems()))
	else
		ContextActionService:UnbindAction(FREEZE_ACTION)
	end
end

function controlsController.updateFarming()
	if Players.LocalPlayer.Character and Players.LocalPlayer.Character:GetAttribute("inCannon") then
		return
	end

	local isFarming = Players.LocalPlayer:GetAttribute("autoFarming")

	if isFarming then
		RunService:BindToRenderStep("moveCharacter", Enum.RenderPriority.Last.Value, constantMovement)
	else
		RunService:UnbindFromRenderStep("moveCharacter")
	end

	controlsController.freezeMovement(isFarming)
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
		controlsController.updateFarming()
	end)

	controlsController.updateFarming()

	repeat
		local success = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", false)
		end)
		task.wait()
	until success
end

return controlsController
