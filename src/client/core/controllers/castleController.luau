local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
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
local objectcache = require(game.ReplicatedStorage.sharedPackages.objectcache)

local floorStorage = Instance.new("Folder")
floorStorage.Name = "floors"
floorStorage.Parent = game.ReplicatedFirst

local enabledPlatforms = {}

local zap = require(ReplicatedStorage.zap)

local Player = Players.LocalPlayer

local castleFolder = workspace:WaitForChild("castles")
local castleFloor = ReplicatedStorage.assets.playerCastleAssets.castleFloor
local floorHeight = 22 -- castleFloor:FindFirstChild("ceiling", true).Position.Y - castleFloor:FindFirstChild("floor", true).Position.Y
local MAX_TEXTURE_DISTANCE = 1024

local platformConfig = require(ReplicatedStorage.shared.config.platformConfig)

local reactComponents = ReplicatedStorage.client.reactComponents

local dataController = require(ReplicatedStorage.client.controllers.dataController)

local platformUI = require(reactComponents.platform)

function castleController.togglePlatform(platformName, toggle)
	enabledPlatforms[platformName] = toggle
end

function castleController.toggleAllPlatforms(toggle)
	require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
		"[CastleController]: Toggled All Platforms to " .. tostring(toggle)
	)
	for platformName, val in pairs(enabledPlatforms) do
		enabledPlatforms[platformName] = toggle
	end
end

function castleController.animateFloor(floor)
	-- Destroying the trove might still be useful for other connections, but let's keep it for now.
	local playerPlatform = workspace:FindFirstChild("playerPlatforms")
		and workspace.playerPlatforms:FindFirstChild(Player.Name)

	require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log("[castleController]: Animate Floor!")

	if floor:FindFirstChild("blockSight", true) then
		floor:FindFirstChild("blockSight", true):Destroy()
	end

	-- Hide the player's character model on the leaderboard during animation
	local playerSpot = castleController.findSpot()
	local charModel = playerSpot and playerSpot:FindFirstChild("characterModel")
	local centerWeld = charModel and charModel:FindFirstChild("centerWeld")
	local originalWeldC0

	if centerWeld then
		originalWeldC0 = centerWeld.C0
		centerWeld.C0 = CFrame.new(0, 10000, 0) -- Move it far away vertically
	end

	for i, v in pairs(floor.PrimaryPart:GetChildren()) do
		if v:IsA("BasePart") then
			-- Use a local trove for each part's animations/connections
			local partTrove = Trove.new()

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
				Debris:AddItem(floor, 1.1)

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

