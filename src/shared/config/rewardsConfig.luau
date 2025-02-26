local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function logFormula(playerLevel: IntValue)
	return math.round(math.log(playerLevel, 10))
end

local function randomRewardLog(playerLevel)
	return math.round(math.log(playerLevel + 100, 10) * math.pow(playerLevel + 100, 2.3) * (math.random() + 0.5))
end

local module = {
	luckyBlockWaitTime = 10,
	playerJoinReward = 1000000,
	luckyBlockFormula = randomRewardLog,
	vipRewardDuration = 10000,
	vipGamepass = 1060138098,
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
				playerData.cannon += 5
			end,
			type = "image",
			image = "",
			name = "+5 Levels",
		},
		{
			day = 4,
			callback = function(playerData)
				playerData.money += 125 * logFormula(playerData.cannon)
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
				playerData.money += 125 * logFormula(playerData.cannon)
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
				playerData.money += 125 * logFormula(playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 9,
			callback = function(playerData)
				playerData.money += 125 * logFormula(playerData.cannon)
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
				playerData.money += 150 * logFormula(playerData.cannon)
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
				playerData.cannon += 10
			end,
			type = "image",
			image = "",
			name = "+10 Levels",
		},
		{
			day = 14,
			callback = function(playerData)
				playerData.money += 150 * logFormula(playerData.cannon)
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
				playerData.cannon += 10
			end,
			type = "image",
			image = "",
			name = "+10 Levels",
		},
		{
			day = 17,
			callback = function(playerData)
				playerData.money += 200 * logFormula(playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 18,
			callback = function(playerData)
				playerData.money += 200 * logFormula(playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 19,
			callback = function(playerData)
				playerData.money += 200 * logFormula(playerData.cannon)
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
				playerData.money += 210 * logFormula(playerData.cannon)
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
				playerData.cannon += 20
			end,
			type = "image",
			image = "",
			name = "+20 Levels",
		},
		{
			day = 24,
			callback = function(playerData)
				playerData.money += 250 * logFormula(playerData.cannon)
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
				playerData.money += 300 * logFormula(playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 27,
			callback = function(playerData)
				playerData.money += 300 * logFormula(playerData.cannon)
			end,
			type = "image",
			image = "",
			name = "Cash",
		},
		{
			day = 28,
			callback = function(playerData)
				playerData.money += 300 * logFormula(playerData.cannon)
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
