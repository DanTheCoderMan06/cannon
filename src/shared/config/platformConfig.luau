return {
	cannon = {
		callback = function()
			print("Touched!")
		end,
		title = "UPGRADE CANNON",
		description = "N/A",
		updateValues = function(trove, updateEvent)
			local Players = game:GetService("Players")
			local stats = Players.LocalPlayer:WaitForChild("leaderstats")
			for _, v in pairs(stats:GetChildren()) do
				if v:GetAttribute("statName") ~= "cannon" then
					continue
				end
				trove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
					updateEvent:Fire({ title = "LEVEL " .. v.Value, description = "N/A" })
				end))
			end
		end,
		init = function()
			local Players = game:GetService("Players")
			local stats = Players.LocalPlayer:WaitForChild("leaderstats")
			for _, v in pairs(stats:GetChildren()) do
				if v:GetAttribute("statName") == "cannon" then
					return { title = "LEVEL " .. v.Value, description = "N/A" }
				end
			end
		end,
	},
	floor = {
		callback = function()
			print("Touched!")
		end,
		title = "+1 FLOOR",
		description = "N/A",
		updateValues = function(trove, updateEvent)
			local Players = game:GetService("Players")
			local stats = Players.LocalPlayer:WaitForChild("leaderstats")
			for _, v in pairs(stats:GetChildren()) do
				if v:GetAttribute("statName") ~= "floors" then
					continue
				end
				trove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
					updateEvent:Fire({ title = "+1 FLOOR", description = "N/A" })
				end))
			end
		end,
		init = function()
			local Players = game:GetService("Players")
			local stats = Players.LocalPlayer:WaitForChild("leaderstats")
			for _, v in pairs(stats:GetChildren()) do
				if v:GetAttribute("statName") == "floors" then
					return { title = "+1 FLOOR", description = "N/A" }
				end
			end
		end,
	},
	tenFloors = {
		callback = function()
			print("Touched!")
		end,
		title = "+10 FLOORS",
		description = '100 <font color="#008000">\u{E002}</font>',
	},
	fiftyFloors = {
		callback = function()
			print("Touched!")
		end,
		title = "+40 FLOORS",
		description = '100 <font color="#008000">\u{E002}</font>',
	},
	doubleGunpowder = {
		callback = function()
			print("Touched!")
		end,
		title = "x2 POWER",
		description = '100 <font color="#008000">\u{E002}</font>',
	},
	newCannon = {
		callback = function()
			print("Touched!")
		end,
		title = "UPGRADE CANNON",
		description = '100 <font color="#008000">\u{E002}</font>',
	},
}