function castleController.setupPlatform(targetPlatform, callbackSignal, modelUsed, platformInfo, hideEvent)
	local container = ReactRoblox.createRoot(Instance.new("Folder"))

	local targetHover = platformConfig.defaultHoverDistance

	if platformConfig.platforms[targetPlatform.Name] then
		--targetHover = platformConfig.platforms[targetPlatform.Name].hoverDistance or targetHover
	end
	local enabled, setEnabled = React.createBinding(true)
	if hideEvent then
		hideEvent:Connect(function(toggle)
			setEnabled(toggle)
		end)
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
			Enabled = enabled,
		}, {
			React.createElement(
				platformUI,
				Sift.Dictionary.merge(platformInfo, {
					name = targetPlatform.Name,
					callbackSignal = callbackSignal,
					modelUsed = modelUsed,
					targetColor = platformConfig.platforms[targetPlatform.Name].targetColor,
				})
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
				local newMiniFloor = ReplicatedStorage.assets.playerCastleAssets.miniFloorTeleport:Clone()
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

	require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
		spot:FindFirstChild("characterModel", true):FindFirstChild("centerWeld")
	)
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

local platformConnections = {} -- Store connections to manage them if needed

function castleController.updateZone(zoneName, targetPart, platform, callbackSignal)
	-- require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(zoneName .. " UPDATE") -- Optional: Keep for debugging

	-- Disconnect previous connection if it exists for this zoneName
	if platformConnections[zoneName] then
		platformConnections[zoneName]:Disconnect()
		platformConnections[zoneName] = nil
	end

	local lastTriggered = 0
	platformConnections[zoneName] = targetPart.Touched:Connect(function(part)
		if not enabledPlatforms[zoneName] then
			return
		end
		if not Players.LocalPlayer.Character then
			return
		end
		if not part:IsDescendantOf(Players.LocalPlayer.Character) then
			return
		end
		-- Debounce check
		if tick() - lastTriggered < 1 then
			return
		end
		SoundService.effects.click:Play()
		lastTriggered = tick()
		platform.callback(callbackSignal)
	end)
	-- Note: Consider adding this connection to a Trove associated with the platform
	-- if the platform or targetPart can be destroyed, to ensure cleanup.
end

local playerTroves = {}

function castleController.updatePlayer(player)
	playerTroves[player.Name] = Trove.new()
	local playerSpot = castleController.findSpot()
	playerSpot.Name = player.Name

	local towerModel = Instance.new("Model")
	towerModel.Name = player.Name

	ReplicatedStorage.assets.playerCastleAssets.towerHighlight:Clone().Parent = towerModel

	towerModel.Parent = playerSpot

	local towerPrompt = ReplicatedStorage.assets.playerCastleAssets.towerPrompt:Clone()

	local playerCastle = castleFolder:WaitForChild(player.Name):FindFirstChildWhichIsA("Model")

	towerPrompt.Parent = playerSpot

	playerTroves[player.Name]:Add(playerCastle:GetAttributeChangedSignal("status"):Connect(function()
		castleController.updatePrompt(towerPrompt, playerCastle:GetAttribute("status"))
	end))

	castleController.updatePrompt(towerPrompt, playerCastle:GetAttribute("status"))

	towerPrompt.PromptShown:Connect(function()
		if not towerModel:FindFirstChild("towerHighlight") then
			return
		end
		spr.target(towerModel.towerHighlight, 0.9, 3, { OutlineTransparency = 0 })
	end)

	towerPrompt.PromptHidden:Connect(function()
		if not towerModel:FindFirstChild("towerHighlight") then
			return
		end
		spr.target(towerModel.towerHighlight, 0.9, 3, { OutlineTransparency = 1 })
	end)

	towerPrompt.Triggered:Connect(function()
		local success = zap.selectPlatform.Call(player)
		SoundService.effects.click:Play()
		if not towerModel:FindFirstChild("towerHighlight") then
			return
		end
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

local function changeTransparency(item, toOne)
	if item:IsA("BasePart") then
		item.LocalTransparencyModifier = toOne and 1 or 0
	end
	for _, v in pairs(item:GetDescendants()) do
		if not v:IsA("BasePart") and not v:IsA("Texture") then
			continue
		end
		if v:IsA("BasePart") then
			v.LocalTransparencyModifier = toOne and 1 or 0
		else
			v.Transparency = toOne and 1 or 0
		end
	end
end

local clientTopFloor

local function updateTopFloor()
	local playerSpot = workspace.castles:WaitForChild(Player.Name)
	local playerPlatform = workspace.playerPlatforms:WaitForChild(Player.Name)
	if not clientTopFloor then
		clientTopFloor = ReplicatedStorage.assets.playerCastleAssets.topFloor:Clone()
		clientTopFloor.Parent = workspace
	end
	if
		playerPlatform:GetAttribute("currentTower") == Player.Name or not playerPlatform:GetAttribute("currentTower")
	then
		local newData = dataController.getData()
		clientTopFloor:PivotTo(playerSpot.CFrame * CFrame.new(0, floorHeight * (newData.floors + 0.5) + 6, 0))
	else
		local otherPlayer = Players:FindFirstChild(playerPlatform:GetAttribute("currentTower"))
		if not otherPlayer then -- Error ??
			local newData = dataController.getData()
			clientTopFloor:PivotTo(playerSpot.CFrame * CFrame.new(0, floorHeight * (newData.floors + 0.5) + 6, 0))
			return
		end
		local otherPlayerSpot = workspace.castles:WaitForChild(otherPlayer.Name)
		local otherPlayerFloors = 0
		for _, v in pairs(otherPlayer:WaitForChild("leaderstats"):GetChildren()) do
			if v:GetAttribute("statName") == "floors" then
				otherPlayerFloors = v.Value
			end
		end
		clientTopFloor:PivotTo(otherPlayerSpot.CFrame * CFrame.new(0, floorHeight * (otherPlayerFloors + 0.5) + 6, 0))
	end
end

function castleController.start()
	updateTopFloor()

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
			local newPurchase = ReplicatedStorage.assets.playerCastleAssets.purchasePlatform:Clone()

			local hideEvent

			if platform.checkToHide then
				hideEvent = Signal.new()
				platform.checkToHide(hideEvent)
			end

			castleController.setupPlatform(
				playerPlatform:WaitForChild("platforms"):WaitForChild(platformName),
				callbackSignal,
				newPurchase,
				platform,
				hideEvent
			)

			local modelFolder = Instance.new("Folder")
			for _, v in pairs(newPurchase:GetChildren()) do
				if v == newPurchase.PrimaryPart then
					continue
				end
				v.Color = platform.targetColor
			end

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

			if hideEvent then
				hideEvent:Connect(function(toggle)
					for _, v in pairs(newPurchase:GetDescendants()) do
						if v:IsA("BasePart") then
							v.Transparency = toggle and 0 or 1
						elseif v:IsA("Texture") then
							v.Transparency = toggle and 0.6 or 1
						end
					end
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
	changeTransparency(localPlayerCastle:FindFirstChild("topFloor", true), 1)
	local lastAnimated = 0
	local oldFloors = dataController.getData().floors
	dataController.dataChanged:Connect(function(newData)
		if newData.floors == oldFloors then
			return
		end
		if tick() - lastAnimated < 0.4 then
			return
		end
		oldFloors = newData.floors
		if playerPlatform:GetAttribute("currentTower") ~= Player.Name then
			return
		end
		lastAnimated = tick()
		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log("[CastleController] Update Floors")
		task.wait()
		local playerSpot = workspace.castles:WaitForChild(Player.Name)
		updateTopFloor()
		local newTopFloor = clientTopFloor:Clone()
		newTopFloor.Name = "TempAnim"
		newTopFloor.Parent = workspace
		pcall(function()
			castleController.animateFloor(newTopFloor)
		end)
		changeTransparency(clientTopFloor, true)
		task.delay(1.1, function()
			if newTopFloor then
				newTopFloor:Destroy()
			end
			require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log("reset to 0")
			changeTransparency(clientTopFloor, false)
		end)
	end)

	playerPlatform.PrimaryPart:GetPropertyChangedSignal("Position"):Connect(function()
		updateTopFloor()
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
			castleController.updateSpot(playerSpot, math.round(totalProportion * 24) + 1, players, playerStats[v.Name])
		end
	end

	--Teleports Service

	Players.PlayerAdded:Connect(function(newPlayer)
		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log("Update")
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
		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(cannons)
		if #cannons > 0 and tick() - dataStart > 5 then
			task.wait()
			zap.toggleCannon.Call(newData.cannons[#newData.cannons])
			platformConfig.changedCannonSignal:Fire(#newData.cannons)
		end
		playerData = newData
	end)

	local playerPlatforms = workspace:WaitForChild("playerPlatforms")
	playerPlatforms.ChildAdded:Connect(function(child)
		if child.Name == Players.LocalPlayer.Name then
			return
		end
		if child:IsA("Model") then
			child:Destroy()
		end
	end)
	for _, v in pairs(playerPlatforms:GetChildren()) do
		if v.Name == Players.LocalPlayer.Name then
			continue
		end
		v:Destroy()
	end

	local floors = objectcache.new({ Template = castleFloor, CacheParent = floorStorage })

	local CHUNK_SIZE = 10

	--Attempt at kitbashing.
	local function castleUpdates(targetPlayer)
		local playerSpot = castleFolder:FindFirstChild(targetPlayer.Name)
		local playerCastle = playerSpot:FindFirstChildWhichIsA("Model")

		local totalFloorsObject = targetPlayer:WaitForChild("leaderstats"):FindFirstChild("Floors 🏢")
			or targetPlayer:WaitForChild("leaderstats"):FindFirstChild("Floors") -- Handle potential name variations
		if not totalFloorsObject then
			warn("Could not find Floors stat for player: " .. targetPlayer.Name)
			return
		end

		local FLOORS_PER_PART = 90
		local BASE_FLOOR_HEIGHT = 22 -- Extracted from original scaling logic
		local TOP_FLOOR_COUNT = 2 -- How many floors at the top use the special model
		local topFloorModelTemplate = ReplicatedStorage.assets.playerCastleAssets.castleFloor

		local function runUpdate()
			--[[
			task.spawn(function() -- This old logic seems to be for individual floor models, keeping commented out
				local currentFloor = totalFloors - 1
				while currentFloor >= 0 do
					for i = 1, CHUNK_SIZE do
						if currentFloor < 0 then
							break
						end
						if not playerCastle:FindFirstChild(tostring(currentFloor)) then
							if #floors._FreeObjects < i then
								floors:ExpandCache(50)
							end
							local newFloor = floors:Get(
								playerSpot.CFrame * CFrame.new(0, floorHeight * (currentFloor + 0.5) + 7.563, 0)
							)
							newFloor.Name = tostring(currentFloor)
							newFloor.Parent = playerCastle
						end
						currentFloor = currentFloor - 1
					end
					task.wait()
				end
			end)
			--]]
			local totalFloors = totalFloorsObject.Value
			local floorsForSegments = math.max(0, totalFloors - TOP_FLOOR_COUNT)
			local numPartsNeeded = math.max(0, math.ceil(floorsForSegments / FLOORS_PER_PART)) -- Calculate parts needed ONLY for floors below the top ones
			local segmentedHeight = floorsForSegments * BASE_FLOOR_HEIGHT -- Total height of the segmented parts section

			-- 1. Create/Update necessary segmented parts (below the top floors)
			for i = 1, numPartsNeeded do
				local partName = "castlePart_" .. i
				local castlePart = playerCastle:FindFirstChild(partName)

				-- Ensure the part exists and has the attribute for optimization later
				if not castlePart then
					castlePart = ReplicatedStorage.assets.playerCastleAssets.castleFloorLerp:Clone()
					castlePart:SetAttribute("isCastlePart", true)
					castlePart.Name = partName
					castlePart.Parent = playerCastle
				end

				-- Calculate floors for *this specific segment* based on remaining floorsForSegments
				local floorsInThisPart = math.min(FLOORS_PER_PART, floorsForSegments - (i - 1) * FLOORS_PER_PART)

				if floorsInThisPart <= 0 then -- This segment is no longer needed (e.g., floors decreased)
					if castlePart then -- Destroy if it exists
						castlePart:Destroy()
					end
					continue
				end

				local sizeY = BASE_FLOOR_HEIGHT * floorsInThisPart
				local size = Vector3.new(80.822, math.max(0.01, sizeY), 80.822) -- Ensure size is not exactly zero to avoid issues

				local previousPartsHeight = (i - 1) * FLOORS_PER_PART * BASE_FLOOR_HEIGHT
				local positionY = previousPartsHeight + (sizeY / 2) -- Center of this part, relative to base
				local position = playerSpot.Position + Vector3.new(0, positionY, 0)

				if castlePart.PrimaryPart then
					castlePart.PrimaryPart.Size = size
					castlePart.PrimaryPart.Position = position
				else
					warn("Castle part " .. partName .. " missing PrimaryPart!")
				end
			end

			-- 2. Remove extra segmented parts if floorsForSegments decreased
			local currentPartIndex = numPartsNeeded + 1 -- Start checking from the part after the last needed one
			while true do
				local partName = "castlePart_" .. currentPartIndex
				local extraPart = playerCastle:FindFirstChild(partName)
				if extraPart then
					extraPart:Destroy()
					currentPartIndex = currentPartIndex + 1
				else
					break -- No more extra parts found
				end
			end

			-- 3. Handle the top two special floors
			local topFloor1 = playerCastle:FindFirstChild("topFloor_1") -- The very top floor
			local topFloor2 = playerCastle:FindFirstChild("topFloor_2") -- The one below the top

			-- Top Floor (Floor N)
			if totalFloors >= 1 then
				if not topFloor1 then
					topFloor1 = topFloorModelTemplate:Clone()
					topFloor1.Name = "topFloor_1"
					topFloor1.Parent = playerCastle
				end
				-- Position based on the center of the Nth floor
				local targetPos1 = playerSpot.Position + Vector3.new(0, (totalFloors - 0.5) * BASE_FLOOR_HEIGHT + 7, 0)
				topFloor1:PivotTo(
					CFrame.new(targetPos1)
						* CFrame.Angles(0, 0, math.rad(-0))
						* CFrame.Angles(math.rad(-90), math.rad(180), 0)
				)
			else
				if topFloor1 then
					topFloor1:Destroy()
				end
			end

			-- Second Top Floor (Floor N-1)
			if totalFloors >= 2 then
				if not topFloor2 then
					topFloor2 = topFloorModelTemplate:Clone()
					topFloor2.Name = "topFloor_2"
					topFloor2.Parent = playerCastle
				end
				-- Position based on the center of the (N-1)th floor
				local targetPos2 = playerSpot.Position + Vector3.new(0, (totalFloors - 1.5) * BASE_FLOOR_HEIGHT + 7, 0)
				topFloor2:PivotTo(
					CFrame.new(targetPos2)
						* CFrame.Angles(0, 0, math.rad(-0))
						* CFrame.Angles(math.rad(-90), math.rad(180), 0)
				)
			else
				if topFloor2 then
					topFloor2:Destroy()
				end
			end
		end

		totalFloorsObject:GetPropertyChangedSignal("Value"):Connect(function()
			runUpdate()
		end)

		totalFloorsObject.Destroying:Connect(function()
			for _, v in pairs(playerCastle:GetChildren()) do
				if v:IsA("Model") then
					floors:Return(v)
				end
			end
		end)

		runUpdate()
	end

	for _, v in pairs(Players:GetPlayers()) do
		castleUpdates(v)
	end

	Players.PlayerAdded:Connect(castleUpdates)

	task.spawn(function()
		while true do
			task.wait(1)
			local char = Players.LocalPlayer.Character
			if not char then
				continue
			end
			if not char.PrimaryPart then
				continue
			end
			for _, v in pairs(castleFolder:GetDescendants()) do
				if not v:GetAttribute("isCastlePart") then
					continue
				end
				local isTooFar = (char.PrimaryPart.Position - v.PrimaryPart.Position).Magnitude > MAX_TEXTURE_DISTANCE
				for e, z in pairs(v:GetChildren()) do
					if z:IsA("Texture") then
						z.Transparency = isTooFar and 1 or 0.6
					end
				end
			end
		end
	end)
end

return castleController
