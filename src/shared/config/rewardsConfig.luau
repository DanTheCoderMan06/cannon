local ReplicatedStorage = game:GetService("ReplicatedStorage")
return {
	rewards = {
		{
			day = 1,
			callback = function(playerData)
				table.insert(playerData.cannons, "circusCannon")
			end,
			type = "viewport",
			model = ReplicatedStorage.assets.minicannons:FindFirstChild("circusCannon"),
			name = "Circus Cannon",
		},
	},
}
