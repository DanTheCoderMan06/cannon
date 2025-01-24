local Players = game:GetService("Players")
return {
	notifications = {
		freeFloors = {
			type = "comeback",
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
			type = "comeback",
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
	},
}
