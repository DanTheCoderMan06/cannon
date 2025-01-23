local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {
	rewards = {
		{
			day = 1,
			callback = function(playerData)
				playerData.money += 5
			end,
			type = "image",
			image = "",
			name = "+5 Cash",
		},
		{
			day = 2,
			callback = function(playerData)
				playerData.money += 10
			end,
			type = "image",
			image = "",
			name = "+10 Cash",
		},
		{
			day = 3,
			callback = function(playerData)
				playerData.money += 20
			end,
			type = "image",
			image = "",
			name = "+20 Cash",
		},
		{
			day = 4,
			callback = function(playerData)
				playerData.money += 50
			end,
			type = "image",
			image = "",
			name = "+50 Cash",
		},
		{
			day = 5,
			callback = function(playerData)
				table.insert(playerData.cannons, "circusCannon")
			end,
			type = "viewport",
			model = ReplicatedStorage.assets.minicannons:FindFirstChild("circusCannon"),
			name = "Circus Cannon",
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
