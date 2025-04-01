local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)

local function logFormula(playerLevel: IntValue)
	return math.round(math.log(playerLevel, 10))
end

local function luckyBlockReward(playerLevel)
	-- Base reward that scales with player level
	local baseReward = 1000 + (playerLevel * 150) * 25

	-- Logarithmic component for diminishing returns at higher levels
	local logScale = math.log10(playerLevel + 10)

	-- Progressive reward scaling for different level ranges
	local scaledReward
	if playerLevel < 20 then
		-- Early game (generous rewards to help players progress)
		scaledReward = baseReward * (1 + logScale * 0.5)
	elseif playerLevel < 50 then
		-- Mid game (moderate logarithmic scaling)
		scaledReward = baseReward * (1 + logScale * 0.4)
	else
		-- Late game (stronger logarithmic dampening)
		scaledReward = baseReward * (1 + logScale * 0.3)
	end

	-- Add variability with controlled randomness (80-120% of calculated value)
	local randomFactor = 0.8 + (math.random() * 0.4)

	-- Round to nearest 100 for clean numbers
	return math.floor((scaledReward * randomFactor) / 100) * 100
end

local function getDailyReward(day, playerLevel)
	-- Base component scaling with consecutive days
	local baseReward = math.min(day * 300, 6000)

	-- Logarithmic scaling based on cannon level
	local progressBonus = math.log10(playerLevel + 10) * 500

	-- Special milestone rewards
	local milestoneMultiplier = 1
	if day % 7 == 0 then -- weekly bonus
		milestoneMultiplier = 2
	elseif day % 3 == 0 then -- smaller bonus every 3 days
		milestoneMultiplier = 1.5
	end

	-- Scale rewards differently for early, mid, and late game
	local scaledReward
	if day < 10 then
		-- Early rewards
		scaledReward = (baseReward + progressBonus) * milestoneMultiplier
	elseif day < 20 then
		-- Mid game rewards
		scaledReward = (baseReward + progressBonus * 1.2) * milestoneMultiplier
	else
		-- Late game rewards with higher floor but slower growth
		scaledReward = (baseReward + progressBonus * 1.5) * milestoneMultiplier
	end

	-- Round to nearest 100 for clean numbers
	return math.floor(scaledReward / 100) * 100
end

local function referralReward(referrerLevel)
	-- Base reward meaningful even for new players
	local baseReward = 5000

	-- Logarithmic scaling with referrer's progress
	local logScale = math.log10(referrerLevel + 10)

	-- Scale rewards differently based on referrer's progress
	local progressBonus
	if referrerLevel < 30 then
		-- Early game referrers
		progressBonus = referrerLevel * 100
	elseif referrerLevel < 70 then
		-- Mid game referrers - use logarithmic scaling
		progressBonus = referrerLevel * 50 * logScale
	else
		-- Late game referrers - more logarithmic dampening
		progressBonus = referrerLevel * 30 * logScale
	end

	-- Cap maximum reward
	local maxReward = 25000
	local reward = math.min(baseReward + progressBonus, maxReward)

	-- Round to nearest 500 for clean numbers
	return math.floor(reward / 500) * 500
end

