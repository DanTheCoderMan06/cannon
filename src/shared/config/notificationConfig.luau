local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

return {
	notifications = {
		freeFloors = {
			multiple = true,
			waitTime = 230,
			assetid = "828ddcf5-3cf2-194f-993f-d20321078d8a",
			callback = function(playerData)
				playerData.Data.floors += 50
			end,
			parseParameters = function(userId, playerData)
				local params = {}
				params["name"] = { stringValue = Players:GetNameFromUserIdAsync(userId) }

				return params
			end,
		},
		freeCannon = {
			multiple = true,
			waitTime = 230,
			assetid = "060f951a-9911-6442-a4d7-96efa7187846",
			callback = function(playerData)
				playerData.Data.floors += 500
				if not table.find(playerData.Data.cannons, "circusCannon") then
					table.insert(playerData.Data.cannons, "circusCannon")
				end
			end,
			parseParameters = function(userId, playerData)
				local params = {}
				params["name"] = { stringValue = Players:GetNameFromUserIdAsync(userId) }

				return params
			end,
		},
		dailyReward = {
			multiple = false,
			waitTime = 230,
			assetid = "2cf3ffb9-87c5-c34b-9ba2-68b6de1fa3ae6",
			callback = function(playerData) end,
			parseParameters = function(userId, playerData)
				local params = {}
				local timePassed = os.time() - playerData.lastClaimed
				local daysPassed = math.floor(timePassed / (24 * 60 * 60))
				local rewardName = rewardsConfig.getDailyReward(playerData.daysPlayed + daysPassed).name
				params["rewardName"] = { stringValue = rewardName }
				return params
			end,
		},
	},
}
