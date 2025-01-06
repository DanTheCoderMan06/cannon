local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local zap = require(ReplicatedStorage.zap)

local PhysicsModule = {}

function PhysicsModule:OnApplyForce(part, velocity, rotvelocity, position)
	assert(typeof(part) == "Instance" and part:IsA("BasePart"), "not a part")

	if part.Anchored or (part:IsGrounded()) then
		return
	end

	velocity = typeof(velocity) == "Vector3" and velocity or Vector3.new()
	rotvelocity = typeof(rotvelocity) == "Vector3" and rotvelocity or Vector3.new()
	position = typeof(position) == "Vector3" and position or Vector3.new()

	local pos = part.Position + position
	part:ApplyImpulseAtPosition(velocity / 10, pos)
	part:ApplyAngularImpulse(rotvelocity / 10)
end

function PhysicsModule:ApplyForce(part, velocity, rotvelocity, position)
	assert(typeof(part) == "Instance" and part:IsA("BasePart"), "not a part")

	if (part:IsDescendantOf(Workspace)) and not part.Anchored and (not part:IsGrounded()) then
		if RunService:IsServer() then
			local NetworkOwner = part:GetNetworkOwner()
			if NetworkOwner then
				zap.applyForceLocally.Fire(
					NetworkOwner,
					{ part = part, velocity = velocity, rotVelocity = rotvelocity, position = position }
				)
			else
				PhysicsModule:OnApplyForce(part, velocity, rotvelocity, position)
			end
		else
			PhysicsModule:OnApplyForce(part, velocity, rotvelocity, position)
		end
	end
end

return PhysicsModule
