local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local floorConfig = require(ReplicatedStorage.shared.config.floorConfig) -- Added floorConfig require
local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)

local function luckyBlockWaitTime(playerLevel)
	if RunService:IsStudio() then
		return 10
	end
	if playerLevel < 20 then
		return 180
	elseif playerLevel < 70 then
		return 180 + playerLevel * 4
	end
	return 460
end

local function luckyBlockReward(floors, boughtFloors)
	local totalCost = 0

	for i = 1, 2 do
		totalCost += floorConfig.costFormula(floors + i, boughtFloors)
	end

	local finalReward = math.round(totalCost)
	print(
		string.format(
			"[RewardsConfig Debug] Calculated lucky block reward. Floors: %d, BoughtFloors: %d, Reward: %d",
			floors,
			boughtFloors,
			finalReward
		)
	)
	return finalReward
end

local function getDailyRewardCash(day, currentFloors) -- Removed playerLevel parameter
	local baseFloorCost = floorConfig.costFormula(currentFloors, 0) -- Cost of the first floor
	local reward = baseFloorCost * math.pow(1.1, day - 1)

	-- Round to nearest 100 for clean numbers
	return math.floor(reward / 100) * 100
end

local function referralReward(floors, boughtFloors) -- Changed parameter to accept floors and boughtFloors
	-- Calculate reward based on referrer's next floor cost * 6
	local totalCost = 0

	for i = 1, 5 do
		totalCost += floorConfig.costFormula(floors + i, boughtFloors)
	end

	return math.round(totalCost)
end

