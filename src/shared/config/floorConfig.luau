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

local module = {
	costFormula = function(targetLevel, boughtLevels)
		local floorDelta = math.max(targetLevel - boughtLevels, 0)
		local floorBase = math.floor(floorDelta / 5) * 5
		local totalCost = 500 * (floorBase + 1) + math.pow(1.04, math.floor(floorBase / 10))

		return totalCost
	end,
}

return module
