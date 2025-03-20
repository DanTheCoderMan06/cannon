local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")
local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local boughtLevels = 0
local cannonIndex = 0

local dataController = require(ReplicatedStorage.client.controllers.dataController)
local uiController = require(ReplicatedStorage.client.controllers.uiController)

local zap = require(ReplicatedStorage.zap)

local spr = require(ReplicatedStorage.sharedPackages.spr)
local Signal = require(ReplicatedStorage.sharedPackages.Signal)

local gamepassConfig = require(ReplicatedStorage.shared.config.gamepassConfig)
local floorConfig = require(ReplicatedStorage.shared.config.floorConfig)
local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)
local tierConfig = require(ReplicatedStorage.shared.config.tierConfig)
local giftConfig = require(ReplicatedStorage.shared.config.giftConfig)

local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)
local reactUtil = require(ReplicatedStorage.shared.utilities.reactUtil)

local startTimeLuckyBlock = tick()

local changedCannonSignal = Signal.new()

return {
	cannonIndex = 1,
	changedCannonSignal = changedCannonSignal,
	platforms = {
		luckyBlock = {
			callback = function(callbackEvent)
				local success = zap.requestLuckyBlock.Call()
				callbackEvent:Fire(success)
			end,
			title = "LUCKY BLOCK!",
			description = "00:00",
			updateValues = function(trove, updateEvent)
				zap.spawnLuckyBlock.On(function()
					startTimeLuckyBlock = tick()
				end)
				trove:BindToRenderStep("renderTimeLuckyBlock", Enum.RenderPriority.Last.Value + 1, function()
					local timeLeft = math.floor(
						math.clamp(
							rewardsConfig.luckyBlockWaitTime - (tick() - startTimeLuckyBlock),
							-10,
							rewardsConfig.luckyBlockWaitTime
						)
					)

					updateEvent:Fire({
						title = timeLeft > 0 and reactUtil.secondsToMMSS(timeLeft) or "READY!",
						description = "UNTIL REWARD",
					})

					if timeLeft == -10 then
						local success = zap.requestLuckyBlock.Call()
					end
				end)
			end,
			init = function()
				return {
					title = "Loading...",
					description = "UNTIL REWARD",
				}
			end,
			initModel = ReplicatedStorage.assets:WaitForChild("luckyBlock"),
			callbackFunction = function(success, states)
				if success then
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0.992156, 1, 0.580392) })
				else
					local luckyBlockId = gamepassConfig.luckyBlockSkip.getId(dataController.getData())
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, luckyBlockId)
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(1, 0, 0) })
				end

				task.delay(1, function()
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0, 1, 81 / 255) })
				end)
			end,
		},
		tasks = {
			callback = function(callbackEvent)
				local success = false
				if uiController.canPromptIn() then
					uiController.promptOptIn()
					success = uiController.promptInEvent:Wait()
				else
					local s, r = pcall(function()
						SocialService:PromptGameInvite(Players.LocalPlayer)
					end)
					success = s
				end
				callbackEvent:Fire(success)
			end,
			title = "1M+ REWARD!",
			description = "ENABLE NOTIFICATIONS",
			updateValues = function(trove, updateEvent)
				uiController.promptInEvent:Connect(function(success)
					print(success)
					if success then
						updateEvent:Fire({
							title = "1M+ REWARD!",
							description = "INVITE A NEW PLAYER",
						})
					end
				end)
			end,
			init = function()
				local canPromptIn = uiController.canPromptIn()
				return {
					title = "1M+ REWARD!",
					description = canPromptIn and "ENABLE NOTIFICATIONS" or "INVITE A NEW PLAYER",
				}
			end,
			initModel = ReplicatedStorage.assets:FindFirstChild("rewardSuitcase"),
			callbackFunction = function(success, states)
				if success then
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0.992156, 1, 0.580392) })
				else
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(1, 0, 0) })
				end

				task.delay(1, function()
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0, 1, 81 / 255) })
				end)
			end,
		},
		cannon = {
			callback = function(callbackEvent)
				local success = zap.purchaseUpgrade.Call("cannon")
				callbackEvent:Fire(success)
			end,
			title = "UPGRADE CANNON",
			description = "N/A",
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.currentData
				local cannonValue
				for _, v in pairs(stats:GetChildren()) do
					if v:GetAttribute("statName") ~= "cannon" then
						continue
					end
					cannonValue = v
					trove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
						updateEvent:Fire({
							title = "LEVEL " .. tostring(v.Value),
							description = tostring(cannonConfig.costFormula(v.Value + 1, playerData.boughtLevels))
								.. "$",
						})
					end))
				end
				trove:Add(dataController.dataChanged:Connect(function(newdata)
					playerData = newdata
					updateEvent:Fire({
						title = "LEVEL " .. tostring(cannonValue.Value),
						description = tostring(
							cannonConfig.costFormula(cannonValue.Value + 1, playerData.boughtLevels)
						) .. "$",
					})
				end))
			end,
			init = function()
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.currentData
				for _, v in pairs(stats:GetChildren()) do
					if v:GetAttribute("statName") == "cannon" then
						return {
							title = "LEVEL " .. v.Value,
							description = tostring(cannonConfig.costFormula(v.Value + 1, playerData.boughtLevels))
								.. "$",
						}
					end
				end
			end,
			initModel = function(modelTrove, updateModelEvent)
				local Players = game:GetService("Players")
				local leaderstatsstats = Players.LocalPlayer:WaitForChild("leaderstats")
				local function updateModel(value)
					local newModel = ReplicatedStorage.assets.cannons:FindFirstChild(cannonConfig.getCannon(value + 1))
					print(newModel.Name)
					updateModelEvent:Fire(newModel)
				end
				for _, v in pairs(leaderstatsstats:GetChildren()) do
					if v:GetAttribute("statName") ~= "cannon" then
						continue
					end
					modelTrove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
						updateModel(v.Value)
					end))
					updateModel(v.Value)
				end
			end,
			callbackFunction = function(success, states)
				if success and not RunService:IsStudio() then
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0.992156, 1, 0.580392) })
				else
					local id = gamepassConfig.upgradeCannon.getId(dataController.getData())
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, id)
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(1, 0, 0) })
				end

				task.delay(1, function()
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0, 1, 81 / 255) })
				end)
			end,
		},
		floor = {
			callback = function(callbackEvent)
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)
				if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
					local success = zap.purchaseUpgrade.Call("floor")
					callbackEvent:Fire(success)
				else
					local playerData = dataController.getData()
					zap.checkRecipient.Call({
						selectedPlayer = playerPlatform:GetAttribute("currentTower"),
						selectedGift = "tenFloors",
					})
					if playerData.productTiers.gifts["floors"] then
						if playerData.productTiers.gifts["floors"] >= 5 then
							MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.tenFloorsTier2.id)
							callbackEvent:Fire(true)
							return
						end
					end
					MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.tenFloors.id)
					callbackEvent:Fire(true)
				end
			end,
			title = "+1 FLOOR",
			description = "N/A",
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.currentData
				local floorValue
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)

				for _, v in pairs(stats:GetChildren()) do
					if v:GetAttribute("statName") ~= "floors" then
						continue
					end
					floorValue = v
					trove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
						if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
							updateEvent:Fire({
								title = "LEVEL " .. tostring(v.Value),
								description = tostring(floorConfig.costFormula(v.Value + 1, playerData.boughtFloors))
									.. "$",
							})
						end
					end))
				end

				trove:Add(dataController.dataChanged:Connect(function(newdata)
					print("go")
					playerData = newdata
					if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
						updateEvent:Fire({
							title = "LEVEL " .. tostring(floorValue.Value),
							description = tostring(
								floorConfig.costFormula(floorValue.Value + 1, playerData.boughtFloors)
							) .. "$",
						})
					end
				end))

				trove:Add(playerPlatform:GetAttributeChangedSignal("currentTower"):Connect(function()
					if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
						updateEvent:Fire({
							title = "LEVEL " .. tostring(floorValue.Value),
							description = tostring(
								floorConfig.costFormula(floorValue.Value + 1, playerData.boughtFloors)
							) .. "$",
						})
					else
						updateEvent:Fire({
							title = "GIFT 10 FLOORS",
							description = '100 <font color="#008000">\u{E002}</font>',
						})
					end
				end))
			end,
			init = function()
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.currentData
				for _, v in pairs(stats:GetChildren()) do
					if v:GetAttribute("statName") == "floors" then
						return {
							title = "LEVEL " .. v.Value,
							description = tostring(floorConfig.costFormula(v.Value + 1, playerData.boughtFloors))
								.. "$",
						}
					end
				end
			end,
			initModel = ReplicatedStorage.assets.miniFloor,
			callbackFunction = function(success, states)
				if success then
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0.992156, 1, 0.580392) })
				else
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(1, 0, 0) })
				end

				task.delay(1, function()
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0, 1, 81 / 255) })
				end)
			end,
		},
		tenFloors = {
			callback = function(callbackEvent)
				local playerData = dataController.getData()
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)
				if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
					if playerData.productTiers.products["floors"] then
						if playerData.productTiers.products["floors"] >= 5 then
							MarketplaceService:PromptProductPurchase(
								Players.LocalPlayer,
								gamepassConfig.tenFloorsTier2.id
							)
						else
							MarketplaceService:PromptProductPurchase(Players.LocalPlayer, gamepassConfig.tenFloors.id)
						end
					end
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, gamepassConfig.tenFloors.id)
					callbackEvent:Fire(true)
				else
					local playerData = dataController.getData()
					zap.checkRecipient.Call({
						selectedPlayer = playerPlatform:GetAttribute("currentTower"),
						selectedGift = "fiftyFloors",
					})
					if playerData.productTiers.gifts["floors"] then
						if playerData.productTiers.gifts["floors"] >= 5 then
							MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.fiftyFloorsTier2.id)
							callbackEvent:Fire(true)
							return
						end
					end
					MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.fiftyFloors.id)
					callbackEvent:Fire(true)
				end
			end,
			init = function()
				return { title = "+10 FLOORS", description = '100 <font color="#008000">\u{E002}</font>' }
			end,
			title = "+10 FLOORS",
			description = '100 <font color="#008000">\u{E002}</font>',
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local floorValue
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)

				trove:Add(playerPlatform:GetAttributeChangedSignal("currentTower"):Connect(function()
					if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
						updateEvent:Fire({
							title = "+10 FLOORS",
							description = '100 <font color="#008000">\u{E002}</font>',
						})
					else
						updateEvent:Fire({
							title = "GIFT 50 FLOORS",
							description = '100 <font color="#008000">\u{E002}</font>',
						})
					end
				end))
			end,
			initModel = ReplicatedStorage.assets.twofloors,
		},
		fiftyFloors = {
			callback = function(callbackEvent)
				local playerData = dataController.getData()
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)
				if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
					if playerData.productTiers.products["floors"] then
						if playerData.productTiers.products["floors"] >= 5 then
							MarketplaceService:PromptProductPurchase(
								Players.LocalPlayer,
								gamepassConfig.fiftyFloorsTier2.id
							)
						else
							MarketplaceService:PromptProductPurchase(Players.LocalPlayer, gamepassConfig.fiftyFloors.id)
						end
					end
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, gamepassConfig.fiftyFloors.id)
					callbackEvent:Fire(true)
				else
					local playerData = dataController.getData()
					zap.checkRecipient.Call({
						selectedPlayer = playerPlatform:GetAttribute("currentTower"),
						selectedGift = "twoHundredFifty",
					})
					if playerData.productTiers.gifts["floors"] then
						if playerData.productTiers.gifts["floors"] >= 5 then
							MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.twoHundredFiftyTier2.id)
							callbackEvent:Fire(true)
							return
						end
					end
					MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.twoHundredFifty.id)
					callbackEvent:Fire(true)
				end
			end,
			init = function()
				return { title = "+50 FLOORS", description = '100 <font color="#008000">\u{E002}</font>' }
			end,
			title = "+50 FLOORS",
			description = '100 <font color="#008000">\u{E002}</font>',
			initModel = ReplicatedStorage.assets.fivefloors,
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local floorValue
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)

				trove:Add(playerPlatform:GetAttributeChangedSignal("currentTower"):Connect(function()
					if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
						updateEvent:Fire({
							title = "+10 FLOORS",
							description = '100 <font color="#008000">\u{E002}</font>',
						})
					else
						updateEvent:Fire({
							title = "GIFT 250 FLOORS",
							description = '100 <font color="#008000">\u{E002}</font>',
						})
					end
				end))
			end,
		},
		changeTower = {
			callback = function(callbackEvent)
				local result = zap.changePrivacy.Call()
				callbackEvent:Fire(result)
			end,
			title = "SET STATUS",
			description = "PUBLIC 👥",
			updateValues = function(trove, updateEvent, states)
				local playerData = dataController.currentData
				if playerData.towerStatus == 0 then
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0, 1, 81 / 255) })
				elseif playerData.towerStatus == 1 then
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0.474509, 0.505882, 0.792156) })
				else
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0.788235, 0.474509, 0.933333) })
				end
				trove:Add(dataController.dataChanged:Connect(function(newdata)
					updateEvent:Fire({
						title = "TOWER STATUS",
						description = if newdata.towerStatus == 0
							then "PUBLIC 🌐"
							elseif newdata.towerStatus == 1 then "FRIENDS ONLY 👥"
							else "PRIVATE 🔒",
					})
				end))
			end,
			init = function()
				local playerData = dataController.currentData
				return {
					title = "TOWER STATUS",
					description = if playerData.towerStatus == 0
						then "PUBLIC 🌐"
						elseif playerData.towerStatus == 1 then "FRIENDS ONLY 👥"
						else "PRIVATE 🔒",
				}
			end,
			callbackFunction = function(success, states) -- callBackFunction is just a function to change the staes if needed
				if success then
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0.992156, 1, 0.580392) })
				else
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(1, 0, 0) })
				end

				task.delay(1, function()
					local newData = dataController.getData()
					if newData.towerStatus == 0 then
						spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0, 1, 81 / 255) })
					elseif newData.towerStatus == 1 then
						spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0.474509, 0.505882, 0.792156) })
					else
						spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0.788235, 0.474509, 0.933333) })
					end
				end)
			end,
		},
		upgradeCannon = {
			callback = function(callbackEvent)
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.currentData

				if playerData.cannonTier >= #tierConfig.cannonTiers then
					return
				end

				local tierInfo = tierConfig.cannonTiers[playerData.cannonTier + 1]

				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, tierInfo.id)
			end,
			title = "UPGRADE CANNON TIER",
			description = '100 <font color="#008000">\u{E002}</font>',
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.currentData
				local cannonValue

				trove:Add(dataController.dataChanged:Connect(function(newdata)
					if newdata.cannonTier == playerData.cannonTier then
						return
					end
					playerData = newdata
					local tierInfo =
						tierConfig.cannonTiers[math.clamp(playerData.cannonTier + 1, 1, #tierConfig.cannonTiers)]

					local itemInfo = marketplaceUtil.getProductInfo(tierInfo.id, Enum.InfoType.Product)

					updateEvent:Fire({
						title = "TIER " .. playerData.cannonTier,
						description = itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>',
					})
				end))
			end,
			init = function()
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.currentData

				local tierInfo =
					tierConfig.cannonTiers[math.clamp(playerData.cannonTier + 1, 1, #tierConfig.cannonTiers)]

				local itemInfo = marketplaceUtil.getProductInfo(tierInfo.id, Enum.InfoType.Product)

				return {
					title = "TIER " .. playerData.cannonTier,
					description = itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>',
				}
			end,
			initModel = function(modelTrove, updateModelEvent)
				local Players = game:GetService("Players")
				local leaderstatsstats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.getData()
				local function updateModel(value, cannonTier)
					local newModel = ReplicatedStorage.assets.cannons:FindFirstChild(cannonConfig.getCannon(value))
					local targetColor
					local targetScaleUp
					if playerData.cannonTier == 0 then
						targetColor = Color3.new(0.0509804, 0.411765, 0.67451)
						targetScaleUp = 1.1
					elseif playerData.cannonTier == 1 then
						targetColor = Color3.new(0.050980, 0.674509, 0.050980)
						targetScaleUp = 1.2
					elseif playerData.cannonTier == 2 then
						targetColor = Color3.new(0.752941, 0.729411, 0.4)
						targetScaleUp = 1.3
					elseif playerData.cannonTier == 3 then
						targetColor = Color3.new(0.713725, 0.301960, 0.301960)
						targetScaleUp = 1.4
					elseif playerData.cannonTier == 4 then
						targetColor = Color3.new(0.713725, 0.301960, 0.301960)
						targetScaleUp = 1.5
					end
					updateModelEvent:Fire(newModel, targetColor, targetScaleUp)
				end
				for _, v in pairs(leaderstatsstats:GetChildren()) do
					if v:GetAttribute("statName") ~= "cannon" then
						continue
					end
					modelTrove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
						updateModel(v.Value)
					end))
					modelTrove:Add(dataController.dataChanged:Connect(function(newData)
						if newData.cannonTier == playerData.cannonTier then
							return
						end
						playerData = newData
						updateModel(v.Value)
					end))
					updateModel(v.Value)
				end
			end,
			callbackFunction = function(success, states)
				if success then
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0.992156, 1, 0.580392) })
				else
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(1, 0, 0) })
				end

				task.delay(1, function()
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0, 1, 81 / 255) })
				end)
			end,
		},
		switchCannon = {
			checkToLoad = function(loadEvent)
				local playerData = dataController.getData()

				if #playerData.cannons > 0 then
					task.delay(1, function()
						loadEvent:Fire()
					end)
					return
				end

				local connection

				connection = dataController.dataChanged:Connect(function(newData)
					if #newData.cannons > 0 then
						loadEvent:Fire()
						connection:Disconnect()
					end
				end)
			end,
			callback = function(callbackEvent)
				local playerData = dataController.getData()
				cannonIndex += 1
				if cannonIndex > #playerData.cannons then
					cannonIndex = 0
				end
				local success = zap.toggleCannon.Call(playerData.cannons[cannonIndex] or "default")
				if not success then
					cannonIndex -= 1
				else
					changedCannonSignal:Fire(cannonIndex)
				end
				callbackEvent:Fire(success)
			end,
			title = "CHANGE CANNON",
			description = "DEFAULT",
			updateValues = function(trove, updateEvent)
				trove:Add(changedCannonSignal:Connect(function(newIndex)
					if newIndex > 0 then
						print("Update")
						local playerData = dataController.getData()
						local newCannon = playerData.cannons[newIndex]
						updateEvent:Fire({
							title = "CHANGE CANNON",
							description = string.upper(newCannon),
						})
					else
						updateEvent:Fire({
							title = "CHANGE CANNON",
							description = "DEFAULT",
						})
					end
				end))
			end,
			init = function()
				return {
					title = "CHANGE CANNON",
					description = "DEFAULT",
				}
			end,
			initModel = function(modelTrove, updateModelEvent)
				local Players = game:GetService("Players")
				local leaderstatsstats = Players.LocalPlayer:WaitForChild("leaderstats")

				local function updateDefaultModel(newVal)
					local newModel = ReplicatedStorage.assets.cannons:FindFirstChild(cannonConfig.getCannon(newVal + 1))
					updateModelEvent:Fire(newModel)
				end

				local function updateModel(modelName)
					local newModel = ReplicatedStorage.assets.cannons:FindFirstChild(modelName)
					updateModelEvent:Fire(newModel)
				end

				for _, v in pairs(leaderstatsstats:GetChildren()) do
					if v:GetAttribute("statName") ~= "cannon" then
						continue
					end

					modelTrove:Add(
						changedCannonSignal:Connect(function(newIndex)
							local playerData = dataController.getData()
							if newIndex == 0 then
								updateDefaultModel(v.Value)
							else
								updateModel(playerData.cannons[newIndex])
							end
							cannonIndex = newIndex
						end),
						"Disconnect"
					)

					modelTrove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
						if cannonIndex == 0 then
							updateDefaultModel(v.Value)
						end
					end))

					updateDefaultModel(v.Value)
				end
			end,
			callbackFunction = function(success, states)
				if success then
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0.992156, 1, 0.580392) })
				else
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(1, 0, 0) })
				end

				task.delay(1, function()
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0, 1, 81 / 255) })
				end)
			end,
		},
	},
}
