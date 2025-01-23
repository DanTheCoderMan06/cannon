local Players = game:GetService("Players")
return {
	notifications = {
		freeFloors = {
			type = "comeback",
			waitTime = 45,
			assetid = "828ddcf5-3cf2-194f-993f-d20321078d8a",
			callback = {
				reward = {
					floors = 50,
				},
			},
			parseParameters = function(userId, playerData)
				local params = {}
				params["name"] = { stringValue = Players:GetNameFromUserIdAsync(userId) }

				return params
			end,
		},
	},
}
