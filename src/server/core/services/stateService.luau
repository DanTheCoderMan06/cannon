local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local mod = require(ReplicatedStorage.shared.utilities.createUtil)
local zap = require(ServerStorage.zap)
local Sift = require(ReplicatedStorage.sharedPackages.Sift)

local folderService = require(script.Parent.folderService)

local stateService = {}

function stateService.start()
	--[[
	PhysicsService:RegisterCollisionGroup("players")
	PhysicsService:CollisionGroupSetCollidable("players", "players", false)
	PhysicsService:CollisionGroupSetCollidable("Default", "players", true)
	--]]

	zap.editRagdollState.SetCallback(function(player, bool)
		local playerInfo = folderService.getPlayerInfo()
		local MotorFolder = playerInfo[player.Name].Motors

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
								motor.Enabled = false
								motor:SetAttribute("serverLoaded", true)
							end
						end
					end
				end
			else
				if Root then
					Root.CanCollide = true
				end

				local function returnMotor(joint, part)
					local Joint = Sift.Array.at(
						MotorFolder,
						Sift.Array.findWhere(MotorFolder, function(value)
							return value.Name == joint
						end)
					)
					Joint.Enabled = true
					Joint:SetAttribute("serverLoaded", nil)
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

				table.clear(MotorFolder)
			end
		end

		zap.replicateNewMotors.Fire(player, MotorFolder)
	end)
end

return stateService
