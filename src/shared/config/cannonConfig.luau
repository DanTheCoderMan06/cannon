-- New logarithmic power formula
--[[
local function power(x)
	return math.max(0, 10000 * math.log10(x + 9) - 9374)
end
--]]

local function requiredLaunches(x)
	return 0.5 + x * 2
end

local function cost(targetLevel, boughtLevels)
	if targetLevel == 2 then
		return 500
	end

	local bl = boughtLevels or 0
	if targetLevel <= bl then
		return 0
	end

	local delta = targetLevel - bl

	local clampedDelta = math.floor(delta / 2) * 2
	local calculated_cost
	if clampedDelta > 45 then
		calculated_cost = 150000 * math.pow(1.1, 45) + 15000 * 45 - 5
		calculated_cost *= math.log(math.exp(1) + (delta - 45) / 2)
	elseif clampedDelta > 6 then
		calculated_cost = 150000 * math.pow(1.1, clampedDelta) + 15000 * delta - 5
	else
		calculated_cost = 20000 * math.pow(1.1, clampedDelta - 2) + 15000 * (delta - 2)
	end
	-- Ensure minimum cost and integer value
	return math.max(500, math.floor(calculated_cost))
end

local gravity = workspace.Gravity
local initialHeight = 220
local launchAngleRadians = math.rad(45)
local cosAngle = math.cos(launchAngleRadians)
local sinAngle = math.sin(launchAngleRadians)

function transformMoney(horizontalDistanceTraveled)
	local denominator = initialHeight + horizontalDistanceTraveled

	local velocitySquared = (gravity * math.pow(horizontalDistanceTraveled, 2)) / denominator

	local initialVelocity = math.sqrt(velocitySquared)

	return initialVelocity
end

local function power(x)
	local launches = requiredLaunches(x)
	local rewardTotal = cost(x + 1, 0) / launches
	local moneyToPower = transformMoney(rewardTotal)
	print(moneyToPower)
	return math.max(500, moneyToPower)
end

-- Original reward formula based on distance (x)
local function rewardFormula(x, floors)
	floors = floors or 0
	local result = x
	return math.max(0, result)
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
			power = 9000,
		},
		["railgun"] = {
			power = 12000,
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
