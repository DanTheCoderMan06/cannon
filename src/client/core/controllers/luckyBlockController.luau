local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local growingSound = SoundService.effects:WaitForChild("growing") -- Get the growing sound

local zap = require(ReplicatedStorage.zap)
local spr = require(ReplicatedStorage.sharedPackages.spr)
local Trove = require(ReplicatedStorage.sharedPackages.Trove)

local effectsController = require(ReplicatedStorage.client.controllers.effectsController)

local reactUtil = require(ReplicatedStorage.shared.utilities.reactUtil)

local luckyBlockController = {}

function luckyBlockController.start()
	zap.spawnLuckyBlock.On(function(data)
		-- Correctly find the player's platform model
		local playerPlatformModel = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
		-- Clone the lucky block template from ReplicatedStorage
		local newLuckyBlock = ReplicatedStorage.assets:WaitForChild("luckyBlock"):Clone()
		-- Find the specific block spawn part
		local blockSpawnPart = playerPlatformModel:FindFirstChild("blockSpawn", true)
		if not blockSpawnPart then
			warn("Could not find 'blockSpawn' part for player", Players.LocalPlayer.Name)
			-- Fallback to spawn location if blockSpawn doesn't exist
			blockSpawnPart = playerPlatformModel:FindFirstChildWhichIsA("SpawnLocation", true)
		end

		-- Calculate random position within the blockSpawnPart bounds
		local spawnCFrame = blockSpawnPart.CFrame
		local spawnSize = blockSpawnPart.Size
		local randomOffsetX = (math.random() - 0.5) * spawnSize.X
		local randomOffsetY = (math.random() - 0.5) * spawnSize.Y
		local randomOffsetZ = (math.random() - 0.5) * spawnSize.Z
		local randomLocalPosition = Vector3.new(randomOffsetX, randomOffsetY, randomOffsetZ)
		local finalWorldCFrame = spawnCFrame * CFrame.new(randomLocalPosition)

		newLuckyBlock:PivotTo(finalWorldCFrame)

		-- Prepare and play the growing sound
		growingSound.PlaybackSpeed = growingSound.TimeLength / 5 -- Scale speed to match 5s duration
		growingSound:Play()

		local blockTrove = Trove.new()
		local timeStarted = tick()

		local scaleUp = math.clamp(data.reward / 5500000, 1, 3)

		blockTrove:BindToRenderStep("renderLuckyBlock" .. data.id, Enum.RenderPriority.Last.Value, function(dt)
			local currentScale = (tick() - timeStarted) * scaleUp / 6
			newLuckyBlock:ScaleTo(currentScale)
			spr.target(newLuckyBlock.PrimaryPart, 0.4, 9, {
				Color = Color3.fromHSV(tick() % 1, 1, 1),
			})
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
			effectsController.rewardPopup(
				newLuckyBlock.PrimaryPart.Position,
				"+ $" .. reactUtil.formatNumber(data.reward)
			) -- Fixed $ placement
			growingSound:Stop() -- Stop the growing sound
			SoundService.effects.claim:Play()
			task.delay(1.2, function()
				newLuckyBlock:Destroy()
			end)

			zap.claimLuckyBlock.Fire(data)
		end)
	end)
end

return luckyBlockController
