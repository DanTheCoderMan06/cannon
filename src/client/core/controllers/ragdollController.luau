local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local sharedPackages = ReplicatedStorage.sharedPackages
local Signal = require(sharedPackages.Signal)

local DelayValue = 0

local stateController = require(script.Parent.stateController)

local ForceModule = require(ReplicatedStorage.shared.utilities.forceUtil)

local Player = Players.LocalPlayer
local Character
local Humanoid
local Root

local motorController = require(ReplicatedStorage.client.controllers.motorController)
local windController = require(ReplicatedStorage.client.controllers.windController)
local cameraController = require(ReplicatedStorage.client.controllers.cameraController)
local zap = require(ReplicatedStorage.zap)
local camerashaker = require(ReplicatedStorage.sharedPackages.camerashaker)
local Sift = require(ReplicatedStorage.sharedPackages.Sift)

-- FUNCTIONS --
local function LocalRagdoll(bool)
	if UIS.VREnabled then
		return
	end

	local State = Humanoid:GetState()
	if bool then
		if State ~= Enum.HumanoidStateType.Physics then
			zap.editRagdollState.Fire(true)
			DelayValue = DelayValue + 3

			Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			Root.CanCollide = false

			for _, bodyPart in pairs(Character:GetChildren()) do
				if bodyPart:IsA("BasePart") then
					for _, motor in pairs(bodyPart:GetChildren()) do
						if motor:IsA("Motor6D") then
							motorController.addMotor(motor)
							motor.Enabled = false
							--motor.Parent = Motors
						end
					end
				end
			end
		end
	else
		if State == Enum.HumanoidStateType.Physics then
			zap.editRagdollState.Fire(false)
			DelayValue = DelayValue + 3

			local function returnMotor(joint, part)
				local Joint = Sift.Array.at(
					motorController.getMotors(),
					Sift.Array.findWhere(motorController.getMotors(), function(value)
						return value.Name == joint
					end)
				)
				if Joint then
					if part then
						Joint.Enabled = false
					end
				end
			end

			if Humanoid.RigType == Enum.HumanoidRigType.R15 then
				returnMotor("Neck", Character:FindFirstChild("Head"))
				returnMotor("Waist", Character:FindFirstChild("UpperTorso"))
				returnMotor("Root", Character:FindFirstChild("LowerTorso"))
				returnMotor("LeftShoulder", Character:FindFirstChild("LeftUpperArm"))
				returnMotor("LeftElbow", Character:FindFirstChild("LeftLowerArm"))
				returnMotor("LeftWrist", Character:FindFirstChild("LeftHand"))
				returnMotor("RightShoulder", Character:FindFirstChild("RightUpperArm"))
				returnMotor("RightElbow", Character:FindFirstChild("RightLowerArm"))
				returnMotor("RightWrist", Character:FindFirstChild("RightHand"))
				returnMotor("LeftHip", Character:FindFirstChild("LeftUpperLeg"))
				returnMotor("LeftKnee", Character:FindFirstChild("LeftLowerLeg"))
				returnMotor("LeftAnkle", Character:FindFirstChild("LeftFoot"))
				returnMotor("RightHip", Character:FindFirstChild("RightUpperLeg"))
				returnMotor("RightKnee", Character:FindFirstChild("RightLowerLeg"))
				returnMotor("RightAnkle", Character:FindFirstChild("RightFoot"))
			else
				returnMotor("Neck", Character:FindFirstChild("Torso"))
				returnMotor("RootJoint", Character:FindFirstChild("HumanoidRootPart"))
				returnMotor("Left Shoulder", Character:FindFirstChild("Torso"))
				returnMotor("Right Shoulder", Character:FindFirstChild("Torso"))
				returnMotor("Left Hip", Character:FindFirstChild("Torso"))
				returnMotor("Right Hip", Character:FindFirstChild("Torso"))
			end
			motorController.clearLocalMotors()
			Root.CanCollide = true

			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
end

-- INITIALIZATION --
local ragdollController = {}
function ragdollController.start()
	local LocalEvent
	local camShake = camerashaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
		workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * shakeCf
	end)
	task.spawn(function()
		local events = stateController.getEvents()
		LocalEvent = events.radgollEvent

		LocalEvent:Connect(LocalRagdoll)
	end)

	local function GetMassOfModel(model)
		local mass = 0
		for i, v in pairs(model:GetChildren()) do
			if v:IsA("BasePart") then
				mass = mass + v:GetMass()
			elseif v:IsA("Accoutrement") then
				local Handle = v:FindFirstChildOfClass("BasePart")
				if Handle then
					mass = mass + Handle:GetMass()
				end
			end
		end
		return mass
	end

	zap.replicateRagdollState.On(function(data)
		windController.toggle(true)
		local force = data.force
		local rotforce = data.rotforce
		local Delay = data.delay
		local State = Humanoid:GetState()
		if State ~= Enum.HumanoidStateType.Physics and State ~= Enum.HumanoidStateType.Dead then
			LocalEvent:Fire(true)
		end
		windController.toggle(true)
		local CharacterMass = GetMassOfModel(Character)
		local torso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
		local f = force and (force * CharacterMass) or (Vector3.new())
		local angfor = rotforce and (rotforce * CharacterMass) or (Vector3.new())

		if data.camera then
			cameraController.trackObject(Player.Character.PrimaryPart, data.offset)
		end

		ForceModule:ApplyForce(torso, f, angfor)

		local DelayVal
		if Delay and tonumber(Delay) then
			DelayVal = Delay
		else
			DelayVal = 0
		end
		DelayValue = DelayValue + (Delay - 3)
		camShake:Shake(camerashaker.Presets.Explosion)
	end)

	Player.CharacterAdded:Connect(function(character)
		Character = character
		Humanoid = Character:WaitForChild("Humanoid")
		Root = Character:WaitForChild("HumanoidRootPart")
	end)
end

return ragdollController
