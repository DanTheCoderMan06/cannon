local function cost(l1, l2)
	local la = l1 - l2
	local m = math.floor(la / 5) * 5
	return math.round(math.pow(m, 1.2))
end
local module = {
	cannonFirePeriod = 1,
	triggerRadius = 20,
	costFormula = function(level, boughtLevels)
		return cost(level, boughtLevels)
	end,
	cannons = {
		cannon1 = {
			min = 0,
			max = 4,
		},
	},
}

function module.getCannon(playerLevel)
	for cannonName, cannonInfo in pairs(module.cannons) do
		if playerLevel >= cannonInfo.min and playerLevel <= cannonInfo.max then
			return cannonName
		end
	end
end

function module.getPower(level)
	return 4
end

return module
