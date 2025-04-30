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
-- No helpers needed as we require the config directly

-- =============================================================================
-- Calculation and Building Output String
-- =============================================================================

local outputLines = {} -- Table to hold each line of the output

table.insert(outputLines, "--- Cannon Stats (Level 1-100) ---")
-- Add new columns: Actual Upgrade Cost, Avg Reward/Launch, Reward/TotalCost Ratio
local headerFormat = "%-5s | %-15s | %-18s | %-15s | %-18s | %-20s"
local separatorLength = 5 + 3 + 15 + 3 + 18 + 3 + 15 + 3 + 18 + 3 + 20
table.insert(
	outputLines,
	string.format(
		headerFormat,
		"Level",
		"TotalCostToLvl",
		"Required Launches",
		"ActualUpgrCost",
		"Power",
		"Reward/TotalCostRatio"
	)
)
table.insert(outputLines, string.rep("-", separatorLength))

for level = 1, 100 do
	-- Total cost from level 0 up to the current level
	local totalCostToLevel = cannonConfig.costFormula(level + 1, 0)

	-- Actual cost to upgrade from the current level to the next level
	local actualUpgradeCost
	if level == 1 then
		actualUpgradeCost = cannonConfig.costFormula(2, 0) -- Special case for first upgrade
	else
		actualUpgradeCost = cannonConfig.costFormula(level + 1, 0)
	end

	-- Required launches at the current level
	local requiredLaunches = cannonConfig.calculateRequiredLaunches(level)

	-- Average reward needed per launch at current level to afford the next upgrade
	local avgRewardPerLaunch = 0
	if requiredLaunches > 0 then
		avgRewardPerLaunch = actualUpgradeCost / requiredLaunches
	end

	-- Ratio of the average reward per launch relative to the total cost invested so far
	local rewardPerTotalCostRatio = 0
	if totalCostToLevel > 0 then
		rewardPerTotalCostRatio = avgRewardPerLaunch / totalCostToLevel
	end

	table.insert(
		outputLines,
		-- Format costs as integers, launches/ratios as floats
		string.format(
			headerFormat,
			level,
			string.format("%.0f", totalCostToLevel), -- Total Cost
			string.format("%.1f", requiredLaunches), -- Required Launches
			string.format("%.0f", actualUpgradeCost), -- Actual Upgrade Cost
			string.format("%.1f", cannonConfig.powerFormula(level)), -- Avg Reward/Launch
			string.format("%.4f", rewardPerTotalCostRatio) -- Reward/TotalCost Ratio
		)
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
table.insert(outputLines, "- TotalCostToLvl: Total cost accumulated from level 0 up to the start of the current level.")
table.insert(outputLines, "- Required Launches: Number needed at the current level based on cannonConfig logic.")
table.insert(outputLines, "- ActualUpgrCost: Cost to upgrade from the current level to the next level.")
table.insert(
	outputLines,
	"- AvgReward/Launch: Average reward needed per launch (at current level) to afford the next upgrade (ActualUpgrCost / RequiredLaunches)."
)
table.insert(
	outputLines,
	"- Reward/TotalCostRatio: Ratio of AvgReward/Launch to TotalCostToLvl. Indicates reward efficiency relative to total investment."
)
table.insert(
	outputLines,
	"- Floor Cost: Cost to upgrade *to* the end level of the range from level 0, using the latest floorConfig logic."
)

-- =============================================================================
-- Final Output
-- =============================================================================

-- Concatenate all lines into a single string with newline separators and print
print(table.concat(outputLines, "\n"))
