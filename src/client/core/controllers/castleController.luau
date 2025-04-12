local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
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

local animateTrove

function castleController.animateFloor(floor)
	-- Destroying the trove might still be useful for other connections, but let's keep it for now.
	local playerPlatform = workspace:FindFirstChild("playerPlatforms")
		and workspace.playerPlatforms:FindFirstChild(Player.Name)

	if animateTrove then
		animateTrove:Destroy()
		playerPlatform.PrimaryPart.LocalTransparencyModifier = 0
	end
	animateTrove = Trove.new()

	print("[castleController]: Animate Floor!")

	-- Hide the player's character model on the leaderboard during animation
	local playerSpot = castleController.findSpot()
	local charModel = playerSpot and playerSpot:FindFirstChild("characterModel")
	local centerWeld = charModel and charModel:FindFirstChild("centerWeld")
	local originalWeldC0

	if centerWeld then
		originalWeldC0 = centerWeld.C0
		centerWeld.C0 = CFrame.new(0, 10000, 0) -- Move it far away vertically
		animateTrove:Add(function()
			if centerWeld and centerWeld.Parent then -- Check if weld still exists
				centerWeld.C0 = originalWeldC0 -- Restore original position
			end
		end)
	end

	if playerPlatform then
		playerPlatform.PrimaryPart.LocalTransparencyModifier = 1
	end

	for i, v in pairs(floor.PrimaryPart:GetChildren()) do
		if v:IsA("BasePart") then
			-- Use a local trove for each part's animations/connections
			local partTrove = Trove.new()
			animateTrove:Add(partTrove) -- Add part's trove to the main animation trove

			task.spawn(function()
				local originalCFrame = v.CFrame
				local originalTransparency = v.Transparency
				local originalAnchored = v.Anchored -- Store original anchored state

				-- Stop any previous animations managed by spr on this part
				spr.stop(v, "Transparency")
				spr.stop(v, "CFrame")

				-- Stop texture animations too
				for _, z in pairs(v:GetChildren()) do
					if z:IsA("Texture") then
						spr.stop(z, "Transparency")
					end
				end

				-- Set initial state for animation
				v.Transparency = 1
				v.Anchored = true -- Anchor for the animation

				-- Animate transparency for the part
				local transparencyTween = spr.target(v, 1, 1, { Transparency = originalTransparency })
				partTrove:Add(function()
					if transparencyTween and transparencyTween.cancel then
						transparencyTween:cancel()
					end
				end) -- Ensure tween is cancelled if trove is destroyed

				-- Animate transparency for textures
				for _, z in pairs(v:GetChildren()) do
					if z:IsA("Texture") then
						local originalTextureTransparency = z.Transparency
						z.Transparency = 1
						local textureTween = spr.target(z, 1, 1, { Transparency = originalTextureTransparency })
						partTrove:Add(function()
							if textureTween and textureTween.cancel then
								textureTween:cancel()
							end
						end)
					end
				end

				-- Calculate offset and set initial CFrame
				local offset = CFrame.new(
					Vector3.new(math.random(-100, 100), math.random(-100, 0), math.random(-100, 100))
				) * CFrame.Angles(
					math.random() * 2 * math.pi,
					math.random() * 2 * math.pi,
					math.random() * 2 * math.pi
				)
				v.CFrame = originalCFrame * offset -- Apply offset relative to original CFrame

				-- Animate CFrame back to original position
				local cframeTween = spr.target(v, 1, 1, { CFrame = originalCFrame })
				partTrove:Add(function()
					if cframeTween and cframeTween.cancel then
						cframeTween:cancel()
					end
				end)

				-- Use Tween.Completed to reset anchored state
				-- Note: spr might not directly expose the underlying Tween object or a reliable completion signal easily.
				-- A simple delay might be the most practical approach, but shorter than 2s.
				-- Let's try task.delay matching the tween duration (1 second).
				task.delay(1.1, function() -- Add a small buffer
					-- Check if the part still exists and if the trove hasn't been destroyed prematurely
					if v and v.Parent and partTrove then
						v.Anchored = originalAnchored -- Restore original anchored state
						playerPlatform.PrimaryPart.LocalTransparencyModifier = 0
						-- No need to stop tweens here as they should have completed.
					end
				end)

				-- The partTrove will automatically clean up the cancel functions if animateTrove is destroyed early.
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

function castleController.setupPlatform(targetPlatform, callbackSignal, modelUsed, platformInfo)
	local container = ReactRoblox.createRoot(Instance.new("Folder"))

	local targetHover = platformConfig.defaultHoverDistance

	if platformConfig[targetPlatform.Name] then
		targetHover = platformConfig[targetPlatform.Name].hoverDistance
	end

	container:render(ReactRoblox.createPortal(
		React.createElement("BillboardGui", {
			Active = true,
			AlwaysOnTop = true,
			ClipsDescendants = true,
			StudsOffset = Vector3.new(0, targetHover + platformConfig.uiHoverDistance, 0),
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
				local weld = Instance.new("Weld")
				local newMiniFloor = ReplicatedStorage.assets.miniFloorTeleport:Clone()
				table.insert(parts, newMiniFloor.PrimaryPart)
				weld.C0 = CFrame.new(0, ((i - 1) * floorHeight * 0.025) + 1.1, 0)
				newMiniFloor.Name = tostring(i)
				newMiniFloor.Parent = spot:FindFirstChildWhichIsA("Model")
				weld.Part0 = spot
				weld.Part1 = newMiniFloor.PrimaryPart
				weld.Parent = newMiniFloor
			end
		end
	else
		for i = newValue, currentValue do
			if spot:FindFirstChildWhichIsA("Model"):FindFirstChild(i) then
				spot:FindFirstChildWhichIsA("Model"):FindFirstChild(i):Destroy()
			end
		end
	end

	print(spot:FindFirstChild("characterModel", true):FindFirstChild("centerWeld"))
	if not spot:FindFirstChild("characterModel", true):FindFirstChild("centerWeld") then
		local weld = Instance.new("Weld")
		weld.Name = "centerWeld"
		weld.Part0 = spot
		weld.Part1 = spot:FindFirstChild("characterModel", true).PrimaryPart
		weld.Parent = spot:FindFirstChild("characterModel", true)
	end

	spot:FindFirstChild("characterModel", true):FindFirstChild("centerWeld").C0 =
		CFrame.new(0, (newValue * floorHeight * 0.025) + 1.6, 0) -- Lowered offset from 2.1 to 0.9
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
		SoundService.effects.click:Play()
		if success then
			spr.target(towerModel.towerHighlight, 0.9, 3, { OutlineColor = Color3.new(0.580392, 1, 0.768627) })
		else
			spr.target(towerModel.towerHighlight, 0.9, 3, { OutlineColor = Color3.new(1, 0, 0) })
		end

		task.delay(1, function()
			spr.target(towerModel.towerHighlight, 0.9, 3, { OutlineColor = Color3.new(1, 1, 1) })
		end)
	end)

	playerTroves[player.Name]:Add(towerPrompt)

	local newRig = ReplicatedStorage.assets.Rig:Clone()
	newRig.PrimaryPart.Anchored = false
	local newAnim = ReplicatedStorage.assets.animations.dance
		:GetChildren()[math.random(1, #ReplicatedStorage.assets.animations.dance:GetChildren())]
		:Clone()
	newRig.Name = "characterModel"
	newRig.Parent = towerModel

	local targetUserId = player.UserId
	if targetUserId <= 0 then
		targetUserId = 1 -- Default to Roblox's UserId if the player's UserId is invalid
	end

	local s, r = pcall(function()
		local playerHumDescription = Players:GetHumanoidDescriptionFromUserId(targetUserId)
		newRig:WaitForChild("Humanoid"):ApplyDescription(playerHumDescription)
	end)

	local tries = 0
	while not s and tries < 3 do
		task.wait(1)
		tries += 1
		s, r = pcall(function()
			-- Use the same targetUserId logic in the retry attempt
			local playerHumDescription = Players:GetHumanoidDescriptionFromUserId(targetUserId)
			newRig:WaitForChild("Humanoid"):ApplyDescription(playerHumDescription)
		end)
	end

	task.delay(1, function()
		newRig:ScaleTo(0.01)
	end)

	local track = newRig.Humanoid.Animator:LoadAnimation(newAnim)
	track.Priority = Enum.AnimationPriority.Action4
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
						end
						newModel.Parent = workspace
						ContentProvider:PreloadAsync(newModel:GetDescendants())
						task.wait(0.2)
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

	local oldFloors = dataController.getData().floors
	dataController.dataChanged:Connect(function(newData)
		if newData.floors == oldFloors then
			return
		end
		task.wait()
		local playerSpot = workspace.castles:WaitForChild(Player.Name)
		localPlayerCastle
			:FindFirstChild("topFloor")
			:PivotTo(playerSpot.CFrame * CFrame.new(0, floorHeight * (newData.floors + 0.5) + 6, 0))
		castleController.animateFloor(localPlayerCastle:FindFirstChild("topFloor"))
		oldFloors = newData.floors
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
				local targetHover = platformConfig.defaultHoverDistance
				if platformConfig.platforms[v.Name] then
					targetHover = platformConfig.platforms[v.Name].hoverDistance or targetHover
				end
				local targetCFrame = CFrame.new(v.Position + Vector3.new(0, targetHover, 0))
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
			return playerStats[b] < playerStats[a]
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

	-- Start periodic tower update loop
	task.spawn(function()
		while true do
			task.wait(60)
			pcall(updateTowers) -- Use pcall to prevent errors in updateTowers from stopping the loop
		end
	end)

	--Teleports

	--Auto Claim Cannon
	local dataStart = tick()
	local playerData = dataController.currentData
	dataController.dataChanged:Connect(function(newData)
		local cannons = Sift.Array.difference(newData.cannons, playerData.cannons)
		print(cannons)
		if #cannons > 0 and tick() - dataStart > 5 then
			task.wait()
			platformConfig.changedCannonSignal:Fire(#newData.cannons)
			zap.toggleCannon.Call(newData.cannons[#newData.cannons])
		end
		playerData = newData
	end)
end

return castleController
