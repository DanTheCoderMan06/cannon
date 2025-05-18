local policyService = game:GetService("PolicyService")
local experienceNotificationService = game:GetService("ExperienceNotificationService")
return {
	tasks = {
		{
			name = "notifications",
			taskText = "Enable Notifications",
			execute = function(updateEvent, ...)
				local function check()
					local canOptIn = true
					pcall(function()
						canOptIn = experienceNotificationService:CanPromptOptInAsync()
					end)
					return not canOptIn
				end
				experienceNotificationService.OptInPromptClosed:Connect(function()
					updateEvent:Fire(check() and "notifications")
				end)
				task.delay(0.25, function()
					updateEvent:Fire(check() and "notifications")
				end)
			end,
		},
		{
			name = "playTime",
			taskText = "Play for 5 minutes!",
			execute = function(updateEvent, initialData)
				local timeLeft = 300 - (os.time() - initialData.timeCreated)
				if timeLeft < 0 then
					updateEvent:Fire("playTime")
					return
				end
				task.delay(timeLeft + 1, function()
					updateEvent:Fire("playTime")
				end)
			end,
		},
	},
}
