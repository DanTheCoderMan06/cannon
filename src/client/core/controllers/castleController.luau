local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local castleController = {}
local Trove = require(game.ReplicatedStorage.sharedPackages.Trove)
local spr = require(game.ReplicatedStorage.sharedPackages.spr)
local ReactRoblox = require(game.ReplicatedStorage.sharedPackages.ReactRoblox)
local React = require(game.ReplicatedStorage.sharedPackages.React)
local Sift = require(game.ReplicatedStorage.sharedPackages.Sift)
local Signal = require(game.ReplicatedStorage.sharedPackages.Signal)
local Zone = require(game.ReplicatedStorage.sharedPackages.Zone)
local ObjectCache = require(game.ReplicatedStorage.sharedPackages.objectcache)

local enabledPlatforms = {}

local zap = require(ReplicatedStorage.zap)

local Player = Players.LocalPlayer

local castleFolder = workspace:WaitForChild("castles")
local castleFloor = ReplicatedStorage.assets.castleFloor
local floorHeight = 22 -- castleFloor:FindFirstChild("ceiling", true).Position.Y - castleFloor:FindFirstChild("floor", true).Position.Y

local platformConfig = require(ReplicatedStorage.shared.config.platformConfig)

local reactComponents = ReplicatedStorage.client.reactComponents

local dataController = require(ReplicatedStorage.client.controllers.dataController)

local platformUI = require(reactComponents.platform)

function castleController.togglePlatform(platformName, toggle)
	enabledPlatforms[platformName] = toggle
end

function castleController.toggleAllPlatforms(toggle)
	print("[CastleController]: Toggled All Platforms to " .. tostring(toggle))
	for platformName, val in pairs(enabledPlatforms) do
		enabledPlatforms[platformName] = toggle
	end
end

function castleController.animateFloor(floor)
	task.wait(0.4)
	for _, v in pairs(floor.PrimaryPart:GetChildren()) do
		if v:IsA("Weld") then
			local oldC1 = v.C1
			local offset
			if v.Name == "structure" then
				offset = CFrame.new(Vector3.new(-100, 0, -100))
			elseif v.Name == "structure.001" then
				offset = CFrame.new(Vector3.new(100, 0, -100))
			elseif v.Name == "structure.002" then
				offset = CFrame.new(Vector3.new(-100, 0, -100))
			elseif v.Name == "structure.003" then
				offset = CFrame.new(Vector3.new(-100, 0, 100))
			else
				continue
			end
			v.C1 *= offset
			spr.target(v, 1, 2.5, { C1 = oldC1 })
		elseif v:IsA("BasePart") then
			local target = v.Transparency
			v.Transparency = 1
			task.delay(0.2, function()
				spr.target(v, 1, 2.5, { Transparency = target })
			end)
			for _, z in pairs(v:GetChildren()) do
				if z:IsA("Texture") then
					z.Transparency = 1
					task.delay(0.2, function()
						spr.target(z, 1, 2.5, { Transparency = 0 })
					end)
				end
			end
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

function castleController.setupPlatform(targetPlatform, callbackSignal, modelUsed, platformInfo)
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
					platformInfo,
					{ name = targetPlatform.Name, callbackSignal = callbackSignal, modelUsed = modelUsed }
				)
			),
		}),
		Players.LocalPlayer.PlayerGui,
		targetPlatform.Name
	))
end

