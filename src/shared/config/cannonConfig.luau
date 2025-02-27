local function cost(l1, l2)
	local la = l1 - l2
	local m = math.floor(la / 5) * 5
	return math.round(math.pow(m, 1.2)) + 100
end

local function power(playerLevel)
	return math.log(1 + 190 * (playerLevel + 1), 1.01) * 50 - 26000
end

local module = {
	cannonFirePeriod = 1,
	cannonAngle = 45,
	costFormula = function(level, boughtLevels)
		return cost(level, boughtLevels)
	end,
	maxDistance = 55000,
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
	rewardFormula = function(distance)
		return math.log(0.6 * distance, 1.1) * 100 + 1000
	end,
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
	return math.log(1 + 190 * (playerLevel + 1), 1.01) * 50 - 26000
end

return module
