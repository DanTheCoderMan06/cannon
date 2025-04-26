-- Replicated functions from cannonConfig.luau

local function power(x)
	local x1 = math.clamp(x, 0, 30)
	local x2 = 0
	if x1 < x then
		x2 = x - x1
	end
	return math.pow(1.1, x1) * 450 + math.log(x2 + 1, 3) * 130
end

local function cost(targetLevel, boughtLevels)
	local bl = boughtLevels or 0
	if targetLevel <= bl then
		return 0
	end

	local delta = targetLevel - bl

	-- Simplified cost for single level upgrade (delta = 1)
	if delta == 1 then
		-- Need to infer single-level cost logic based on the multi-level formula.
		-- Let's adapt the formula for delta=1, using the logic for small deltas.
		-- The original formula seems complex for multi-level jumps.
		-- We'll use a simplified approach based on the structure for delta > 2.
		-- This might need refinement based on the exact intended single-level cost.

		-- Approximation based on the formula's structure for small increases:
		-- Using the structure for clampedDelta = 0 (since delta=1 -> clampedDelta=0)
		-- cost = 20000 * math.pow(1.1, 0 - 2) + 15000 * (1 - 2) -- This doesn't seem right.

		-- Let's try applying the logic more directly for targetLevel:
		local levelCost
		if targetLevel > 45 then
			-- Apply scaling based on the > 45 logic, but for a single level jump
			local baseCostAt45 = 150000 * math.pow(1.1, 45) + 15000 * 45 - 5
			levelCost = baseCostAt45 * math.log(math.exp(1) + (targetLevel - 45) / 2)
				- (baseCostAt45 * math.log(math.exp(1) + (targetLevel - 1 - 45) / 2)) -- Approx difference
			-- This difference calculation is complex. Let's use a simpler exponential growth based on the patterns.
			levelCost = (150000 * math.pow(1.1, 45)) * math.pow(1.05, targetLevel - 45) -- Simplified exponential increase past 45
		elseif targetLevel > 6 then
			-- Cost increases based on 1.1^level factor
			levelCost = 150000 * math.pow(1.1, targetLevel) + 15000 -- Simplified from the delta formula
		elseif targetLevel > 2 then
			-- Cost increases based on 1.1^(level-2) factor
			levelCost = 20000 * math.pow(1.1, targetLevel - 2) + 15000 -- Simplified from the delta formula
		else -- Level 1 or 2
			levelCost = 500 -- From the delta <= 2 case
		end
		return math.max(500, math.floor(levelCost)) -- Ensure minimum cost and integer value
	else
		-- Fallback for multi-level cost calculation (original function)
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
		return math.floor(calculated_cost)
	end
end

local function calculateDistance(initialHeight, initialVelocity, angleDegrees)
	local angleRadians = math.rad(angleDegrees)
	local gravity = 196.2 -- Default Roblox gravity
	local horizontalVelocity = math.cos(angleRadians) * initialVelocity
	local verticalVelocity = math.sin(angleRadians) * initialVelocity
	-- Using the formula term initialHeight * 5 directly as seen in the config
	local effectiveHeightTerm = initialHeight * 5
	local timeElapsed = (
		verticalVelocity + math.sqrt(math.pow(verticalVelocity, 2) + 2 * gravity * effectiveHeightTerm)
	) / gravity
	local horizontalDistanceTraveled = timeElapsed * horizontalVelocity
	return horizontalDistanceTraveled
end

-- Constants
local MAX_LEVEL = 100
local INITIAL_HEIGHT = 10 -- Assumed initial height in studs
local CANNON_ANGLE = 45 -- From config

-- Calculate and print stats for each level
print("Level | Cost to Upgrade | Est. Distance")
print("------|-----------------|--------------")

local cumulativeCost = 0

for level = 1, MAX_LEVEL do
	local upgradeCost = cost(level, level - 1)
	cumulativeCost = cumulativeCost + upgradeCost

	local cannonPower = power(level)
	local distance = calculateDistance(INITIAL_HEIGHT, cannonPower, CANNON_ANGLE)

	print(string.format("%-5d | %-15d | %.2f", level, upgradeCost, distance))
end

print("\nNote: Cost is calculated for upgrading from the previous level.")
print(
	string.format(
		"Note: Distance calculated with initialHeight=%d, angle=%d, gravity=%.1f",
		INITIAL_HEIGHT,
		CANNON_ANGLE,
		196.2
	)
)
