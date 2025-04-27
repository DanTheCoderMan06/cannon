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

local MAX_FLOORS = 0

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

local cannonConfig = require(script.Parent.cannonConfig)

local function getValue(level)
	if level >= 90 then
		return 40
	elseif level >= 70 then
		return 20
	elseif level >= 40 then
		return 10
	elseif level >= 20 then
		return 8
	elseif level >= 10 then
		return 6
	else
		return 5
	end
end

--Calculate Integral
local totalSum = 0
for i = 0, 101 do
	totalSum = totalSum + getValue(i)
end
MAX_FLOORS = totalSum
--

local function getApproxCannonLevelFromFloors(targetTotalFloors)
	if targetTotalFloors <= 0 then
		return 0
	end

	local currentLevel = 0
	local cumulativeFloors = 0

	while cumulativeFloors < targetTotalFloors do
		currentLevel = currentLevel + 1
		local floorsAddedAtThisLevel = getValue(currentLevel)
		cumulativeFloors = cumulativeFloors + floorsAddedAtThisLevel

		if currentLevel >= 101 then
			return currentLevel
		end
	end

	return currentLevel
end

local function cost(targetLevel, boughtLevels)
	local floorDelta = math.max(targetLevel - boughtLevels, 0)
	local floorBase = math.ceil(floorDelta / 5) * 5
	if floorDelta <= 12 then
		return 500
	end
	local currentLevelApprox = getApproxCannonLevelFromFloors(floorBase) + 1
	local totalCost = cannonConfig.costFormula(currentLevelApprox + 1, 0) / getValue(currentLevelApprox)
	print(MAX_FLOORS)
	if floorBase >= MAX_FLOORS then
		totalCost *= math.pow(1.02, floorBase - MAX_FLOORS)
	end

	return math.max(500, totalCost)
end

local module = {
	costFormula = function(targetLevel, boughtLevels)
		return cost(targetLevel, boughtLevels)
	end,
}

return module
