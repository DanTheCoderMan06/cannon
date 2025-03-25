local function cost(l1, l2)
    local la = math.clamp(l1 - l2, 0, 10000000)
    
    local baseValue = 200 + (la * 20)
    
    local logScale = math.log10(l1 + 10)
    
    local exponent = 1 + (logScale * 0.01)
    
    local scaledCost
    if l1 < 100 then
        scaledCost = baseValue * math.pow(l1, 1.1)
    elseif l1 < 1000 then
        scaledCost = baseValue * math.pow(l1, exponent)
    else
        scaledCost = baseValue * l1 * logScale * 2
    end
    
    return math.round(scaledCost + 50)
end

local module = {
	costFormula = function(level, boughtLevels)
		return cost(level, boughtLevels)
	end,
}

return module
