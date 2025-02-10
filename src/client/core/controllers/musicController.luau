local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TextChatService = game:GetService("TextChatService")

local musicController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local Signal = require(ReplicatedStorage.sharedPackages.Signal)

musicController.toggleMusicEvent = Signal.new()

local targetVolume = 1

function musicController.toggle(toggle: boolean)
	targetVolume = toggle and 1 or 0
	SoundService.music.Volume = targetVolume * 0.5
end

function musicController.start()
	task.spawn(function()
		while true do
			for _, v in pairs(SoundService.music:GetChildren()) do
				v:Play()
				v.Ended:Wait()
			end
			task.wait()
		end
	end)
	musicController.toggleMusicEvent:Connect(musicController.toggle)
end

return musicController
