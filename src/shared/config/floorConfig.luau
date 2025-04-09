local TRANSITION_LEVEL = 60
local EXP_BASE = 5000
local EXP_RATE = 1.05
local LOG_SCALE = 200000

-- Calculate the base level for the group containing the transition level
local TRANSITION_GROUP_BASE_LEVEL = TRANSITION_LEVEL - (TRANSITION_LEVEL - 1) % 5

-- Calculate the cost at the start of the logarithmic phase for smooth transition
local COST_AT_TRANSITION_BASE = EXP_BASE * math.pow(EXP_RATE, TRANSITION_GROUP_BASE_LEVEL / 5)

local function get_cost_for_base_level(baseLevel)
	local cost
	if baseLevel < TRANSITION_LEVEL then
		-- Exponential growth before transition
		cost = EXP_BASE * math.pow(EXP_RATE, baseLevel / 5)
	else
		-- Logarithmic growth after transition
		-- Calculate how many 5-level steps past the transition base level we are
		local steps_past_transition = (baseLevel - TRANSITION_GROUP_BASE_LEVEL) / 5
		cost = COST_AT_TRANSITION_BASE + LOG_SCALE * math.log10(steps_past_transition + 1)
	end
	return math.round(math.max(0, cost))
end

local module = {
	costFormula = function(targetLevel, boughtLevels)
		if targetLevel <= boughtLevels then
			return 0
		end

		local totalCost = 0
		for currentLevel = boughtLevels + 1, targetLevel do
			-- Determine the base level for the 5-level group this level belongs to
			local levelGroup = math.floor((currentLevel - 1) / 5)
			local baseLevelForGroup = levelGroup * 5 + 1

			-- Get the cost associated with this group's base level
			local levelCost = get_cost_for_base_level(baseLevelForGroup)
			totalCost = totalCost + levelCost
		end

		return math.min(totalCost, 100000000) -- Clamp final total cost at 100 million
	end,
}

return module
