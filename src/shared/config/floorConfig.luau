local function cost(l1, l2)
	local la = l1 - l2
	local m = math.floor(la / 5) * 5
	return math.round(math.pow(m, 1.2)) + 100
end
local module = {
	costFormula = function(level, boughtLevels)
		return cost(level, boughtLevels)
	end,
}

return module
