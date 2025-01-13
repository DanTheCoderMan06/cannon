local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")

local zap = require(ServerStorage.zap)

local sharedModules = ReplicatedStorage.sharedPackages
local Sift = require(sharedModules.Sift)

local OverallPhysics = nil

local RootPhysics = PhysicalProperties.new(0.01, 0.3, 0.5)

local HeadPhysics = PhysicalProperties.new(1, 0.3, 0.5)
local UpperTorsoPhysics = PhysicalProperties.new(0.5, 0.3, 0.5)
local LowerTorsoPhysics = PhysicalProperties.new(0.5, 0.3, 0.5) --PhysicalProperties.new(0.05, 0.3, 0.5)

local UpperArmPhysics = PhysicalProperties.new(1, 0.3, 0.5)
local LowerArmPhysics = PhysicalProperties.new(1, 0.3, 0.5)
local HandPhysics = PhysicalProperties.new(1.5, 0.6, 0.5)

local UpperLegPhysics = PhysicalProperties.new(1, 0.3, 0.5)
local LowerLegPhysics = PhysicalProperties.new(1, 0.3, 0.5)
local FootPhysics = PhysicalProperties.new(1.5, 0.6, 0.5)

local playerCollisionGroupName = "Players"

PhysicsService:RegisterCollisionGroup(playerCollisionGroupName)
PhysicsService:CollisionGroupSetCollidable(playerCollisionGroupName, playerCollisionGroupName, true)

local previousCollisionGroups = {}

local jointService = {}

local zone = require(sharedModules.Zone)