local module = {
	luckyBlockWaitTime = 20,
	playerJoinReward = referralReward,
	luckyBlockFormula = luckyBlockReward,
	vipRewardDuration = 10000,
	vipGamepass = 1060138098,
	referWaitTime = 50,
	rewards = {
		{
			day = 1,
			callback = function(playerData, player)
				local ServerStorage = game:GetService("ServerStorage")
				local vipService = require(ServerStorage.server.services.vipService)
				vipService.givePlayerTempVIP(player)
			end,
			type = "image",
			image = "rbxassetid://128528383855205", -- money 1
			name = "VIP",
		},
		{
			day = 2,
			callback = function(playerData)
				playerData.floors += 10
			end,
			type = "image",
			image = "rbxassetid://114681769444446", -- floors 1
			name = "+10 Floors",
		},
		{
			day = 3,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon += 5
					playerData.cannon = math.clamp(playerData.cannon, 0, cannonConfig.maxLevel)
				end
			end,
			type = "image",
			image = "rbxassetid://130622146298272", -- levels 1
			name = "+5 Levels",
		},
		{
			day = 4,
			callback = function(playerData)
				playerData.money += getDailyReward(4, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://128528383855205", -- money 1
			name = "Cash",
		},
		{
			day = 5,
			callback = function(playerData)
				playerData.floors += 10
			end,
			type = "image",
			image = "rbxassetid://114681769444446", -- floors 1
			name = "+10 Floors",
		},
		{
			day = 6,
			callback = function(playerData)
				playerData.money += getDailyReward(6, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://103800518067222", -- money 2
			name = "Cash",
		},
		{
			day = 7,
			callback = function(playerData)
				playerData.money *= 2
			end,
			type = "image",
			image = "rbxassetid://99606636871207", -- money 4
			name = "x2 Money",
		},
		{
			day = 8,
			callback = function(playerData)
				playerData.money += getDailyReward(8, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://103800518067222", -- money 2
			name = "Cash",
		},
		{
			day = 9,
			callback = function(playerData)
				playerData.money += getDailyReward(9, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://138174371404751", -- money 3
			name = "Cash",
		},
		{
			day = 10,
			callback = function(playerData)
				if not table.find(playerData.cannons, "armyCannon") then
					table.insert(playerData.cannons, "armyCannon")
				end
			end,
			type = "image",
			image = "rbxassetid://128528383855205", -- money 1
			name = "Cash",
		},
		{
			day = 11,
			callback = function(playerData)
				playerData.money += getDailyReward(11, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://109170235764314", -- floors 2
			name = "+20 Floors",
		},
		{
			day = 12,
			callback = function(playerData)
				playerData.floors += 20
			end,
			type = "image",
			image = "rbxassetid://109170235764314", -- floors 2
			name = "+20 Floors",
		},
		{
			day = 13,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon += 10
					playerData.cannon = math.clamp(playerData.cannon, 0, cannonConfig.maxLevel)
				end
			end,
			type = "image",
			image = "rbxassetid://125247795327983", -- levels 2
			name = "+10 Levels",
		},
		{
			day = 14,
			callback = function(playerData)
				playerData.money += getDailyReward(14, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://103800518067222", -- money 2
			name = "Cash",
		},
		{
			day = 15,
			callback = function(playerData)
				playerData.floors += 20
			end,
			type = "image",
			image = "rbxassetid://109170235764314", -- floors 2
			name = "+20 Floors",
		},
		{
			day = 16,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon += 10
					playerData.cannon = math.clamp(playerData.cannon, 0, cannonConfig.maxLevel)
				end
			end,
			type = "image",
			image = "rbxassetid://125247795327983", -- levels 2
			name = "+10 Levels",
		},
		{
			day = 17,
			callback = function(playerData)
				playerData.money += getDailyReward(17, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://138174371404751", -- money 3
			name = "Cash",
		},
		{
			day = 18,
			callback = function(playerData)
				playerData.money += getDailyReward(18, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://138174371404751", -- money 3
			name = "Cash",
		},
		{
			day = 19,
			callback = function(playerData)
				playerData.money += getDailyReward(19, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://99606636871207", -- money 4
			name = "Cash",
		},
		{
			day = 20,
			callback = function(playerData)
				playerData.distanceIncreased = true
			end,
			type = "image",
			image = "rbxassetid://128528383855205", -- money 1
			name = "Cash", -- Note: Callback is distanceIncreased, but name is Cash
		},
		{
			day = 21,
			callback = function(playerData)
				playerData.money += getDailyReward(21, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://103800518067222", -- money 2
			name = "Cash",
		},
		{
			day = 22,
			callback = function(playerData)
				playerData.floors += 50
			end,
			type = "image",
			image = "rbxassetid://76426067940627", -- floors 3
			name = "+50 Floors",
		},
		{
			day = 23,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon += 20
					playerData.cannon = math.clamp(playerData.cannon, 0, cannonConfig.maxLevel)
				end
			end,
			type = "image",
			image = "rbxassetid://95225204873256", -- levels 3
			name = "+20 Levels",
		},
		{
			day = 24,
			callback = function(playerData)
				playerData.money += getDailyReward(24, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://138174371404751", -- money 3
			name = "Cash",
		},
		{
			day = 25,
			callback = function(playerData)
				playerData.floors += 100
			end,
			type = "image",
			image = "rbxassetid://76426067940627", -- floors 3
			name = "+100 Floors",
		},
		{
			day = 26,
			callback = function(playerData)
				playerData.money += getDailyReward(26, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://99606636871207", -- money 4
			name = "Cash",
		},
		{
			day = 27,
			callback = function(playerData)
				playerData.money += getDailyReward(27, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://99606636871207", -- money 4
			name = "Cash",
		},
		{
			day = 28,
			callback = function(playerData)
				playerData.money += getDailyReward(28, playerData.cannon)
			end,
			type = "image",
			image = "rbxassetid://99606636871207", -- money 4
			name = "Cash",
		},
		{
			day = 29,
			callback = function(playerData)
				playerData.floors += 500
			end,
			type = "image",
			image = "rbxassetid://76426067940627", -- floors 3
			name = "+500 Floors",
		},
		{
			day = 30,
			callback = function(playerData)
				table.insert(playerData.cannons, "railgun")
			end,
			type = "viewport",
			model = ReplicatedStorage.assets.cannons:FindFirstChild("railgun"),
			name = "Rail-gun",
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
