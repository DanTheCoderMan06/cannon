-- New logarithmic power formula
--[[
local function power(x)
	return math.max(0, 10000 * math.log10(x + 9) - 9374)
end
--]]

local function power(x)
	local x1 = math.clamp(x, 0, 30)
	local x2 = 0
	if x1 < x then
		x2 = x - x1
	end
	return math.pow(1.1, x1) * 450 + math.log(x2 + 1, 3) * 900
end

-- Original reward formula based on distance (x)
local function rewardFormula(x, floors)
	floors = floors or 0
	local result = x
	return math.max(0, result)
end

local function calculateDistance(initialHeight, initialVelocity, angleDegrees)
	local angleRadians = math.rad(angleDegrees)
	local gravity = workspace.Gravity
	local horizontalVelocity = math.cos(angleRadians) * initialVelocity
	local verticalVelocity = math.sin(angleRadians) * initialVelocity
	local timeElapsed = (
		verticalVelocity + math.sqrt(math.pow(verticalVelocity, 2) + 2 * gravity * (initialHeight * 5))
	) / gravity
	local horizontalDistanceTraveled = timeElapsed * horizontalVelocity
	return horizontalDistanceTraveled
end

local function cost(targetLevel, boughtLevels)
	local bl = boughtLevels or 0
	if targetLevel <= bl then
		return 0
	end

	if targetLevel == 1 then
		return 4000
	end

	local delta = targetLevel - bl

	local cost = 4000 * math.pow(1.12, delta) + 8000 * delta

	return cost
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
	-- Export the original reward formula
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