function castleController.updateSpot(spot, newValue, places, playerFloors)
	local currentValue = 0
	for _, v in pairs(spot:FindFirstChildWhichIsA("Model"):GetChildren()) do
		if v:IsA("Model") and tonumber(v.Name) then
			currentValue += 1
		end
	end
	if newValue > currentValue then
		local parts = {}
		local cframes = {}
		for i = currentValue, newValue do
			if not spot:FindFirstChildWhichIsA("Model"):FindFirstChild(i) then
				local newMiniFloor = ReplicatedStorage.assets.miniFloor:Clone()
				table.insert(parts, newMiniFloor.PrimaryPart)
				table.insert(cframes, spot.CFrame * CFrame.new(0, ((i - 1) * floorHeight * 0.025), 0))
				newMiniFloor.Name = tostring(i)
				newMiniFloor.Parent = spot:FindFirstChildWhichIsA("Model")
			end
		end
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	else
		for i = newValue, currentValue do
			if spot:FindFirstChildWhichIsA("Model"):FindFirstChild(i) then
				spot:FindFirstChildWhichIsA("Model"):FindFirstChild(i):Destroy()
			end
		end
	end
	spot:FindFirstChild("characterModel", true)
		:PivotTo(spot.CFrame * CFrame.new(0, (newValue * floorHeight * 0.025) + 1, 0))
	spot:FindFirstChild("characterModel", true):FindFirstChild("floors", true).Text = playerFloors .. " Floors!"
	if places[1] == spot.Name then
		spot:FindFirstChild("characterModel", true):FindFirstChild("record", true).Text = "🥇1st Place!"
	elseif places[2] == spot.Name then
		spot:FindFirstChild("characterModel", true):FindFirstChild("record", true).Text = "🥈2nd Place!"
	elseif places[3] == spot.Name then
		spot:FindFirstChild("characterModel", true):FindFirstChild("record", true).Text = "🥉3rd Place!"
	else
		spot:FindFirstChild("characterModel", true):FindFirstChild("floors", true).Text = ""
		spot:FindFirstChild("characterModel", true):FindFirstChild("record", true).Text = ""
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
	prompt.ActionText = prompt.Parent.Name
	if status == 0 then
		prompt.ObjectText = "PUBLIC 🌐"
	elseif status == 1 then
		prompt.ObjectText = "FRIENDS ONLY 👥"
	else
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
		if not enabledPlatforms[zoneName] then
			return
		end
		if not Players.LocalPlayer.Character then
			return
		end
		if not part:IsDescendantOf(Players.LocalPlayer.Character) then
			return
		end
		if tick() - lastTriggered < 1 then
			return
		end
		SoundService.effects.click:Play()
		lastTriggered = tick()
		platform.callback(callbackSignal)
	end)
end

local playerTroves = {}

