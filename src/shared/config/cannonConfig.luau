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
	maxDistance = 2400,
	cannons = {
		cannon1 = {
			min = 0,
			max = 4,
		},
	},
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
	local isNextCannon = false
	for cannonName, cannonInfo in pairs(module.cannons) do
		if isNextCannon then
			return cannonName
		end
		if playerLevel <= cannonInfo.max then
			isNextCannon = true
		end
	end
	return module.getCannon(playerLevel)
end

function module.getPower(playerLevel)
	return math.pow(1.5, playerLevel) * 100
end

return module
