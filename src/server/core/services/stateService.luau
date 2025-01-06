local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local mod = require(ReplicatedStorage.shared.utilities.createUtil)
local zap = require(ServerStorage.zap)
local Sift = require(ReplicatedStorage.sharedPackages.Sift)

local folderService = require(script.Parent.folderService)

local stateService = {}

function stateService.start()
	zap.editRagdollState.On(function(player, bool)
		local MotorFolder = folderService.getPlayerInfo()[player.Name].Motors

		local Character = player.Character
		if Character ~= nil then
			local Humanoid = Character:WaitForChild("Humanoid")
			local Root = Character:FindFirstChild("HumanoidRootPart")

			if bool then
				if Root then
					Root.CanCollide = false
				end

				for _, bodyPart in pairs(Character:GetChildren()) do
					if bodyPart:IsA("BasePart") then
						for _, motor in pairs(bodyPart:GetChildren()) do
							if motor:IsA("Motor6D") then
								table.insert(MotorFolder, motor)
							end
						end
					end
				end
			else
				if Root then
					Root.CanCollide = true
				end

				local function returnMotor(joint, part)
					local Joint = Sift.Array.at(Sift.Array.find(MotorFolder, joint))
					if Joint then
						if part then
							Joint.Parent = part
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
			end
		end

		zap.replicateNewMotors.Fire(player, MotorFolder)
	end)
end

return stateService
