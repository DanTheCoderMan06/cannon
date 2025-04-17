--[[
local TRANSITION_LEVEL = 1000 -- Level at which the formula transitions
local EXP_BASE = 50 -- Starting cost for the exponential phase
local EXP_RATE = 1.05 -- Rate of exponential increase
local LOG_SCALE = 280000 -- Scaling factor for the logarithmic phase
--]]

local TRANSITION_LEVEL = 600
local EXP_BASE = 500
local EXP_RATE = 1.06
local LOG_SCALE = 280000

local TRANSITION_GROUP_BASE_LEVEL = math.floor((TRANSITION_LEVEL - 1) / 5) * 5 + 1

local COST_AT_TRANSITION_BASE = EXP_BASE * math.pow(EXP_RATE, (TRANSITION_GROUP_BASE_LEVEL - 1) / 5)

--[[
local function get_cost_for_base_level(baseLevel)
	local cost
	if baseLevel < TRANSITION_GROUP_BASE_LEVEL then
		cost = EXP_BASE * math.pow(EXP_RATE, (baseLevel - 1) / 5)
	else
		local steps_past_transition = (baseLevel - TRANSITION_GROUP_BASE_LEVEL) / 5
		cost = COST_AT_TRANSITION_BASE + LOG_SCALE * math.log10(steps_past_transition + 1)
	end
	return math.round(math.max(0, cost))
end
--]]

local function get_cost_for_base_level(baseLevel)
	local cost = baseLevel * 155
	return cost
end

local module = {
	costFormula = function(targetLevel, boughtLevels)
		if targetLevel <= boughtLevels then
			return 0
		end

		local totalCost = 0
		for currentLevel = boughtLevels + 1, targetLevel do
			local levelGroup = math.ceil((currentLevel - 1) / 5)
			local baseLevelForGroup = levelGroup * 5 + 1

			local levelCost = get_cost_for_base_level(baseLevelForGroup)
			totalCost = totalCost + levelCost
		end

		return totalCost
	end,
}

return module
