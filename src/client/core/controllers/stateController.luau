local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Player = Players.LocalPlayer
local Character
local Humanoid

local sharedModules = ReplicatedStorage.sharedPackages
local Signal = require(sharedModules.Signal)

local stateController = {
	events = {},
}
local zap = require(ReplicatedStorage.zap)

local initialized = false
local initializedEvent = Signal.new()

local windController = require(ReplicatedStorage.client.controllers.windController)

function stateController.getEvents()
	if not initialized then
		initializedEvent:Wait()
	end
	return stateController.events
end

function stateController.start()
	local LocalEvent = Signal.new()
	stateController.events.radgollEvent = LocalEvent

	local function SetMotorsToDefault()
		RunService.Heartbeat:Wait()
		if Humanoid.RigType == Enum.HumanoidRigType.R15 then
			for _, part in pairs(Character:GetChildren()) do
				if part:IsA("BasePart") then
					for _, motor in pairs(part:GetChildren()) do
						if motor:IsA("Motor6D") then
							motor.C0 = CFrame.new(motor.C0.X, motor.C0.Y, motor.C0.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
							motor.C1 = CFrame.new(motor.C1.X, motor.C1.Y, motor.C1.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
						end
					end
				end
			end
		end
	end

	local function HumanoidPhysics()
		Humanoid.AutoRotate = false
	end

	local function HumanoidGettingUp()
		Humanoid.AutoRotate = true
	end

	local function HumanoidLanded()
		local Root = Character:FindFirstChild("HumanoidRootPart")
		if Root then
			local Speed = Root.AssemblyLinearVelocity.Magnitude
			if Speed > 75 and not Player:GetAttribute("inCannon") then
				windController.toggle(false)
				LocalEvent:Fire(true)
			end
		end
	end

	zap.getUp.On(function(...)
		LocalEvent:Fire(false)
	end)

	initialized = true
	initializedEvent:Fire()

	Player.CharacterAdded:Connect(function(character)
		Character = character
		Humanoid = Character:WaitForChild("Humanoid")

		task.spawn(SetMotorsToDefault)

		for _, scale in pairs(Humanoid:GetChildren()) do
			if scale:IsA("NumberValue") then
				scale.Changed:Connect(function()
					task.spawn(SetMotorsToDefault)
				end)
			end
		end

		Humanoid.Died:Connect(function()
			local FindRoot = Character:FindFirstChild("HumanoidRootPart")
			if FindRoot then
				FindRoot.CanCollide = false
				Humanoid.AutoRotate = false
			end

			for _, bodyPart in pairs(Character:GetChildren()) do
				if bodyPart:IsA("BasePart") then
					for _, motor in pairs(bodyPart:GetChildren()) do
						if motor:IsA("Motor6D") then
							motor:Destroy()
						end
					end
				end
			end
		end)
	end)
end

return stateController
