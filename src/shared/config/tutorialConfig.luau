local Players = game:GetService("Players")
local config = {
	steps = {
		{
			text = "Welcome to the tutorial! We recommend you read this tutorial to play the game! Press the X to close!",
			action = function(items, nextSignal, states)
				states.toggleAllPlatforms(false)
				local highlight = items.highlight
				local start = items.beamPart.start
				local target = items.beamPart.target
				highlight.Adornee = nil
				items.beam.Attachment0 = target
				items.beam.Attachment1 = target
				states.toggleEntrance(false)

				Players.LocalPlayer.Character:WaitForChild("Humanoid"):GetPropertyChangedSignal("MoveDirection"):Wait()

				local con
				task.delay(2.5, function()
					if con then
						con:Disconnect()
					end
					nextSignal:Fire()
				end)

				con = Players.LocalPlayer.CharacterRemoving:Connect(function(character)
					con:Disconnect()
					nextSignal:Fire()
				end)
			end,
		},
		{
			text = "First, come to the cannon area to launch yourself!",
			action = function(items, nextSignal, states)
				states.toggleAllPlatforms(false)
				local highlight = items.highlight
				local start = items.beamPart.start
				local target = items.beamPart.target
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
				local upgradePlatform = playerPlatform:FindFirstChild("cannonPosition")
				highlight.Adornee = upgradePlatform:FindFirstChildWhichIsA("Model", true)
				items.beam.Attachment0 =
					Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChildWhichIsA("Attachment")
				target.CFrame = upgradePlatform.CFrame

				local con

				con = Players.LocalPlayer.Character:GetAttributeChangedSignal("inCannon"):Connect(function()
					if Players.LocalPlayer.Character:GetAttribute("inCannon") then
						con:Disconnect()
						items.beam.Attachment0 = target
						Players.LocalPlayer.Character:GetAttributeChangedSignal("inCannon"):Wait()
						nextSignal:Fire()
					end
				end)

				states.toggleEntrance(true)
			end,
		},
		{
			text = "Then come to the upgrade cannon platform, here you can buy cannon levels to upgrade your cannon.",
			action = function(items, nextSignal, states)
				local highlight = items.highlight
				local start = items.beamPart.start
				local target = items.beamPart.target
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
				local upgradePlatform = playerPlatform.platforms:FindFirstChild("cannon")
				highlight.Adornee = upgradePlatform:FindFirstChildWhichIsA("Model", true)
				items.beam.Attachment0 =
					Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChildWhichIsA("Attachment")
				target.CFrame = upgradePlatform.CFrame

				local oldCannon = states.getData().cannon
				local conn
				conn = states.dataChanged:Connect(function(newData)
					if newData.cannon ~= oldCannon then
						conn:Disconnect()
						nextSignal:Fire()
					end
				end)

				states.toggleEntrance(false)
				states.togglePlatform("cannon", true)
			end,
		},
		{
			text = "Now launch yourself with the new cannon!",
			action = function(items, nextSignal, states)
				states.toggleAllPlatforms(false)
				local highlight = items.highlight
				local start = items.beamPart.start
				local target = items.beamPart.target
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
				local upgradePlatform = playerPlatform:FindFirstChild("cannonPosition")
				highlight.Adornee = upgradePlatform:FindFirstChildWhichIsA("Model", true)
				items.beam.Attachment0 =
					Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChildWhichIsA("Attachment")
				target.CFrame = upgradePlatform.CFrame

				local con
				con = Players.LocalPlayer.Character:GetAttributeChangedSignal("inCannon"):Connect(function()
					if Players.LocalPlayer.Character:GetAttribute("inCannon") then
						con:Disconnect()
						items.beam.Attachment0 = target
						Players.LocalPlayer.Character:GetAttributeChangedSignal("inCannon"):Wait()
						nextSignal:Fire()
					end
				end)

				states.toggleEntrance(true)

				Players.LocalPlayer.CharacterRemoving:Wait()
				nextSignal:Fire()
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
				highlight.Adornee = upgradePlatform:FindFirstChildWhichIsA("Model", true)
				items.beam.Attachment0 =
					Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChildWhichIsA("Attachment")
				target.CFrame = upgradePlatform.CFrame

				local oldFloors = states.getData().floors
				local conn
				conn = states.dataChanged:Connect(function(newData)
					if newData.floors ~= oldFloors then
						conn:Disconnect()
						nextSignal:Fire()
					end
				end)

				states.toggleEntrance(false)
				states.togglePlatform("floor", true)
			end,
		},
		{
			text = "Thank you for playing the tutorial! Enjoy the game!",
			action = function(items, nextSignal, states)
				states.toggleAllPlatforms(false)
				local highlight = items.highlight
				local start = items.beamPart.start
				local target = items.beamPart.target
				highlight.Adornee = nil
				items.beam.Attachment0 = target
				items.beam.Attachment1 = target
				states.toggleEntrance(false)
				task.delay(2.5, function()
					nextSignal:Fire()
				end)
				states.toggleEntrance(true)
			end,
		},
	},
}

return config
