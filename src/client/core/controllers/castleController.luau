local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local castleController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local ReactRoblox = require(game.ReplicatedStorage.sharedPackages.ReactRoblox)
local React = require(game.ReplicatedStorage.sharedPackages.React)
local Sift = require(game.ReplicatedStorage.sharedPackages.Sift)
local Signal = require(game.ReplicatedStorage.sharedPackages.Signal)
local Zone = require(game.ReplicatedStorage.sharedPackages.Zone)

local zap = require(ReplicatedStorage.zap)

local Player = Players.LocalPlayer

local castleFolder = workspace:WaitForChild("castles")
local castleFloor = ReplicatedStorage.assets.castleFloor
local floorHeight = castleFloor.ceiling.Position.Y - castleFloor.floor.Position.Y

local platformConfig = require(ReplicatedStorage.shared.config.platformConfig)

local reactComponents = ReplicatedStorage.client.reactComponents

local platformUI = require(reactComponents.platform)

function castleController.animateFloor(floor)
	local models = {}
	for _, v in pairs(floor:GetDescendants()) do
		if v:IsA("Model") then
			if v:GetAttribute("dir") then
				table.insert(models, v)
			end
			for i, z in pairs(v:GetChildren()) do
				z.Transparency = 1
			end
		else
			if v.Parent == floor or v:IsA("Texture") then
				v.Transparency = 1
				task.delay(1.2, function()
					spr.target(v, 0.8, 2.5, { Transparency = 0 })
				end)
			end
		end
	end

	for _, v in pairs(models) do
		local offset = Vector3.new()
		if v:GetAttribute("dir") == "south" then
			offset = Vector3.new(-35, 0, 0)
		elseif v:GetAttribute("dir") == "north" then
			offset = Vector3.new(35, 0, 0)
		elseif v:GetAttribute("dir") == "east" then
			offset = Vector3.new(0, 0, 35)
		else
			offset = Vector3.new(0, 0, -35)
		end
		for e, z in pairs(v:GetChildren()) do
			local targetCFrame = z.CFrame
			z.CFrame *= CFrame.new(offset)
			task.delay(1, function()
				spr.target(z, 0.8, 2.5, { CFrame = targetCFrame, Transparency = 0 })
			end)
		end
	end
end

function castleController.getFloors(targetPlayer)
	local pstats = targetPlayer:WaitForChild("leaderstats")
	for i, v in pairs(pstats:GetChildren()) do
		if v:GetAttribute("statName") == "floors" then
			return v.Value
		end
	end
end

function castleController.getCannonLevel(targetPlayer)
	local pstats = targetPlayer:WaitForChild("leaderstats")
	for i, v in pairs(pstats:GetChildren()) do
		if v:GetAttribute("statName") == "cannon" then
			return v.Value
		end
	end
end

function castleController.setupPlatform(targetPlatform, callbackSignal, modelUsed)
	local container = ReactRoblox.createRoot(Instance.new("Folder"))
	container:render(ReactRoblox.createPortal(
		React.createElement("BillboardGui", {
			Active = true,
			AlwaysOnTop = true,
			ClipsDescendants = true,
			StudsOffset = Vector3.new(0, 4, 0),
			LightInfluence = 1,
			MaxDistance = 100,
			Size = UDim2.fromScale(12, 6),
			Adornee = targetPlatform,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			ResetOnSpawn = false,
		}, {
			React.createElement(
				platformUI,
				Sift.Dictionary.merge(
					platformConfig[targetPlatform.Name],
					{ name = targetPlatform.Name, callbackSignal = callbackSignal, modelUsed = modelUsed }
				)
			),
		}),
		Players.LocalPlayer.PlayerGui,
		targetPlatform.Name
	))
end

function castleController.updateSpot(spot, newValue, override)
	if math.floor(newValue / 20) == 0 then
		return
	end
	for i = 1, math.floor(newValue / 20) do
		if not spot:FindFirstChildWhichIsA("Model"):FindFirstChild(i) or override then
			local newMiniFloor = ReplicatedStorage.assets.miniFloor:Clone()
			newMiniFloor:PivotTo(spot.CFrame * CFrame.new(0, ((i - 1) * floorHeight * 0.025), 0))
			newMiniFloor.Name = tostring(i)
			newMiniFloor.Parent = spot:FindFirstChildWhichIsA("Model")
		end
	end
