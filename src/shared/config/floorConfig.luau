local function cost(l1, l2)
    local la = math.clamp(l1 - l2, 0, 10000000)
    
    -- Base cost that grows more slowly
    local baseValue = 20 + (la * 2)
    
    -- Logarithmic scaling to prevent excessive growth
    local logScale = math.log10(l1 + 10)
    
    -- Controlled exponential growth
    local exponent = 1.05 + (logScale * 0.03)
    
    -- Apply piecewise scaling for different ranges
    local scaledCost
    if l1 < 100 then
        -- Early game (gentle curve)
        scaledCost = baseValue * math.pow(l1, 1.1)
    elseif l1 < 1000 then
        -- Mid game (moderate scaling)
        scaledCost = baseValue * math.pow(l1, exponent)
    else
        -- Late game (logarithmic dominance to prevent astronomical costs)
        scaledCost = baseValue * l1 * logScale * 2
    end
    
    -- Add minimum cost buffer and round
    return math.round(scaledCost + 50)
end

local module = {
	costFormula = function(level, boughtLevels)
		return cost(level, boughtLevels)
	end,
}

return module
