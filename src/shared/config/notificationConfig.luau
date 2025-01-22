local Players = game:GetService("Players")
return {
	notifications = {
		freeFloors = {
			waitTime = 45,
			assetid = "b3d932ed-4f76-c842-a6f7-d83379379a06",
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
