local function power(x)
	local L = 15200
	local k = 0.068
	local x0 = 59.5
	return L / (1 + math.exp(-k * (x - x0))) + 200
end

local function rewardFormula(x, floors)
	floors = floors or 0
	local LOW_X = 966
	local MID_X = 128000
	local HIGH_X = 940000
	local SUPER_HIGH_X = 5000000

	local LOW_Y = 4000
	local MID_Y = 1000000
	local HIGH_Y = 4000000
	local SUPER_HIGH_Y = 20000000

	local result
	if x < LOW_X then
		result = LOW_Y
	elseif x < MID_X then
		local progress = (x - LOW_X) / (MID_X - LOW_X)
		local curve = progress * progress * (3 - 2 * progress)
		local linear = progress * 0.2
		result = LOW_Y + (curve * 0.8 + linear) * (MID_Y - LOW_Y)
	elseif x < HIGH_X then
		local progress = math.min(1, (x - MID_X) / (HIGH_X - MID_X))
		local curve = progress ^ 0.8 * (3 - 2 * progress ^ 0.8)
		local linear = progress * 0.3
		result = MID_Y + (curve * 0.7 + linear) * (HIGH_Y - MID_Y)
	elseif x < SUPER_HIGH_X then
		local progress = (x - HIGH_X) / (SUPER_HIGH_X - HIGH_X)
		local curve = progress ^ 0.7 * (3 - 2 * progress ^ 0.7)
		local linear = progress * 0.25
		result = HIGH_Y + (curve * 0.6 + linear) * (SUPER_HIGH_Y - HIGH_Y)
	else
		result = SUPER_HIGH_Y + math.log10(x / SUPER_HIGH_X + 1) * (SUPER_HIGH_Y * 0.5)
	end

	local floorMultiplier = 1 + (math.sqrt(math.max(1, floors)) * 0.2) -- Reduced multiplier from 0.3 to 0.2
	return math.max(0, result * floorMultiplier)
end

local function calculateDistance(initialHeight, initialVelocity, angleDegrees)
	local angleRadians = math.rad(angleDegrees)
	local gravity = workspace.Gravity
	local horizontalVelocity = math.cos(angleRadians) * initialVelocity
	local verticalVelocity = math.sin(angleRadians) * initialVelocity
	local timeElapsed = (
		verticalVelocity + math.sqrt(math.pow(verticalVelocity, 2) + 2 * gravity * (initialHeight * 5))
	) -- Increased impact of height
		/ gravity
	local horizontalDistanceTraveled = timeElapsed * horizontalVelocity
	return horizontalDistanceTraveled
end

local function cost(targetLevel, boughtLevels)
	if targetLevel <= boughtLevels then
		return 0
	end

	if targetLevel == 1 then
		return 100
	end

	local previousLevel = targetLevel - 1

	local powerPreviousLevel = power(previousLevel)

	local assumedHeight = 5
	local distancePreviousLevel = calculateDistance(assumedHeight, powerPreviousLevel, 45)

	local rewardPreviousLevel = rewardFormula(distancePreviousLevel, 0)

	local finalCost = math.round(rewardPreviousLevel * math.pow(1.075, targetLevel - boughtLevels) * 0.86)

	if targetLevel - boughtLevels > 50 then
		finalCost = math.round(finalCost * math.pow(1.02, 50 - targetLevel + boughtLevels))
	end

	return math.max(1, finalCost)
end

