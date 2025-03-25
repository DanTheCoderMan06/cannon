local function cost(level, boughtLevels)
    -- Ensure we're working with a valid level difference
    local levelDiff = math.max(0, level - boughtLevels)
    
    -- Base cost with more reasonable scaling
    local baseValue = 100 + (levelDiff * 50)
    
    -- Control the exponential growth with a much gentler curve
    -- Starting with linear growth, transitioning to gentle logarithmic
    if level <= 5 then
        -- Very early game - 4x more expensive than before
        return math.round(baseValue * level * 1.2 * 4) + 1000  -- 4x multiplier and increased base
    elseif level <= 10 then
        -- Early game - 4x more expensive
        return math.round(baseValue * level * 1.5 * 4) + 2000  -- 4x multiplier and increased base
    elseif level <= 30 then
        -- Mid game - 10x more expensive to reach ~20M at level 20
        local scaleFactor = 1 + (level * 0.03)
        return math.round(baseValue * math.pow(level, scaleFactor) * 10) + 10000  -- 10x multiplier and increased base
    else
        -- Late game - logarithmic dampening but with higher base to maintain progression
        local logScale = math.log10(level)
        local expScale = math.exp((level - 20) * 0.4 + 1)  -- Keeping your exponential scaling
        -- Combined approach with 10x scaling
        return math.round((baseValue * level * level * logScale * 10) / 2) + 50000  -- 10x multiplier and increased base
    end
end

local function rewardFormula(distance)
    -- Further reduced base reward (40x less than original version)
    local baseReward = 37  -- Reduced by 4x from 150
    
    -- Thresholds for scaling transitions
    local midThreshold = 100000
    local lateThreshold = 500000
    
    -- Early to mid game rewards (reduced by ~40x from original version)
    if distance <= midThreshold then
        -- Further scaled-down values for early game
        local distanceScale = distance * 0.037  -- Reduced by 4x from 0.15
        local logarithmicComponent = math.log(distanceScale + 100, 1.08) * 12.5  -- Reduced by 4x from 50
        local linearComponent = distance * 0.0125  -- Reduced by 4x from 0.05
        
        return math.round(baseReward + logarithmicComponent + linearComponent)
    
    -- Late mid-game (transitional scaling)
    elseif distance <= lateThreshold then
        -- Get the reward at threshold point
        local midReward = baseReward + 
                         (math.log(midThreshold * 0.15 + 100, 1.08) * 50) + 
                         (midThreshold * 0.05)
        
        -- Additional distance beyond threshold
        local excessDistance = distance - midThreshold
        
        -- More aggressive scaling for this range with polynomial growth
        local bonusFactor = math.pow(excessDistance, 1.1) / 1000 + excessDistance * 0.1
        
        return math.round(midReward + bonusFactor)
    
    -- Late game rewards (significantly increased - ~2x+ previous version)
    else
        -- Calculate the reward at late threshold point for continuity
        local midReward = baseReward + 
                         (math.log(midThreshold * 0.15 + 100, 1.08) * 50) + 
                         (midThreshold * 0.05)
                         
        local lateThresholdExcess = lateThreshold - midThreshold
        local lateMidReward = midReward + 
                             (math.pow(lateThresholdExcess, 1.1) / 1000 + 
                              lateThresholdExcess * 0.1)
        
        -- Additional distance beyond late threshold
        local ultraLateExcess = distance - lateThreshold
        
        -- Much more aggressive scaling with combined approaches for late game:
        -- 1. Strong polynomial component (grows faster than linear)
        -- 2. Square root component for large numbers
        -- 3. Logarithmic boost to ensure meaningful jumps
        local ultraLateBonus = 
            (math.pow(ultraLateExcess, 1.2) / 500) +  -- Stronger polynomial growth
            (math.sqrt(ultraLateExcess) * 30) +       -- Square root scaling
            (math.log(ultraLateExcess + 1000, 1.5) * 2000)  -- Logarithmic component
        
        return math.round(lateMidReward + ultraLateBonus)
    end
end

local function power(playerLevel)
	return math.log(1 + 25 * (playerLevel + 1), 1.01) * 40 - 12000
end

local module = {
	cannonFirePeriod = 1,
	cannonAngle = 45,
	costFormula = function(level, boughtLevels)
		return cost(level, boughtLevels)
	end,
	maxLevel = 100,
	maxDistance = 20000,
	premiumMultiplier = 1.5,
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
	rewardFormula = rewardFormula
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
	return power(playerLevel)
end

return module
