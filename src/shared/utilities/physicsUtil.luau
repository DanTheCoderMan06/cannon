local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local physicsUtil = {}

function physicsUtil.getVariables(initialHeight, initialVelocity)
	print(initialHeight)
	local horizontalVelocity = math.cos(math.rad(45)) * initialVelocity
	local verticalVelocity = math.sin(math.rad(45)) * initialVelocity
	local timeElapsed = (
		verticalVelocity + math.sqrt(math.pow(verticalVelocity, 2) + 2 * workspace.Gravity * (initialHeight * 5))
	) / workspace.Gravity
	local horizontalDistanceTraveled = timeElapsed * horizontalVelocity

	return {
		height = initialHeight,
		velocity = initialVelocity,
		horizontalVelocity = horizontalVelocity,
		verticalVelocity = verticalVelocity,
		distance = horizontalDistanceTraveled,
		time = timeElapsed * 3,
		timeCreated = tick(),
	}
end

local function test(initialHeight, initialVelocity)
	local horizontalVelocity = math.cos(math.rad(cannonConfig.cannonAngle)) * initialVelocity
	local verticalVelocity = math.sin(math.rad(cannonConfig.cannonAngle)) * initialVelocity
	local timeElapsed = (
		initialVelocity + math.sqrt(math.pow(horizontalVelocity, 2) - 2 * -workspace.Gravity * initialHeight)
	) / -workspace.Gravity
	local horizontalDistanceTraveled = timeElapsed * horizontalVelocity

	return {
		distance = horizontalDistanceTraveled,
		time = timeElapsed,
	}
end

return physicsUtil
