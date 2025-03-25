local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)

local function logFormula(playerLevel: IntValue)
	return math.round(math.log(playerLevel, 10))
end

local function luckyBlockReward(playerLevel)
    -- Base component that scales with player level
    local baseReward = 1000 + (playerLevel * 200)
    
    -- Logarithmic component for diminishing returns
    local logComponent = math.log(playerLevel + 20, 2) * 500
    
    -- Random multiplier between 0.8 and 1.5 for variability
    local randomMultiplier = 0.8 + (math.random() * 0.7)
    
    -- Scale based on cannon level (more powerful cannons = better rewards)
    local cannonBonus = math.sqrt(playerLevel) * 300
    
    -- Combine components
    local reward = (baseReward + logComponent + cannonBonus) * randomMultiplier
    
    -- Round to nearest 100 for clean numbers
    return math.floor(reward / 100) * 100
end

local function getDailyReward(day, playerData)
    -- Base rewards that increase with consecutive days
    local baseReward = math.min(day * 500, 10000)
    
    -- Special milestone rewards
    local milestoneMultiplier = 1
    if day % 5 == 0 then -- every 5 days
        milestoneMultiplier = 1.5
    end
    if day % 10 == 0 then -- every 10 days
        milestoneMultiplier = 2
    end
    
    -- Scale with player progress
    local progressScaling = 1 + (math.log(playerData.cannon + 10, 10) * 0.2)
    
    -- Calculate final reward
    local reward = baseReward * milestoneMultiplier * progressScaling
    
    -- For money rewards
    return math.floor(reward / 100) * 100
end

local function referralReward(referrerLevel)
    -- Base reward that's meaningful even for new players
    local baseReward = 5000
    
    -- Scaling component based on referrer's progress
    local progressBonus = referrerLevel * 200
    
    -- Cap the maximum reward
    local maxReward = 25000
    
    return math.min(baseReward + progressBonus, maxReward)
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
			image = "",
			name = "VIP",
		},
		--[[
		{
			day = 2,
			callback = function(playerData)
				playerData.floors += 10
			end,
			type = "image",
			image = "",
			name = "+10 Floors",
		},
		--]]
		{
			day = 2,
			callback = function(playerData)
				if not table.find(playerData.cannons, "artillery") then
					table.insert(playerData.cannons, "artillery")
				end
			end,
			type = "viewport",
			model = ReplicatedStorage.assets.cannons:FindFirstChild("artillery"),
			name = "Artillery",
		},
		{
			day = 3,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon += 5
					playerData.cannon = math.clamp(playerData.cannon,0,cannonConfig.maxLevel)
				end	
			end,
			type = "image",
			image = "",
			name = "+5 Levels",
		},
		{
			day = 4,
			callback = function(playerData)
				playerData.money +=getDailyReward(4,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 5,
			callback = function(playerData)
				playerData.floors += 10
			end,
			type = "image",
			image = "",
			name = "+10 Floors",
		},
		{
			day = 6,
			callback = function(playerData)
				playerData.money +=getDailyReward(6,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 7,
			callback = function(playerData)
				playerData.money *= 2
			end,
			type = "image",
			image = "",
			name = "x2 Money",
		},
		{
			day = 8,
			callback = function(playerData)
				playerData.money += getDailyReward(8,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 9,
			callback = function(playerData)
				playerData.money +=getDailyReward(9,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 10,
			callback = function(playerData)
				if not table.find(playerData.cannons, "railgun") then
					table.insert(playerData.cannons, "railgun")
				end
			end,
			type = "viewport",
			model = ReplicatedStorage.assets.cannons:FindFirstChild("railgun"),
			name = "Railgun",
		},
		{
			day = 11,
			callback = function(playerData)
				playerData.money  += getDailyReward(11,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 12,
			callback = function(playerData)
				playerData.floors += 20
			end,
			type = "image",
			image = "",
			name = "+20 Floors",
		},
		{
			day = 13,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon += 10
					playerData.cannon = math.clamp(playerData.cannon,0,cannonConfig.maxLevel)
				end
				end,
			type = "image",
			image = "",
			name = "+10 Levels",
		},
		{
			day = 14,
			callback = function(playerData)
				playerData.money  += getDailyReward(14,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 15,
			callback = function(playerData)
				playerData.floors += 20
			end,
			type = "image",
			image = "",
			name = "+20 Floors",
		},
		{
			day = 16,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon += 10
					playerData.cannon = math.clamp(playerData.cannon,0,cannonConfig.maxLevel)
				end
			end,
			type = "image",
			image = "",
			name = "+10 Levels",
		},
		{
			day = 17,
			callback = function(playerData)
				playerData.money  += getDailyReward(17,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 18,
			callback = function(playerData)
				playerData.money +=getDailyReward(18,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 19,
			callback = function(playerData)
				playerData.money +=getDailyReward(19,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 20,
			callback = function(playerData)
				playerData.distanceIncreased = true
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 21,
			callback = function(playerData)
				playerData.money +=getDailyReward(21,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 22,
			callback = function(playerData)
				playerData.floors += 50
			end,
			type = "image",
			image = "",
			name = "+50 Floors",
		},
		{
			day = 23,
			callback = function(playerData)
				if cannonConfig.maxLevel > playerData.cannon then
					playerData.cannon += 20
					playerData.cannon = math.clamp(playerData.cannon,0,cannonConfig.maxLevel)
				end	
			end,
			type = "image",
			image = "",
			name = "+20 Levels",
		},
		{
			day = 24,
			callback = function(playerData)
				playerData.money +=getDailyReward(24,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 25,
			callback = function(playerData)
				playerData.floors += 100
			end,
			type = "image",
			image = "",
			name = "+100 Floors",
		},
		{
			day = 26,
			callback = function(playerData)
				playerData.money +=getDailyReward(26,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 27,
			callback = function(playerData)
				playerData.money +=getDailyReward(27,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 28,
			callback = function(playerData)
				playerData.money +=getDailyReward(28,playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 29,
			callback = function(playerData)
				playerData.floors += 500
			end,
			type = "image",
			image = "",
			name = "+500 Floors",
		},
		{
			day = 30,
			callback = function(playerData)
				table.insert(playerData.cannons, "armyCannon")
			end,
			type = "viewport",
			model = ReplicatedStorage.assets.cannons:FindFirstChild("armyCannon"),
			name = "Army Cannon",
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