local module = {
	cannonFirePeriod = 1,
	cannonAngle = 45,
	costFormula = function(level, boughtLevels)
		return cost(level, boughtLevels)
	end,
	maxLevel = 100,
	maxDistance = 20000,
	premiumMultiplier = 1.5,
	specialCannons = {
		["artillery"] = {
			power = power(70),
		},
		["railgun"] = {
			power = power(140),
		},
		["circusCannon"] = {
			power = power(100),
		},
		armyCannon = {
			power = power(85),
		},
	},
	cannons = {
		["cannon1"] = {
			["max"] = 2,
			["min"] = 0,
		},
		["cannon10"] = {
			["max"] = 20,
			["min"] = 18,
		},
		["cannon11"] = {
			["max"] = 22,
			["min"] = 20,
		},
		["cannon12"] = {
			["max"] = 24,
			["min"] = 22,
		},
		["cannon13"] = {
			["max"] = 26,
			["min"] = 24,
		},
		["cannon14"] = {
			["max"] = 28,
			["min"] = 25,
		},
		["cannon15"] = {
			["max"] = 30,
			["min"] = 27,
		},
		["cannon16"] = {
			["max"] = 32,
			["min"] = 29,
		},
		["cannon17"] = {
			["max"] = 34,
			["min"] = 31,
		},
		["cannon18"] = {
			["max"] = 36,
			["min"] = 33,
		},
		["cannon19"] = {
			["max"] = 38,
			["min"] = 35,
		},
		["cannon2"] = {
			["max"] = 4,
			["min"] = 2,
		},
		["cannon20"] = {
			["max"] = 40,
			["min"] = 37,
		},
		["cannon21"] = {
			["max"] = 42,
			["min"] = 39,
		},
		["cannon22"] = {
			["max"] = 44,
			["min"] = 41,
		},
		["cannon23"] = {
			["max"] = 46,
			["min"] = 43,
		},
		["cannon24"] = {
			["max"] = 48,
			["min"] = 45,
		},
		["cannon25"] = {
			["max"] = 50,
			["min"] = 47,
		},
		["cannon26"] = {
			["max"] = 51,
			["min"] = 49,
		},
		["cannon27"] = {
			["max"] = 53,
			["min"] = 51,
		},
		["cannon28"] = {
			["max"] = 55,
			["min"] = 53,
		},
		["cannon29"] = {
			["max"] = 57,
			["min"] = 55,
		},
		["cannon3"] = {
			["max"] = 6,
			["min"] = 4,
		},
		["cannon30"] = {
			["max"] = 59,
			["min"] = 57,
		},
		["cannon31"] = {
			["max"] = 61,
			["min"] = 59,
		},
		["cannon32"] = {
			["max"] = 63,
			["min"] = 61,
		},
		["cannon33"] = {
			["max"] = 65,
			["min"] = 63,
		},
		["cannon34"] = {
			["max"] = 67,
			["min"] = 65,
		},
		["cannon35"] = {
			["max"] = 69,
			["min"] = 67,
		},
		["cannon36"] = {
			["max"] = 71,
			["min"] = 69,
		},
		["cannon37"] = {
			["max"] = 73,
			["min"] = 71,
		},
		["cannon38"] = {
			["max"] = 75,
			["min"] = 73,
		},
		["cannon39"] = {
			["max"] = 77,
			["min"] = 75,
		},
		["cannon4"] = {
			["max"] = 8,
			["min"] = 6,
		},
		["cannon40"] = {
			["max"] = 79,
			["min"] = 76,
		},
		["cannon41"] = {
			["max"] = 81,
			["min"] = 78,
		},
		["cannon42"] = {
			["max"] = 83,
			["min"] = 80,
		},
		["cannon43"] = {
			["max"] = 85,
			["min"] = 82,
		},
		["cannon44"] = {
			["max"] = 87,
			["min"] = 84,
		},
		["cannon45"] = {
			["max"] = 89,
			["min"] = 86,
		},
		["cannon46"] = {
			["max"] = 91,
			["min"] = 88,
		},
		["cannon47"] = {
			["max"] = 93,
			["min"] = 90,
		},
		["cannon48"] = {
			["max"] = 95,
			["min"] = 92,
		},
		["cannon49"] = {
			["max"] = 97,
			["min"] = 94,
		},
		["cannon5"] = {
			["max"] = 10,
			["min"] = 8,
		},
		["cannon50"] = {
			["max"] = 99,
			["min"] = 96,
		},
		["cannon51"] = {
			["max"] = 100,
			["min"] = 98,
		},
		["cannon6"] = {
			["max"] = 12,
			["min"] = 10,
		},
		["cannon7"] = {
			["max"] = 14,
			["min"] = 12,
		},
		["cannon8"] = {
			["max"] = 16,
			["min"] = 14,
		},
		["cannon9"] = {
			["max"] = 18,
			["min"] = 16,
		},
	},
	rewardFormula = rewardFormula,
}

function module.getCannon(playerLevel)
	local maxLevel = -1
	local targetCannon
	for cannonName, cannonInfo in pairs(module.cannons) do
		if cannonInfo.max > maxLevel then
			maxLevel = cannonInfo.max
			targetCannon = cannonName
		end
		if playerLevel >= cannonInfo.min and playerLevel <= cannonInfo.max then
			return cannonName
		end
	end
	return targetCannon
end

function module.getNextCannon(playerLevel)
	local currentCannon = module.getCannon(playerLevel)
	local targetMin = module.cannons[currentCannon].max + 1
	for cannonName, cannonInfo in pairs(module.cannons) do
		if targetMin == cannonInfo.min then
			return cannonName
		end
	end
	return currentCannon
end
function module.getPower(playerLevel)
	return power(playerLevel)
end

return module