function castleController.updatePlayer(player)
	print(player.Name)
	playerTroves[player.Name] = Trove.new()
	local playerSpot = castleController.findSpot()
	playerSpot.Name = player.Name

	local towerModel = Instance.new("Model")
	towerModel.Name = player.Name

	ReplicatedStorage.assets.towerHighlight:Clone().Parent = towerModel

	towerModel.Parent = playerSpot

	local towerPrompt = ReplicatedStorage.assets.towerPrompt:Clone()

	local playerCastle = castleFolder:WaitForChild(player.Name):FindFirstChildWhichIsA("Model")

	towerPrompt.Parent = playerSpot

	playerTroves[player.Name]:Add(playerCastle:GetAttributeChangedSignal("status"):Connect(function()
		castleController.updatePrompt(towerPrompt, playerCastle:GetAttribute("status"))
	end))

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

	local oldSpotCFrame = playerSpot.CFrame

	playerTroves[player.Name]:Add(playerSpot:GetPropertyChangedSignal("CFrame"):Connect(function()
		local parts = {}
		local cframes = {}
		local delta = playerSpot.Position - oldSpotCFrame.Position
		for _, v in pairs(towerModel:GetChildren()) do
			if not tonumber(v.Name) then
				continue
			end
			table.insert(parts, v.PrimaryPart)
			table.insert(cframes, (v.PrimaryPart.CFrame * CFrame.new(delta)))
		end
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		oldSpotCFrame = playerSpot.CFrame
	end))

	playerTroves[player.Name]:Add(towerPrompt)

	local newRig = ReplicatedStorage.assets.Rig:Clone()
	local newAnim = ReplicatedStorage.assets.animations.dance
		:GetChildren()[math.random(1, #ReplicatedStorage.assets.animations.dance:GetChildren())]
		:Clone()
	newRig.Name = "characterModel"
	newRig.Parent = towerModel

	local s, r = pcall(function()
		local playerHumDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
		newRig:WaitForChild("Humanoid"):ApplyDescription(playerHumDescription)
	end)

	local tries = 0
	while not s and tries < 3 do
		task.wait(1)
		tries += 1
		s, r = pcall(function()
			local playerHumDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
			newRig:WaitForChild("Humanoid"):ApplyDescription(playerHumDescription)
		end)
	end

	task.delay(1, function()
		newRig:ScaleTo(0.01)
	end)

	local track = newRig.Humanoid.Animator:LoadAnimation(newAnim)
	track.Looped = true
	track:Play()
end

function castleController.start()
	local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)

	for platformName, platform in pairs(platformConfig.platforms) do
		enabledPlatforms[platformName] = true

		task.defer(function()
			if platform.checkToLoad then
				local loadEvent = Signal.new()
				platform.checkToLoad(loadEvent)
				loadEvent:Wait()
				loadEvent:Destroy()
			end

			local callbackSignal = Signal.new()
			local newPurchase = ReplicatedStorage.assets.purchasePlatform:Clone()
			castleController.setupPlatform(
				playerPlatform:WaitForChild("platforms"):WaitForChild(platformName),
				callbackSignal,
				newPurchase,
				platform
			)

			local modelFolder = Instance.new("Folder")
			newPurchase:PivotTo(playerPlatform.platforms:WaitForChild(platformName).CFrame)
			newPurchase.Parent = playerPlatform.platforms:WaitForChild(platformName)

			local w = Instance.new("WeldConstraint")
			w.Part0 = newPurchase.Parent
			w.Part1 = newPurchase.PrimaryPart
			w.Parent = newPurchase

			if typeof(platform.initModel) == "Instance" then
				local updateTrove = Trove.new()
				modelFolder.Name = platformName .. "_Model"
				modelFolder.Parent = newPurchase
				updateTrove:AttachToInstance(modelFolder)

				if platform.initModel:IsA("Folder") then
					local newModel = platform.initModel:FindFirstChildWhichIsA("Model"):Clone()
					newModel:ScaleTo(platform.initModel:GetAttribute("miniSize"))
					newModel:PivotTo(newPurchase:FindFirstChild("modelPlatform", true).WorldCFrame)
					newModel.Parent = modelFolder
				else
					local newModel = platform.initModel:Clone()
					newModel:PivotTo(newPurchase:FindFirstChild("modelPlatform", true).WorldCFrame)
					newModel.Parent = modelFolder
				end
			--Causing Crash
			elseif typeof(platform.initModel) == "function" then
				local updateTrove = Trove.new()
				local updateSignal = Signal.new()
				modelFolder.Name = platformName .. "_Model"
				modelFolder.Parent = newPurchase
				updateTrove:AttachToInstance(modelFolder)

				updateTrove:Add(
					updateSignal:Connect(function(recievedModel, newColor, targetScaleUp)
						local newModel
						if recievedModel:IsA("Model") then
							newModel = recievedModel
						else
							newModel = recievedModel:FindFirstChildWhichIsA("Model"):Clone()
							newModel:ScaleTo(recievedModel:GetAttribute("miniSize"))
							modelFolder:ClearAllChildren()
						end
						if newColor ~= nil then
							for _, v in pairs(newModel:GetDescendants()) do
								if v:IsA("BasePart") then
									v.Color = v.Color:Lerp(newColor, 0.9)
									if v:IsA("MeshPart") then
										v.TextureID = ""
									end
								elseif v:IsA("Texture") then
									v.Color3 = v.Color3:Lerp(newColor, 0.9)
								end
							end
						end
						if targetScaleUp then
							newModel:ScaleTo(recievedModel:GetAttribute("miniSize") * targetScaleUp)
						end
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

			task.delay(3, function()
				newPurchase:PivotTo(playerPlatform.platforms:WaitForChild(platformName).CFrame)
			end)

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

	local localPlayerCastle = castleFolder:WaitForChild(Player.Name):FindFirstChildWhichIsA("Model")

	local lastAnimated = 0
	localPlayerCastle:WaitForChild("topFloor").PrimaryPart:GetPropertyChangedSignal("CFrame"):Connect(function()
		if tick() - lastAnimated < 2 then
			return
		end
		lastAnimated = tick()
		castleController.animateFloor(localPlayerCastle:FindFirstChild("topFloor"))
	end)

	local pTrove = Trove.new()
	pTrove:AttachToInstance(playerPlatform)

	local rotateAngle = 0

	local timeStart = tick()

	pTrove:BindToRenderStep("rotateModels", Enum.RenderPriority.Last.Value + 1, function(dt)
		rotateAngle += 0.33

		local targetModels = {}
		local targetCFrames = {}

		for _, v in pairs(playerPlatform.platforms:GetChildren()) do
			if v:IsA("BasePart") and v:FindFirstChildWhichIsA("Folder", true) then
				local model = v:FindFirstChildWhichIsA("Folder", true):FindFirstChildWhichIsA("Model")
				if not model then
					continue
				end
				if not model.PrimaryPart then
					continue
				end
				local targetCFrame = CFrame.new(v.Position + Vector3.new(0, 5, 0))
					* CFrame.Angles(0, math.rad(rotateAngle), 0)
				table.insert(targetModels, model.PrimaryPart)
				table.insert(targetCFrames, targetCFrame)
			end
		end

		workspace:BulkMoveTo(targetModels, targetCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end)

	local playerLeaderboard = playerPlatform:FindFirstChild("teleports")

	local function updateTowers()
		local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
		local teleports = playerPlatform.teleports
		local totalFloors = 0
		local playerStats = {}
		local players = {}
		for _, v in pairs(Players:GetPlayers()) do
			local floorCount
			for e, z in pairs(v:WaitForChild("leaderstats"):GetChildren()) do
				if z:GetAttribute("statName") == "floors" then
					floorCount = z.Value
					break
				end
			end
			playerStats[v.Name] = floorCount
			table.insert(players, v.Name)
			totalFloors += floorCount
		end

		players = Sift.Array.sort(players, function(a, b)
			return playerStats[b] > playerStats[a]
		end)

		for _, v in pairs(Players:GetPlayers()) do
			local totalProportion = playerStats[v.Name] / totalFloors
			local playerSpot = teleports:WaitForChild(v.Name)
			castleController.updateSpot(playerSpot, math.round(totalProportion * 48) + 1, players, playerStats[v.Name])
		end
	end

	--Teleports Service

	Players.PlayerAdded:Connect(function(newPlayer)
		print("Update")
		castleController.updatePlayer(newPlayer)
		updateTowers()
	end)

	Players.PlayerRemoving:Connect(function(playerWhoLeft)
		playerTroves[playerWhoLeft.Name]:Destroy()
		local leftPlayerSpot = playerPlatform.teleports:FindFirstChild(playerWhoLeft.Name)
		leftPlayerSpot.Name = "spot"
		spr.stop(leftPlayerSpot:FindFirstChildWhichIsA("Highlight", true), "OutlineTransparency")
		leftPlayerSpot:ClearAllChildren()
		updateTowers()
	end)

	for i, v in pairs(Players:GetPlayers()) do
		castleController.updatePlayer(v)
	end

	updateTowers()

	--Teleports

	--Auto Claim Cannon
	local playerData = dataController.currentData
	dataController.dataChanged:Connect(function(newData)
		local cannons = Sift.Array.difference(newData.cannons, playerData.cannons)
		print(cannons)
		if #cannons > 0 then
			task.wait()
			platformConfig.changedCannonSignal:Fire(#newData.cannons)
			zap.toggleCannon.Call(newData.cannons[#newData.cannons])
		end
		playerData = newData
	end)
end

return castleController
