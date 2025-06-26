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

				-- Use Trove to manage the delay task
				local delayTask = task.delay(2.5, function()
					require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log("Next Signal")
					nextSignal:Fire()
				end)
				-- Add task cancellation function to the trove
				states.trove:Add(function()
					pcall(function()
						task.cancel(delayTask)
					end)
				end)

				-- Connect using Trove's Connect method
				task.wait()
				nextSignal:Fire()
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
				local sWait = tick() --LAUNCHFIX
				repeat
					task.wait()
				until Players.LocalPlayer.Character or tick() - sWait > 3 
				items.beam.Attachment0 =
					Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChildWhichIsA("Attachment")
				local cannonPart = playerPlatform:FindFirstChild("cannonPart")
				items.beam.Attachment1 = cannonPart and cannonPart:FindFirstChild("center", true) or target -- Assign to center attachment, fallback to original target
				-- Connect to GetAttributeChangedSignal using Trove
				states.trove:Add(upgradePlatform.ChildAdded:Connect(function(child)
					highlight.Adornee = upgradePlatform:FindFirstChildWhichIsA("Model", true)
				end))
				states.trove:Connect(Players.LocalPlayer.Character:GetAttributeChangedSignal("inCannon"), function()
					if Players.LocalPlayer.Character:GetAttribute("inCannon") then
						if items:FindFirstChild("beam") then
							items.beam.Attachment0 = nil
						else
							return
						end
						highlight.Adornee = nil
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
				local upgradePlatform = playerPlatform.platforms:FindFirstChild("oneLevel")
				highlight.Adornee = upgradePlatform:FindFirstChildWhichIsA("Model", true)
				items.beam.Attachment0 =
					Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChildWhichIsA("Attachment")
				items.beam.Attachment1 = upgradePlatform and upgradePlatform:FindFirstChild("center") or target -- Assign to center attachment, fallback to original target

				local oldCannon = states.getData().cannon

				-- Connect to dataChanged using Trove
				states.trove:Connect(states.dataChanged, function(newData)
					if newData.cannon ~= oldCannon then
						nextSignal:Fire()
					end
				end)

				states.toggleEntrance(false)
				states.togglePlatform("oneLevel", true)
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
				-- Assuming the target should be the cannon entrance area like step 2
				local cannonPart = playerPlatform:FindFirstChild("cannonPart")
				items.beam.Attachment1 = cannonPart and cannonPart:FindFirstChild("center") or target -- Assign to center attachment, fallback to original target
				states.trove:Add(upgradePlatform.ChildAdded:Connect(function(child)
					highlight.Adornee = upgradePlatform:FindFirstChildWhichIsA("Model", true)
				end))
				-- Connect to inCannon attribute change using Trove
				states.trove:Connect(Players.LocalPlayer.Character:GetAttributeChangedSignal("inCannon"), function()
					if Players.LocalPlayer.Character:GetAttribute("inCannon") then
						if items:FindFirstChild("beam") then
							items.beam.Attachment0 = nil
						else
							return
						end
						highlight.Adornee = nil
						Players.LocalPlayer.Character:GetAttributeChangedSignal("inCannon"):Wait()
						nextSignal:Fire()
					end
				end)

				states.toggleEntrance(true)

				-- Connect to CharacterRemoving using Trove
				states.trove:Connect(Players.LocalPlayer.CharacterRemoving, function()
					nextSignal:Fire()
				end)
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
				local upgradePlatform = playerPlatform.platforms:FindFirstChild("upgradeFloor")
				highlight.Adornee = upgradePlatform:FindFirstChildWhichIsA("Model", true)
				items.beam.Attachment0 =
					Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChildWhichIsA("Attachment")
				items.beam.Attachment1 = upgradePlatform and upgradePlatform:FindFirstChild("center") or target -- Assign to center attachment, fallback to original target

				local oldFloors = states.getData().floors

				-- Connect to dataChanged using Trove
				states.trove:Connect(states.dataChanged, function(newData)
					if newData.floors ~= oldFloors then
						nextSignal:Fire()
					end
				end)

				states.toggleEntrance(false)
				states.togglePlatform("upgradeFloor", true)
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

				-- Use Trove to manage the delay
				local delayTask = task.delay(0.1, function()
					nextSignal:Fire()
				end)
				states.trove:Add(function()
					pcall(function()
						task.cancel(delayTask)
					end)
				end)

				states.toggleEntrance(true)
			end,
		},
	},
}

return config