local module = {
	luckyBlockWaitTime = luckyBlockWaitTime, -- Revert to original static value
	playerJoinReward = referralReward,
	luckyBlockFormula = luckyBlockReward,
	vipRewardDuration = 10000,
	vipGamepass = 1022963419,
	referWaitTime = 60 * 60 * 24,
	getDailyRewardCash = getDailyRewardCash,
	rewards = {
		{ -- Day 1: money reward
			day = 1,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(1, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://128528383855205",
			name = "Cash",
		},
		{ -- Day 2: 10 floors
			day = 2,
			callback = function(playerData)
				playerData.floors += 10
			end,
			type = "image",
			image = "rbxassetid://114681769444446",
			name = "+10 Floors",
		},
		{ -- Day 3: 5 levels
			day = 3,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon = math.min(playerData.cannon + 5, cannonConfig.maxLevel)
				end
			end,
			type = "image",
			image = "rbxassetid://130622146298272",
			name = "+5 Levels",
		},
		{ -- Day 4: money reward
			day = 4,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(4, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://103800518067222",
			name = "Cash",
		},
		{ -- Day 5: 10 floors
			day = 5,
			callback = function(playerData)
				playerData.floors += 10
			end,
			type = "image",
			image = "rbxassetid://114681769444446",
			name = "+10 Floors",
		},
		{ -- Day 6: money reward
			day = 6,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(6, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://138174371404751",
			name = "Cash",
		},
		{ -- Day 7: 2x Money gamepass
			day = 7,
			callback = function(playerData)
				playerData.doubleMoney = true
			end,
			type = "image",
			image = "rbxassetid://99606636871207",
			name = "2x Cash", -- Reusing money 4 image
		},
		{ -- Day 8: money reward
			day = 8,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(8, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://103800518067222",
			name = "Cash",
		},
		{ -- Day 9: money reward
			day = 9,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(9, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://138174371404751",
			name = "Cash",
		},
		{ -- Day 10: 799 robux cannon (Artillery)
			day = 10,
			callback = function(playerData)
				if not table.find(playerData.cannons, "artillery") then
					table.insert(playerData.cannons, "artillery")
				end
			end,
			type = "image", -- Changed from viewport
			image = "rbxassetid://99541703558018", -- Placeholder image ID
			name = "Artillery Cannon", -- Updated name
		},
		{ -- Day 11: money reward
			day = 11,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(11, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://103800518067222",
			name = "Cash",
		},
		{ -- Day 12: 20 floors
			day = 12,
			callback = function(playerData)
				playerData.floors += 20
			end,
			type = "image",
			image = "rbxassetid://109170235764314",
			name = "+20 Floors",
		},
		{ -- Day 13: 10 levels
			day = 13,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon = math.min(playerData.cannon + 10, cannonConfig.maxLevel)
				end
			end,
			type = "image",
			image = "rbxassetid://125247795327983",
			name = "+10 Levels",
		},
		{ -- Day 14: money reward
			day = 14,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(14, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://138174371404751",
			name = "Cash",
		},
		{ -- Day 15: 20 floors
			day = 15,
			callback = function(playerData)
				playerData.floors += 20
			end,
			type = "image",
			image = "rbxassetid://109170235764314",
			name = "+20 Floors",
		},
		{ -- Day 16: 10 levels
			day = 16,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon = math.min(playerData.cannon + 10, cannonConfig.maxLevel)
				end
			end,
			type = "image",
			image = "rbxassetid://125247795327983",
			name = "+10 Levels",
		},
		{ -- Day 17: money reward
			day = 17,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(17, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://99606636871207",
			name = "Cash",
		},
		{ -- Day 18: money reward
			day = 18,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(18, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://103800518067222",
			name = "Cash",
		},
		{ -- Day 19: money reward
			day = 19,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(19, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://138174371404751",
			name = "Cash",
		},
		{ -- Day 20: 2x Distance gamepass
			day = 20,
			callback = function(playerData)
				playerData.doubleDistance = true
			end,
			type = "image",
			image = "rbxassetid://128528383855205",
			name = "2x Distance", -- Reusing money 1 image
		},
		{ -- Day 21: money reward
			day = 21,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(21, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://99606636871207",
			name = "Cash",
		},
		{ -- Day 22: 50 floors
			day = 22,
			callback = function(playerData)
				playerData.floors += 50
			end,
			type = "image",
			image = "rbxassetid://76426067940627",
			name = "+50 Floors",
		},
		{ -- Day 23: 20 levels
			day = 23,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon = math.min(playerData.cannon + 20, cannonConfig.maxLevel)
				end
			end,
			type = "image",
			image = "rbxassetid://95225204873256",
			name = "+20 Levels",
		},
		{ -- Day 24: money reward
			day = 24,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(24, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://103800518067222",
			name = "Cash",
		},
		{ -- Day 25: 100 floors
			day = 25,
			callback = function(playerData)
				playerData.floors += 100
			end,
			type = "image",
			image = "rbxassetid://76426067940627",
			name = "+100 Floors",
		},
		{ -- Day 26: money reward
			day = 26,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(26, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://138174371404751",
			name = "Cash",
		},
		{ -- Day 27: money reward
			day = 27,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(27, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://99606636871207",
			name = "Cash",
		},
		{ -- Day 28: money reward
			day = 28,
			callback = function(playerData)
				playerData.money += getDailyRewardCash(28, playerData.floors)
			end,
			type = "image",
			image = "rbxassetid://103800518067222",
			name = "Cash",
		},
		{ -- Day 29: 250 floors
			day = 29,
			callback = function(playerData)
				playerData.floors += 250
			end,
			type = "image",
			image = "rbxassetid://76426067940627",
			name = "+250 Floors",
		},
		{ -- Day 30: 1699 robux cannon (Railgun)
			day = 30,
			callback = function(playerData)
				if not table.find(playerData.cannons, "railgun") then
					table.insert(playerData.cannons, "railgun")
				end
			end,
			type = "image", -- Changed from viewport
			image = "rbxassetid://90322020414034", -- Placeholder image ID
			name = "Railgun Cannon", -- Updated name
		},
	},
	rewardNotification = {
		assetId = "2cf3ffb9-87c5-c34b-9ba2-68b6de1fa3ae",
	},
}

function module.getDailyReward(day: IntValue)
	for _, v in pairs(module.rewards) do
		if v.day == day then
			return v
		end
	end
end

return module
