local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local AcceptableEventTypes = {
	["RemoteEvent"] = true,
	["RemoteFunction"] = true,
	["BindableEvent"] = true,
	["BindableFunction"] = true,
}

local createUtil = {}

createUtil.Admins = {}

function createUtil:CreateFolder(name, parent)
	if name and parent then
		local FindFolder = parent:FindFirstChild(name)
		if FindFolder then
			if FindFolder:IsA("Folder") then
				warn("Folder " .. name .. " already exists")
				return FindFolder
			end
		end

		local Folder = Instance.new("Folder")
		Folder.Name = name
		Folder.Parent = parent

		return Folder
	end
	return nil
end

function createUtil:CreateExplosion(properties, Delay)
	local Explosion = Instance.new("Explosion")
	Explosion.Position = properties["Position"]
	Explosion.DestroyJointRadiusPercent = 0
	Explosion.BlastRadius = properties["BlastRadius"]
	Explosion.BlastPressure = 0
	Explosion.Parent = Workspace

	Explosion.Hit:Connect(function(HitPart)
		local character = HitPart.Parent
		local human = character:FindFirstChild("Humanoid")
		if human and HitPart.Name == "HumanoidRootPart" then -- If it finds both Humanoid and the Root part
			local player = Players:GetPlayerFromCharacter(character)

			local applyForce = (
				(human.RootPart.Position + Vector3.new(0, properties["ForceHeight"], 0)) - Explosion.Position
			).Unit * properties["Force"]
			ReplicatedStorage.Events.RagdollState:FireClient(player, applyForce, nil, Delay)
		end
	end)
end

return createUtil
