local RNG = Random.new(tick())

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForceModule = require(ReplicatedStorage.shared.utilities.forceUtil)
local zap = require(ServerStorage.zap)
local Admins = {}

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

local module = {}

function module:CreateExplosion(
	position,
	radius,
	force,
	forceheight,
	Delay,
	explodeToPieces,
	exclusive,
	targetCharacter
)
	local Explosion = Instance.new("Explosion")
	Explosion.Position = position
	Explosion.BlastRadius = radius
	Explosion.BlastPressure = 0
	Explosion.DestroyJointRadiusPercent = 0

	Explosion.Parent = game.Workspace

	local playersHit = {}

	Explosion.Hit:Connect(function(HitPart)
		local character = HitPart.Parent
		if exclusive then
			if character ~= targetCharacter then
				return
			end
		end
		local human = character:FindFirstChild("Humanoid")
		if explodeToPieces == true then
			if character and human then
				local player = game.Players:GetPlayerFromCharacter(character)
				if player and not playersHit[player.Name] then
					playersHit[player.Name] = true

					local rng = RNG:NextNumber()

					if human.Health > 0 then
						human.Health = 0
					end

					for _, v in pairs(character:GetChildren()) do
						if v:IsA("Constraint") then
							if rng > 0.1 then
								v:Destroy()
							end
						elseif v:IsA("BasePart") then
							local force =
								Vector3.new(RNG:NextNumber(-10, 10), 1000 * v:GetMass(), RNG:NextNumber(-10, 10))
							ForceModule:ApplyForce(v, force)
						end
					end
				end
			else
				HitPart:BreakJoints()
				if not HitPart.Anchored then
					local force = ((HitPart.Position + Vector3.new(
						RNG:NextNumber(-20, 20),
						forceheight + 10,
						RNG:NextNumber(-20, 20)
					)) - Explosion.Position).Unit * force * HitPart:GetMass()
					ForceModule:ApplyForce(HitPart, force)
				end
			end
		else
			if human and HitPart.Name == "HumanoidRootPart" then -- If it finds both Humanoid and the Root part
				local player = game.Players:GetPlayerFromCharacter(character)
				if player then
					if not Admins[player.UserId] then
						local root = character:WaitForChild("HumanoidRootPart")

						local applyForce = ((root.Position + Vector3.new(0, forceheight, 0)) - Explosion.Position).Unit
							* force
						zap.replicateRagdollState.Fire(player, { force = applyForce, delay = Delay })
					end
				else
					local mass = GetMassOfModel(character)
					local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
					if root then
						local applyForce = ((root.Position + Vector3.new(0, forceheight, 0)) - Explosion.Position).Unit
							* (force * 0.75)
							* mass

						ForceModule:ApplyForce(HitPart, applyForce)
					end
				end
			end
		end
	end)
end

return module
