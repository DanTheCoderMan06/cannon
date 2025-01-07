local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sharedModules = ReplicatedStorage.sharedPackages
local shared = ReplicatedStorage.shared

local Trove = require(sharedModules.Trove)

local globalConfig = require(shared.config.cannonConfig)

local explosionUtil = require(shared.utilities.explosionUtil)

local Cannon = {}
Cannon.__index = Cannon

function Cannon.new(args)
	local self = setmetatable({}, Cannon)

	self.owner = args.owner
	self.model = args.model

	self.Trove = Trove.new()

	self.cannonModel = ReplicatedStorage.assets.cannons:FindFirstChild(self.model):Clone()
	self.cannonModel.Parent = workspace.playerCannons

	self.busy = false

	self.enabled = true

	task.spawn(function()
		while self.enabled do
			task.wait(0.5)
			self.character = self.owner.Character
			if self.character then
				if not self.character.PrimaryPart then
					continue
				end
				if
					(self.character.PrimaryPart.Position - self.cannonModel.center.characterPosition.WorldPosition).Magnitude
						< globalConfig.triggerRadius
					and not self.busy
				then
					self:useCannon()
				end
			end
		end
	end)

	return self
end

function Cannon:useCannon()
	self.owner:SetAttribute("inCannon", true)
	self.busy = true
	self.character = self.owner.Character
	self:positionCharacter()
	self:fireCannon()
	task.delay(3, function()
		self.busy = false
	end)
end

function Cannon:positionCharacter()
	if not self.character then
		return
	end
	self.character.PrimaryPart.Anchored = true
	self.character.PrimaryPart.CFrame = CFrame.new(
		self.cannonModel.center.characterPosition.WorldPosition,
		self.cannonModel.center.characterDirection.WorldPosition
	) * CFrame.new(0, math.rad(-90), 0)
end

function Cannon:fireCannon()
	task.wait(globalConfig.cannonFirePeriod)
	self.owner:SetAttribute("inCannon", false)
	if not self.character then
		return
	end
	self.character.PrimaryPart.Anchored = false
	explosionUtil:CreateExplosion(
		self.cannonModel.center.fireDirection.WorldPosition,
		20,
		5000,
		1,
		4,
		false,
		true,
		self.character
	)
end

function Cannon:destroy()
	self.enabled = false
	self.Trove:Destroy()
end

return Cannon