end

function castleController.findSpot()
	local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)

	for i, v in pairs(playerPlatform.teleports:GetChildren()) do
		if v.Name == "spot" then
			return v
		end
	end
end

function castleController.updatePrompt(prompt, status)
	if status == 0 then
		prompt.ActionText = "Teleport"
		prompt.ObjectText = "PUBLIC 🌐"
	elseif status == 1 then
		prompt.ActionText = "Teleport"
		prompt.ObjectText = "FRIENDS ONLY 👥"
	else
		prompt.ActionText = "Blocked"
		prompt.ObjectText = "PRIVATE 🔒"
	end
end

local touchZones = {}

function castleController.updateZone(zoneName, targetPart, platform, callbackSignal)
	local touchZone = touchZones[zoneName]
	if touchZone then
		touchZone:Destroy()
		touchZone = nil
	end
	touchZone = Zone.new(targetPart)
	local lastTriggered = 0
	touchZone.partEntered:Connect(function(part)
		if not Players.LocalPlayer.Character then
			return
		end
		if not part:IsDescendantOf(Players.LocalPlayer.Character) then
			return
		end
		if tick() - lastTriggered < 1 then
			return
		end
		lastTriggered = tick()
		platform.callback(callbackSignal)
	end)
end

function castleController.start()
	local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)

	for platformName, platform in pairs(platformConfig) do
		local callbackSignal = Signal.new()
		local newPurchase = ReplicatedStorage.assets.purchasePlatform:Clone()
		castleController.setupPlatform(playerPlatform.platforms:WaitForChild(platformName), callbackSignal, newPurchase)

		task.defer(function()
			local modelFolder = Instance.new("Folder")
			newPurchase.Parent = playerPlatform.platforms
			newPurchase:PivotTo(playerPlatform.platforms:WaitForChild(platformName).CFrame)

			if typeof(platform.initModel) == "Instance" then
				local updateTrove = Trove.new()
				modelFolder.Name = platformName .. "_Model"
				modelFolder.Parent = newPurchase
				updateTrove:AttachToInstance(modelFolder)

				local newModel = platform.initModel:Clone()
				newModel:PivotTo(newPurchase:FindFirstChild("modelPlatform", true).WorldCFrame)
				newModel.Parent = modelFolder
			--Causing Crash
			elseif typeof(platform.initModel) == "function" then
				local updateTrove = Trove.new()
				local updateSignal = Signal.new()
				modelFolder.Name = platformName .. "_Model"
				modelFolder.Parent = newPurchase
				updateTrove:AttachToInstance(modelFolder)

				updateTrove:Add(
					updateSignal:Connect(function(newModel)
						modelFolder:ClearAllChildren()
						newModel:PivotTo(newPurchase:FindFirstChild("modelPlatform", true).WorldCFrame)
						newModel.Parent = modelFolder
					end),
					"Disconnect"
				)

				updateTrove:Add(updateSignal, "Destroy")

				task.defer(function()
					platform.initModel(updateTrove, updateSignal)
				end)
			end

			local touchTrove = Trove.new()
			touchTrove:AttachToInstance(playerPlatform)

			local lastTriggered = 0

			touchTrove:Add(
				playerPlatform.platforms
					:FindFirstChild(platformName)
					:GetPropertyChangedSignal("CFrame")
					:Connect(function()
						newPurchase:PivotTo(playerPlatform.platforms:FindFirstChild(platformName).CFrame)
						castleController.updateZone(
							platformName,
							playerPlatform.platforms:FindFirstChild(platformName),
							platform,
							callbackSignal
						)
					end)
			)

			castleController.updateZone(
				platformName,
				playerPlatform.platforms:FindFirstChild(platformName),
				platform,
				callbackSignal
			)
		end)
	end

	local startingFloors = castleController.getFloors(Player)

	local localPlayerCastle = castleFolder:WaitForChild(Player.Name):FindFirstChildWhichIsA("Folder")

	localPlayerCastle.ChildAdded:Connect(function(child)
		if tonumber(child.Name) > startingFloors then
			castleController.animateFloor(child)
		end
	end)

	local pTrove = Trove.new()
	pTrove:AttachToInstance(playerPlatform)

	local rotateAngle = 0

	pTrove:BindToRenderStep("rotateModels", Enum.RenderPriority.Last.Value + 1, function(dt)
		rotateAngle += 1

		local targetModels = {}
		local targetCFrames = {}
		for _, v in pairs(playerPlatform.platforms:GetChildren()) do
			if v:IsA("Model") and v:FindFirstChildWhichIsA("Folder", true) then
				local model = v:FindFirstChildWhichIsA("Folder", true):FindFirstChildWhichIsA("Model")
				if not model then
					continue
				end
				local targetCFrame = v:FindFirstChild("modelPlatform", true).WorldCFrame

				table.insert(targetModels, model.PrimaryPart)
				table.insert(targetCFrames, targetCFrame * CFrame.Angles(0, math.rad(rotateAngle), 0))
			end
		end
		workspace:BulkMoveTo(targetModels, targetCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end)

	local playerLeaderboard = playerPlatform:FindFirstChild("teleports")

	local playerTroves = {}

	local function playerAdded(player)
		playerTroves[player.Name] = Trove.new()
		local playerSpot = castleController.findSpot()
		playerSpot.Name = player.Name

		local towerModel = Instance.new("Model")
		towerModel.Name = player.Name

		ReplicatedStorage.assets.towerHighlight:Clone().Parent = towerModel

		towerModel.Parent = playerSpot

		for _, v in pairs(player:WaitForChild("leaderstats"):GetChildren()) do
			if v:GetAttribute("statName") == "floors" then
				playerTroves[player.Name]:Add(function()
					v:GetPropertyChangedSignal("Value"):Connect(function()
						castleController.updateSpot(playerSpot, v.Value)
					end)
				end)
				castleController.updateSpot(playerSpot, v.Value)
				playerTroves[player.Name]:Add(playerSpot:GetPropertyChangedSignal("CFrame"):Connect(function()
					castleController.updateSpot(playerSpot, v.Value, true)
				end))
			end
		end

		local towerPrompt = ReplicatedStorage.assets.towerPrompt:Clone()

		local playerCastle = castleFolder:WaitForChild(player.Name):FindFirstChildWhichIsA("Folder")

		towerPrompt.Parent = playerSpot

		playerTroves[player.Name]:Add(playerCastle:GetAttributeChangedSignal("status"):Connect(function()
			castleController.updatePrompt(towerPrompt, playerCastle:GetAttribute("status"))
		end))
		--TODO: Fix prompt updating
		castleController.updatePrompt(towerPrompt, playerCastle:GetAttribute("status"))

		towerPrompt.PromptShown:Connect(function()
			spr.target(towerModel.towerHighlight, 0.9, 3, { OutlineTransparency = 0 })
		end)

		towerPrompt.PromptHidden:Connect(function()
			spr.target(towerModel.towerHighlight, 0.9, 3, { OutlineTransparency = 1 })
		end)

		towerPrompt.Triggered:Connect(function()
			local success = zap.selectPlatform.Call(player)

			if success then
				spr.target(towerModel.towerHighlight, 0.9, 3, { OutlineColor = Color3.new(0.580392, 1, 0.768627) })
			else
				spr.target(towerModel.towerHighlight, 0.9, 3, { OutlineColor = Color3.new(1, 0, 0) })
			end

			task.delay(1, function()
				spr.target(towerModel.towerHighlight, 0.9, 3, { OutlineColor = Color3.new(1, 1, 1) })
			end)
		end)
	end

	Players.PlayerAdded:Connect(playerAdded)

	Players.PlayerRemoving:Connect(function(player)
		playerTroves[player.Name]:Destroy()
		for i, v in pairs(playerPlatform.teleports:GetChildren()) do
			if v.Name == player.Name then
				v.Name = "spot"
				v:ClearAllChildren()
			end
		end
	end)

	for i, v in pairs(Players:GetPlayers()) do
		playerAdded(v)
	end
end

return castleController
