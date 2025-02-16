local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local zap = require(ReplicatedStorage.zap)
local spr = require(ReplicatedStorage.sharedPackages.spr)
local Trove = require(ReplicatedStorage.sharedPackages.Trove)

local effectsController = require(ReplicatedStorage.client.controllers.effectsController)

local luckyBlockController = {}

function luckyBlockController.start()
	zap.spawnLuckyBlock.On(function(data)
		local newLuckyBlock = ReplicatedStorage.assets.luckyBlock:Clone()
		local targetCFrame = workspace
			:WaitForChild("playerPlatforms")
			:WaitForChild(Players.LocalPlayer.Name)
			:FindFirstChildWhichIsA("SpawnLocation", true).CFrame
		newLuckyBlock:PivotTo(targetCFrame * CFrame.new(math.random() * 10 - 20, 20, math.random() * 10 - 20))

		local blockTrove = Trove.new()
		local timeStarted = tick()
		local startCFrame = targetCFrame

		local scaleUp = math.clamp(data.reward / 2500000, 1, 6)

		blockTrove:BindToRenderStep("renderLuckyBlock" .. data.id, Enum.RenderPriority.Last.Value, function(dt)
			local currentScale = (tick() - timeStarted) * scaleUp / 6
			newLuckyBlock:ScaleTo(currentScale)
			--[[
			spr.target(newLuckyBlock.PrimaryPart, 0.4, 9, {
				Color = Color3.fromHSV(tick() % 1, 1, 1),
				CFrame = startCFrame
					* CFrame.new(0, currentScale * 10.926 * 0.87 - 2, 0)
					* CFrame.new(math.random() * 2 - 2, 0, math.random() * 2 - 2),
			})
			--]]
		end)
		newLuckyBlock.Parent = workspace
		task.delay(0.2, function()
			newLuckyBlock.PrimaryPart.Anchored = false
		end)

		task.delay(5, function()
			blockTrove:Destroy()
			for _, v in pairs(newLuckyBlock:GetChildren()) do
				if v:IsA("BasePart") then
					spr.target(v, 1, 2, {
						Transparency = 1,
					})
					task.delay(1, function()
						spr.stop(v, "Transparency")
					end)
				end
			end
			print(data.reward)
			effectsController.rewardPopup(newLuckyBlock.PrimaryPart.Position, "+" .. data.reward .. "$")
			task.delay(1.2, function()
				newLuckyBlock:Destroy()
			end)

			zap.claimLuckyBlock.Fire(data)
		end)
	end)
end

return luckyBlockController
