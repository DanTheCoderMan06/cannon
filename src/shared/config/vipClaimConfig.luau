local policyService = game:GetService("PolicyService")
local experienceNotificationService = game:GetService("ExperienceNotificationService")
local RunService = game:GetService("RunService")
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
					updateEvent:Fire(if check() then "notifications" else "")
				end)
				task.delay(0.25, function()
					updateEvent:Fire(if check() then "notifications" else "")
				end)
			end,
		},
		{
			name = "playTime",
			taskText = "Play for 5 minutes!",
			execute = function(updateEvent, initialData)
				local timeLeft = (RunService:IsStudio() and 20 or 300) - (os.time() - initialData.timeCreated)
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
