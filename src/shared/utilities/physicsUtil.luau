local ReplicatedStorage = game:GetService("ReplicatedStorage")
local physicsUtil = {}
local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)

-- We calculate T, Distance, etc through the big 5 (phyiscs)

function physicsUtil.getVariables(initialHeight, initialVelocity)
	print(initialHeight)
	local horizontalVelocity = math.cos(math.rad(cannonConfig.cannonAngle)) * initialVelocity
	local verticalVelocity = math.sin(math.rad(cannonConfig.cannonAngle)) * initialVelocity
	local timeElapsed = (
		verticalVelocity + math.sqrt(math.pow(verticalVelocity, 2) + 2 * workspace.Gravity * initialHeight)
	) / workspace.Gravity
	local horizontalDistanceTraveled = timeElapsed * horizontalVelocity

	return {
		height = initialHeight,
		velocity = initialVelocity,
		horizontalVelocity = horizontalVelocity,
		verticalVelocity = verticalVelocity,
		distance = horizontalDistanceTraveled,
		time = timeElapsed,
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
