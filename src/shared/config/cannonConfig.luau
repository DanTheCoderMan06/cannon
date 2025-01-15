local function cost(l1, l2)
	local la = l1 - l2
	local m = math.floor(la / 5) * 5
	return math.round(math.pow(m, 1.2)) + 100
end
local module = {
	cannonFirePeriod = 1,
	cannonAngle = 45,
	costFormula = function(level, boughtLevels)
		return cost(level, boughtLevels)
	end,
	maxDistance = 50000,
	cannons = {
		["cannon1"] = {
			["max"] = 4,
			["min"] = 0,
		},
		["cannon10"] = {
			["max"] = 40,
			["min"] = 37,
		},
		["cannon11"] = {
			["max"] = 44,
			["min"] = 41,
		},
		["cannon12"] = {
			["max"] = 48,
			["min"] = 45,
		},
		["cannon13"] = {
			["max"] = 52,
			["min"] = 49,
		},
		["cannon14"] = {
			["max"] = 56,
			["min"] = 53,
		},
		["cannon15"] = {
			["max"] = 60,
			["min"] = 57,
		},
		["cannon16"] = {
			["max"] = 64,
			["min"] = 61,
		},
		["cannon17"] = {
			["max"] = 68,
			["min"] = 65,
		},
		["cannon18"] = {
			["max"] = 72,
			["min"] = 69,
		},
		["cannon19"] = {
			["max"] = 76,
			["min"] = 73,
		},
		["cannon2"] = {
			["max"] = 8,
			["min"] = 5,
		},
		["cannon20"] = {
			["max"] = 80,
			["min"] = 77,
		},
		["cannon21"] = {
			["max"] = 84,
			["min"] = 81,
		},
		["cannon22"] = {
			["max"] = 88,
			["min"] = 85,
		},
		["cannon23"] = {
			["max"] = 92,
			["min"] = 89,
		},
		["cannon24"] = {
			["max"] = 96,
			["min"] = 93,
		},
		["cannon25"] = {
			["max"] = 100,
			["min"] = 97,
		},
		["cannon26"] = {
			["max"] = 104,
			["min"] = 101,
		},
		["cannon27"] = {
			["max"] = 108,
			["min"] = 105,
		},
		["cannon28"] = {
			["max"] = 112,
			["min"] = 109,
		},
		["cannon29"] = {
			["max"] = 116,
			["min"] = 113,
		},
		["cannon3"] = {
			["max"] = 12,
			["min"] = 9,
		},
		["cannon30"] = {
			["max"] = 120,
			["min"] = 117,
		},
		["cannon31"] = {
			["max"] = 124,
			["min"] = 121,
		},
		["cannon32"] = {
			["max"] = 128,
			["min"] = 125,
		},
		["cannon33"] = {
			["max"] = 132,
			["min"] = 129,
		},
		["cannon34"] = {
			["max"] = 136,
			["min"] = 133,
		},
		["cannon35"] = {
			["max"] = 140,
			["min"] = 137,
		},
		["cannon36"] = {
			["max"] = 144,
			["min"] = 141,
		},
		["cannon37"] = {
			["max"] = 148,
			["min"] = 145,
		},
		["cannon38"] = {
			["max"] = 152,
			["min"] = 149,
		},
		["cannon39"] = {
			["max"] = 156,
			["min"] = 153,
		},
		["cannon4"] = {
			["max"] = 16,
			["min"] = 13,
		},
		["cannon40"] = {
			["max"] = 160,
			["min"] = 157,
		},
		["cannon41"] = {
			["max"] = 164,
			["min"] = 161,
		},
		["cannon42"] = {
			["max"] = 168,
			["min"] = 165,
		},
		["cannon43"] = {
			["max"] = 172,
			["min"] = 169,
		},
		["cannon44"] = {
			["max"] = 176,
			["min"] = 173,
		},
		["cannon45"] = {
			["max"] = 180,
			["min"] = 177,
		},
		["cannon46"] = {
			["max"] = 184,
			["min"] = 181,
		},
		["cannon47"] = {
			["max"] = 188,
			["min"] = 185,
		},
		["cannon48"] = {
			["max"] = 192,
			["min"] = 189,
		},
		["cannon49"] = {
			["max"] = 196,
			["min"] = 193,
		},
		["cannon5"] = {
			["max"] = 20,
			["min"] = 17,
		},
		["cannon50"] = {
			["max"] = 200,
			["min"] = 197,
		},
		["cannon51"] = {
			["max"] = 204,
			["min"] = 201,
		},
		["cannon6"] = {
			["max"] = 24,
			["min"] = 21,
		},
		["cannon7"] = {
			["max"] = 28,
			["min"] = 25,
		},
		["cannon8"] = {
			["max"] = 32,
			["min"] = 29,
		},
		["cannon9"] = {
			["max"] = 36,
			["min"] = 33,
		},
	},
	rewardFormula = function(distance)
		return 2 * math.pow(distance, 0.8)
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
	return math.pow(playerLevel, 1.3) * 10
end

return module
