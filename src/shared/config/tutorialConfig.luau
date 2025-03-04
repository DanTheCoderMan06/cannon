local Players = game:GetService("Players")
local config = {
	steps = {
		{
			text = "Welcome to the tutorial! Our system detects you are a new player, and we recommend you read this tutorial to play the game! Press the close button to skip this tutorial!",
			action = function(items, nextSignal, states)
				local highlight = items.highlight
				local start = items.beamPart.start
				local target = items.beamPart.target
				highlight.Adornee = nil
				start.CFrame = CFrame.new()
				target.CFrame = CFrame.new()
				items.beam.Attachment0 = start
				items.beam.Attachment1 = target
				task.wait(5)
				nextSignal:Fire()

				states.toggleEntrence(false)

				states.toggleAllPlatforms(false)
			end,
		},
		{
			text = "First come to the upgrade cannon platform, here you can buy cannon levels to upgrade your cannon.",
			action = function(items, nextSignal, states)
				local highlight = items.highlight
				local start = items.beamPart.start
				local target = items.beamPart.target
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
				local upgradePlatform = playerPlatform.platforms:FindFirstChild("cannon")
				highlight.Adornee = upgradePlatform
				items.beam.Attachment0 =
					Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChildWhichIsA("Attachment")
				target.CFrame = upgradePlatform.CFrame

				local oldCannon = states.getData().cannon
				states.dataChanged:Connect(function(newData)
					if newData.cannon ~= oldCannon then
						nextSignal:Fire()
					end
				end)

				states.togglePlatform("cannon", true)
			end,
		},
		{
			text = "Then go to floors to upgrade your tower!",
			action = function(items, nextSignal, states)
				states.toggleAllPlatforms(false)
				local highlight = items.highlight
				local start = items.beamPart.start
				local target = items.beamPart.target
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
				local upgradePlatform = playerPlatform.platforms:FindFirstChild("floor")
				highlight.Adornee = upgradePlatform
				items.beam.Attachment0 =
					Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChildWhichIsA("Attachment")
				target.CFrame = upgradePlatform.CFrame

				local oldFloors = states.getData().floors
				states.dataChanged:Connect(function(newData)
					if newData.floors ~= oldFloors then
						nextSignal:Fire()
					end
				end)

				states.togglePlatform("floor", true)
			end,
		},
		{
			text = "Finally, head over to the cannon to launch yourself!",
			action = function(items, nextSignal, states)
				states.toggleAllPlatforms(false)
				local highlight = items.highlight
				local start = items.beamPart.start
				local target = items.beamPart.target
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
				local upgradePlatform = playerPlatform:FindFirstChild("cannonPart")
				highlight.Adornee = upgradePlatform
				items.beam.Attachment0 =
					Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChildWhichIsA("Attachment")
				target.CFrame = upgradePlatform.CFrame

				Players.LocalPlayer.Character:GetAttributeChangedSignal("inCannon"):Connect(function()
					if Players.LocalPlayer.Character:GetAttribute("inCannon") then
						nextSignal:Fire()
					end
				end)

				states.toggleEntrence(true)
			end,
		},
	},
}

return config