function jointService.start()
	local function PlayerAdded(player)
		local function setCollisionGroup(object)
			if object:IsA("BasePart") then
				previousCollisionGroups[object] = object.CollisionGroup

				object.CollisionGroup = playerCollisionGroupName
			end
		end

		local function setCollisionGroupRecursive(object)
			setCollisionGroup(object)

			for _, child in ipairs(object:GetChildren()) do
				setCollisionGroupRecursive(child)
			end
		end

		local function resetCollisionGroup(object)
			local previousCollisionGroupName = previousCollisionGroups[object]
			if not previousCollisionGroupName then
				return
			end

			object.CollisionGroup = previousCollisionGroupName
			previousCollisionGroups[object] = nil
		end

		local function CharacterAdded(character)
			local Humanoid = character:WaitForChild("Humanoid")
			local Root = character:WaitForChild("HumanoidRootPart")
			local Head = character:WaitForChild("Head")

			Humanoid.BreakJointsOnDeath = false

			local function getAttachment0(attachmentName)
				for _, child in pairs(character:GetChildren()) do
					local attachment = child:FindFirstChild(attachmentName)
					if attachment then
						return attachment
					end
				end
				return nil
			end

			if Humanoid.RigType == Enum.HumanoidRigType.R15 then
				Head.CanCollide = true
				--RunService.Heartbeat:Wait()

				local function CreateJoint(part0, part1, attachment, constraintType, properties)
					if part0 and part1 and attachment and constraintType then
						local rigAttachment = attachment .. "RigAttachment"
						local constraint = constraintType .. "Constraint"
						if part0:FindFirstChild(rigAttachment) and part1:FindFirstChild(rigAttachment) then
							local findJoint = character:FindFirstChild(attachment .. "Joint")
							if not findJoint then
								local Joint = Instance.new(constraint)
								Joint.Name = attachment .. "Joint"
								Joint.Attachment0 = part0[rigAttachment]
								Joint.Attachment1 = part1[rigAttachment]

								for _, propertyData in pairs(properties or {}) do
									Joint[propertyData[1]] = propertyData[2]
								end

								Joint.Parent = character
							else
								findJoint.Attachment0 = part0[rigAttachment]
								findJoint.Attachment1 = part1[rigAttachment]
							end
						else
							warn("Cannot find attachments")
						end
					else
						warn("Error")
					end
				end
				local ShoulderProperties = { -- Upper arm
					{ "LimitsEnabled", true },
					{ "UpperAngle", 180 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -135 },
					{ "TwistUpperAngle", 135 },
				}
				local ElbowProperties = { -- Lower arm
					{ "LimitsEnabled", true },
					{ "UpperAngle", 135 },
					{ "LowerAngle", 0 },
				}
				local WristProperties = { -- Hand
					{ "LimitsEnabled", true },
					{ "UpperAngle", 45 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -95 },
					{ "TwistUpperAngle", 95 },
				}
				local KneeProperties = { -- Lower leg
					{ "LimitsEnabled", true },
					{ "UpperAngle", 0 },
					{ "LowerAngle", -135 },
				}
				local AnkleProperties = { -- Foot
					--[[{"LimitsEnabled", true};
                    {"UpperAngle", 0};
                    {"LowerAngle", -50};]]
					{ "LimitsEnabled", true },
					{ "UpperAngle", 40 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -30 },
					{ "TwistUpperAngle", 30 },
				}
				local LeftHipProperties = { -- Upper left leg
					{ "LimitsEnabled", true },
					{ "UpperAngle", 70 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -95 },
					{ "TwistUpperAngle", 25 },
				}
				local RightHipProperties = { -- Upper right leg
					{ "LimitsEnabled", true },
					{ "UpperAngle", 70 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -25 },
					{ "TwistUpperAngle", 95 },
				}
				local NeckProperties = { -- Head
					{ "LimitsEnabled", true },
					{ "UpperAngle", 45 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -95 },
					{ "TwistUpperAngle", 95 },
				}
				local WaistProperties = { -- Upper torso
					{ "LimitsEnabled", true },
					{ "UpperAngle", 45 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -45 },
					{ "TwistUpperAngle", 45 },
				}

				local function ApplyR15Joints()
					CreateJoint(character.HumanoidRootPart, character.LowerTorso, "Root", "Hinge", {
						{ "LimitsEnabled", true },
						{ "UpperAngle", 0 },
						{ "LowerAngle", 0 },
					})
					CreateJoint(character.LowerTorso, character.UpperTorso, "Waist", "BallSocket", WaistProperties)
					CreateJoint(character.UpperTorso, character.Head, "Neck", "BallSocket", NeckProperties)
					CreateJoint(
						character.UpperTorso,
						character.LeftUpperArm,
						"LeftShoulder",
						"BallSocket",
						ShoulderProperties
					)
					CreateJoint(
						character.UpperTorso,
						character.RightUpperArm,
						"RightShoulder",
						"BallSocket",
						ShoulderProperties
					)
					CreateJoint(character.LeftUpperArm, character.LeftLowerArm, "LeftElbow", "Hinge", ElbowProperties)
					CreateJoint(
						character.RightUpperArm,
						character.RightLowerArm,
						"RightElbow",
						"Hinge",
						ElbowProperties
					)
					CreateJoint(character.LeftLowerArm, character.LeftHand, "LeftWrist", "BallSocket", WristProperties)
					CreateJoint(
						character.RightLowerArm,
						character.RightHand,
						"RightWrist",
						"BallSocket",
						WristProperties
					)
					CreateJoint(
						character.LowerTorso,
						character.LeftUpperLeg,
						"LeftHip",
						"BallSocket",
						LeftHipProperties
					)
					CreateJoint(
						character.LowerTorso,
						character.RightUpperLeg,
						"RightHip",
						"BallSocket",
						RightHipProperties
					)
					CreateJoint(character.LeftUpperLeg, character.LeftLowerLeg, "LeftKnee", "Hinge", KneeProperties)
					CreateJoint(character.RightUpperLeg, character.RightLowerLeg, "RightKnee", "Hinge", KneeProperties)
					CreateJoint(character.LeftLowerLeg, character.LeftFoot, "LeftAnkle", "BallSocket", AnkleProperties)
					CreateJoint(
						character.RightLowerLeg,
						character.RightFoot,
						"RightAnkle",
						"BallSocket",
						AnkleProperties
					)
				end
				ApplyR15Joints()

				local function ApplyCollisionConstraints()
					local function CreateNoCollision(part0, part1)
						local Constraint = Instance.new("NoCollisionConstraint")
						Constraint.Name = part0.Name .. "NoCollision"
						Constraint.Enabled = true
						Constraint.Part0 = part0
						Constraint.Part1 = part1
						Constraint.Parent = part0
					end

					CreateNoCollision(character.LeftUpperLeg, character.RightUpperLeg)
					CreateNoCollision(character.LeftUpperLeg, character.UpperTorso)
					CreateNoCollision(character.RightUpperLeg, character.UpperTorso)
					CreateNoCollision(character.LeftFoot, character.LeftUpperLeg)
					CreateNoCollision(character.RightFoot, character.RightUpperLeg)
					CreateNoCollision(character.LeftUpperArm, character.Head)
					CreateNoCollision(character.RightUpperArm, character.Head)
				end
				ApplyCollisionConstraints()

				local function SetAxis(part0, part1, attachment, axis, saxis)
					local attachmentName = attachment .. "RigAttachment"

					local attachment0 = part0:WaitForChild(attachmentName)
					attachment0.Axis = axis
					attachment0.SecondaryAxis = saxis

					local attachment1 = part1:WaitForChild(attachmentName)
					attachment1.Axis = axis
					attachment1.SecondaryAxis = saxis
				end

				local function SetAxises()
					SetAxis(character.UpperTorso, character.Head, "Neck", Vector3.new(0, 1, 0), Vector3.new(0, 0, -1))
					SetAxis(
						character.LowerTorso,
						character.UpperTorso,
						"Waist",
						Vector3.new(0, 1, 0),
						Vector3.new(0, 0, -1)
					)
					SetAxis(
						character.UpperTorso,
						character.LeftUpperArm,
						"LeftShoulder",
						Vector3.new(0, -1, 0),
						Vector3.new(-1, 0, 0)
					)
					SetAxis(
						character.UpperTorso,
						character.RightUpperArm,
						"RightShoulder",
						Vector3.new(0, -1, 0),
						Vector3.new(1, 0, 0)
					)
					SetAxis(
						character.LowerTorso,
						character.LeftUpperLeg,
						"LeftHip",
						Vector3.new(0, -1, 0),
						Vector3.new(0, 0, -1)
					)
					SetAxis(
						character.LowerTorso,
						character.RightUpperLeg,
						"RightHip",
						Vector3.new(0, -1, 0),
						Vector3.new(0, 0, -1)
					)
					SetAxis(
						character.LeftLowerArm,
						character.LeftHand,
						"LeftWrist",
						Vector3.new(0, -1, 0),
						Vector3.new(1, 0, 0)
					)
					SetAxis(
						character.RightLowerArm,
						character.RightHand,
						"RightWrist",
						Vector3.new(0, -1, 0),
						Vector3.new(-1, 0, 0)
					)
					SetAxis(
						character.LeftLowerLeg,
						character.LeftFoot,
						"LeftAnkle",
						Vector3.new(0, -1, 0),
						Vector3.new(0, 0, -1)
					)
					SetAxis(
						character.RightLowerLeg,
						character.RightFoot,
						"RightAnkle",
						Vector3.new(0, -1, 0),
						Vector3.new(0, 0, -1)
					)

					character.LowerTorso.LeftHipRigAttachment.Axis = Vector3.new(0, -0.643, -0.766)
					character.LowerTorso.LeftHipRigAttachment.SecondaryAxis = Vector3.new(-0, 0.766, -0.643)
					character.LowerTorso.RightHipRigAttachment.Axis = Vector3.new(0, -0.643, -0.766)
					character.LowerTorso.RightHipRigAttachment.SecondaryAxis = Vector3.new(-0, 0.766, -0.643)

					character.LeftLowerLeg.LeftAnkleRigAttachment.Axis = Vector3.new(0, -0.94, 0.342)
					character.LeftLowerLeg.LeftAnkleRigAttachment.SecondaryAxis = Vector3.new(0, -0.342, -0.94)
					character.RightLowerLeg.RightAnkleRigAttachment.Axis = Vector3.new(0, -0.94, 0.342)
					character.RightLowerLeg.RightAnkleRigAttachment.SecondaryAxis = Vector3.new(0, -0.342, -0.94)
				end
				SetAxises()

				local function SetMotorsToDefault()
					RunService.Heartbeat:Wait()
					if Humanoid.RigType == Enum.HumanoidRigType.R15 then
						for _, part in pairs(character:GetChildren()) do
							if part:IsA("BasePart") then
								for _, motor in pairs(part:GetChildren()) do
									if motor:IsA("Motor6D") then
										motor.C0 =
											CFrame.new(motor.C0.X, motor.C0.Y, motor.C0.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
										motor.C1 =
											CFrame.new(motor.C1.X, motor.C1.Y, motor.C1.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
									end
								end
							end
						end
					end
				end

				task.spawn(SetMotorsToDefault)

				for _, scale in pairs(Humanoid:GetChildren()) do
					if scale:IsA("NumberValue") then
						scale.Changed:Connect(function()
							task.spawn(SetMotorsToDefault)
						end)
					end
				end

				Root.CustomPhysicalProperties = OverallPhysics or RootPhysics
				Head.CustomPhysicalProperties = OverallPhysics or HeadPhysics
				character.UpperTorso.CustomPhysicalProperties = OverallPhysics or UpperTorsoPhysics
				character.LowerTorso.CustomPhysicalProperties = OverallPhysics or LowerTorsoPhysics
				character.LeftUpperArm.CustomPhysicalProperties = OverallPhysics or UpperArmPhysics
				character.RightUpperArm.CustomPhysicalProperties = OverallPhysics or UpperArmPhysics
				character.LeftLowerArm.CustomPhysicalProperties = OverallPhysics or LowerArmPhysics
				character.RightLowerArm.CustomPhysicalProperties = OverallPhysics or LowerArmPhysics
				character.LeftHand.CustomPhysicalProperties = OverallPhysics or HandPhysics
				character.RightHand.CustomPhysicalProperties = OverallPhysics or HandPhysics
				character.LeftUpperLeg.CustomPhysicalProperties = OverallPhysics or UpperLegPhysics
				character.RightUpperLeg.CustomPhysicalProperties = OverallPhysics or UpperLegPhysics
				character.LeftLowerLeg.CustomPhysicalProperties = OverallPhysics or LowerLegPhysics
				character.RightLowerLeg.CustomPhysicalProperties = OverallPhysics or LowerLegPhysics
				character.LeftFoot.CustomPhysicalProperties = OverallPhysics or FootPhysics
				character.RightFoot.CustomPhysicalProperties = OverallPhysics or FootPhysics

				local Desc = Humanoid:WaitForChild("HumanoidDescription")
				Desc.Changed:Connect(function()
					if not character:FindFirstChild("HumanoidRootPart") then
						return nil
					end
					ApplyR15Joints()
					SetAxises()
					ReplicatedStorage:WaitForChild("PlayerInfo")[player.Name].Motors:ClearAllChildren()
					task.spawn(function()
						zap.getUp.Fire(player)
					end)
				end)
			else
				Head.Size = Vector3.new(1, 1, 1)

				character.PrimaryPart = Root
				local function CreateAttachment(parent, pos, torsopos, axis, saxis)
					local Attachment = Instance.new("Attachment")
					Attachment.Name = parent.Name .. " Attachment"
					Attachment.Position = pos
					Attachment.Axis = axis
					Attachment.SecondaryAxis = saxis
					Attachment.Parent = parent

					local TorsoAttach = Instance.new("Attachment")
					TorsoAttach.Name = parent.Name .. " Attachment"
					TorsoAttach.Position = torsopos
					TorsoAttach.Axis = axis
					TorsoAttach.SecondaryAxis = saxis
					TorsoAttach.Parent = character.Torso
				end

				local LeftArmPos, LeftArmTorsoPos
				local RightArmPos, RightArmTorsoPos

				for _, v in pairs(character:GetChildren()) do
					if v:IsA("CharacterMesh") then
						if v.BodyPart == Enum.BodyPart.LeftArm then
							LeftArmPos = Vector3.new(0.5, 0.5, 0)
							LeftArmTorsoPos = Vector3.new(-1, 0.5, 0)
						elseif v.BodyPart == Enum.BodyPart.RightArm then
							RightArmPos = Vector3.new(-0.5, 0.5, 0)
							RightArmTorsoPos = Vector3.new(1, 0.5, 0)
						end
					end
				end

				if LeftArmPos and LeftArmTorsoPos then
				else
					LeftArmPos = Vector3.new(0, 0.5, 0)
					LeftArmTorsoPos = Vector3.new(-1.5, 0.5, 0)
				end

				if RightArmPos and RightArmTorsoPos then
				else
					RightArmPos = Vector3.new(0, 0.5, 0)
					RightArmTorsoPos = Vector3.new(1.5, 0.5, 0)
				end

				local LegPos = Vector3.new(0, 1, 0)
				CreateAttachment(
					Head,
					Vector3.new(0, -0.5, 0),
					Vector3.new(0, 1, 0),
					Vector3.new(0, 1, 0),
					Vector3.new(0, 0, -1)
				)
				CreateAttachment(Root, Vector3.new(), Vector3.new(), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0))
				CreateAttachment(
					character["Left Arm"],
					LeftArmPos,
					LeftArmTorsoPos,
					Vector3.new(0, -1, 0),
					Vector3.new(-1, 0, 0)
				)
				CreateAttachment(
					character["Right Arm"],
					RightArmPos,
					RightArmTorsoPos,
					Vector3.new(0, -1, 0),
					Vector3.new(1, 0, 0)
				)
				CreateAttachment(
					character["Left Leg"],
					LegPos,
					Vector3.new(-0.5, -1, 0),
					Vector3.new(0, -1, 0),
					Vector3.new(0, 0, -1)
				)
				CreateAttachment(
					character["Right Leg"],
					LegPos,
					Vector3.new(0.5, -1, 0),
					Vector3.new(0, -1, 0),
					Vector3.new(0, 0, -1)
				)

				character.Torso["Left Arm Attachment"].Axis = Vector3.new(-1, 0, 0)
				character.Torso["Left Arm Attachment"].SecondaryAxis = Vector3.new(0, 1, 0)
				character.Torso["Right Arm Attachment"].Axis = Vector3.new(1, 0, 0)
				character.Torso["Right Arm Attachment"].SecondaryAxis = Vector3.new(0, 1, 0)

				local function CreateR6Joint(part, jointType, properties) -- Creates a joint
					if part then
						local attachmentName = part.Name .. " Attachment"

						local constraint = Instance.new(jointType .. "Constraint")
						constraint.Name = part.Name .. "Joint"
						constraint.Attachment0 = character.Torso:FindFirstChild(attachmentName)
						constraint.Attachment1 = part:FindFirstChild(attachmentName)

						for _, propertyData in pairs(properties or {}) do
							constraint[propertyData[1]] = propertyData[2]
						end

						constraint.Parent = character
					end
				end
				CreateR6Joint(Head, "BallSocket", {
					{ "LimitsEnabled", true },
					{ "UpperAngle", 45 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -90 },
					{ "TwistUpperAngle", 90 },
				})
				CreateR6Joint(Root, "Hinge", {
					{ "LimitsEnabled", true },
					{ "UpperAngle", 0 },
					{ "LowerAngle", 0 },
				})
				CreateR6Joint(character["Left Arm"], "BallSocket", {
					{ "LimitsEnabled", true },
					{ "UpperAngle", 120 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -105 },
					{ "TwistUpperAngle", 105 },
				})
				CreateR6Joint(character["Right Arm"], "BallSocket", {
					{ "LimitsEnabled", true },
					{ "UpperAngle", 120 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -105 },
					{ "TwistUpperAngle", 105 },
				})
				CreateR6Joint(character["Left Leg"], "BallSocket", {
					{ "LimitsEnabled", true },
					{ "UpperAngle", 60 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -105 },
					{ "TwistUpperAngle", 45 },
				})
				CreateR6Joint(character["Right Leg"], "BallSocket", {
					{ "LimitsEnabled", true },
					{ "UpperAngle", 60 },
					{ "TwistLimitsEnabled", true },
					{ "TwistLowerAngle", -45 },
					{ "TwistUpperAngle", 105 },
				})

				Root.CustomPhysicalProperties = OverallPhysics or RootPhysics
				character.Torso.CustomPhysicalProperties = OverallPhysics or UpperTorsoPhysics

				Head.CustomPhysicalProperties = OverallPhysics or HeadPhysics
				character["Left Arm"].CustomPhysicalProperties = OverallPhysics or UpperArmPhysics
				character["Right Arm"].CustomPhysicalProperties = OverallPhysics or UpperArmPhysics
				character["Left Leg"].CustomPhysicalProperties = OverallPhysics or UpperLegPhysics
				character["Right Leg"].CustomPhysicalProperties = OverallPhysics or UpperLegPhysics
			end

			spawn(function()
				RunService.Heartbeat:Wait()
				for _, part in pairs(character:GetChildren()) do
					if part:IsA("BasePart") then
						part:SetNetworkOwner(player)
					end
				end
			end)

			Humanoid.Died:Connect(function()
				local Root = character:FindFirstChild("HumanoidRootPart")
				if Root then
					Root.CanCollide = false
				end

				for _, bodyPart in pairs(character:GetChildren()) do
					if bodyPart:IsA("BasePart") then
						for _, motor in pairs(bodyPart:GetChildren()) do
							if motor:IsA("Motor6D") then
								motor:Destroy()
							end
						end
					end
				end
			end)

			setCollisionGroupRecursive(character)

			character.DescendantAdded:Connect(setCollisionGroup)
			character.DescendantRemoving:Connect(resetCollisionGroup)
		end

		if player.Character then
			CharacterAdded(player.Character)
		end

		player.CharacterAppearanceLoaded:Connect(CharacterAdded)
	end

	Players.PlayerAdded:Connect(PlayerAdded)
	for _, player in pairs(Players:GetPlayers()) do
		PlayerAdded(player)
	end
end

return jointService
