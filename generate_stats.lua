--[[
	Generates cannon stats (cost per launch) for levels 1-100
	and floor upgrade costs for levels up to 1000 (in intervals of 50).
	Output is generated as a single string.

	Uses the latest formulas from cannonConfig.luau and floorConfig.luau.
	Requires these files to be present in the expected location
	(e.g., src/shared/config/).
]]

-- =============================================================================
-- Configuration Requirements
-- =============================================================================

-- Assuming this script is run from the workspace root 'cannon'
local cannonConfig = require(game.ReplicatedStorage.shared.config.cannonConfig)
local floorConfig = require(game.ReplicatedStorage.shared.config.floorConfig)

-- =============================================================================
-- Helper Functions (Replicated from latest cannonConfig)
-- =============================================================================

-- =============================================================================
-- Calculation and Building Output String
-- =============================================================================

local outputLines = {} -- Table to hold each line of the output

table.insert(outputLines, "--- Cannon Stats (Level 1-100) ---")
table.insert(outputLines, string.format("%-5s | %-15s | %-18s", "Level", "Upgrade Cost", "Required Launches"))
table.insert(outputLines, string.rep("-", 5 + 3 + 15 + 3 + 18)) -- Adjusted separator length

for level = 1, 100 do
	-- Upgrade cost is cost from level-1 to level (using latest cannonConfig.costFormula)
	local upgradeCost = cannonConfig.costFormula(level + 1, 0)
	-- Required launches uses the locally replicated latest function
	local requiredLaunches = cannonConfig.calculateRequiredLaunches(level)
	-- Total cost is cost from 0 to level (using latest cannonConfig.costFormula)
	-- local totalCostToLevel = cannonConfig.costFormula(level + 1, 0) -- Removed total cost calculation as it's no longer needed
	-- local costPerLaunch = 0 -- Removed costPerLaunch calculation
	-- if requiredLaunches > 0 then
	-- 	costPerLaunch = tonumber(totalCostToLevel) / requiredLaunches
	-- end
	table.insert(
		outputLines,
		-- Format costs as integers for readability, launches potentially float
		string.format("%-5d | %-15.0f | %-18.1f", level, upgradeCost, requiredLaunches) -- Removed costPerLaunch from format
	)
end

table.insert(outputLines, "\n--- Floor Upgrade Costs (Intervals of 50 up to 1000) ---")
table.insert(outputLines, string.format("%-10s | %-15s", "Level Range", "Cost"))
table.insert(outputLines, string.rep("-", 10 + 3 + 15))

local previousIntervalLevel = 0
for level = 50, 1000, 50 do
	-- Cost calculation uses the latest floorConfig.costFormula.
	-- As before, this calculates the cost *to reach* 'level' from 0 based on the formula's logic.
	local costForLevel = floorConfig.costFormula(level, 0)
	table.insert(
		outputLines,
		string.format("%-10s | %-15.0f", tostring(previousIntervalLevel + 1) .. "-" .. tostring(level), costForLevel) -- Format as integer
	)
	previousIntervalLevel = level
end

table.insert(outputLines, "\nNotes:")
table.insert(
	outputLines,
	"- Calculations use the latest formulas from src/shared/config/cannonConfig.luau and src/shared/config/floorConfig.luau."
)
table.insert(outputLines, "- Cannon Upgrade Cost is cost from the previous level.")
table.insert(outputLines, "- Required Launches is the number needed based on the latest cannonConfig logic.")
-- Removed Cost Per Launch note
table.insert(
	outputLines,
	"- Floor Cost is the cost to upgrade *to* the end level of the range from level 0, using the latest floorConfig logic."
)

-- =============================================================================
-- Final Output
-- =============================================================================

-- Concatenate all lines into a single string with newline separators and print
print(table.concat(outputLines, "\n"))
