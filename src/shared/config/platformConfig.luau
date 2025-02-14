local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local boughtLevels = 0

local dataController = require(ReplicatedStorage.client.controllers.dataController)
local uiController = require(ReplicatedStorage.client.controllers.uiController)

local zap = require(ReplicatedStorage.zap)

local spr = require(ReplicatedStorage.sharedPackages.spr)

local gamepassConfig = require(ReplicatedStorage.shared.config.gamepassConfig)
local floorConfig = require(ReplicatedStorage.shared.config.floorConfig)
local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)
local reactUtil = require(ReplicatedStorage.shared.utilities.reactUtil)

local startTimeLuckyBlock = tick()

return {
	cannons = {
		armyCannon = {
			callback = function(callbackEvent)
				if not marketplaceUtil.userOwnsGamepass(Players.LocalPlayer, gamepassConfig.buyArmyCannon.id) then
					MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, gamepassConfig.buyArmyCannon.id)
				else
					local playerPlatform =
						workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
					local cannonName = playerPlatform
						:FindFirstChild("cannonPosition", true)
						:FindFirstChildWhichIsA("Folder")
						:GetAttribute("cannonName")
					callbackEvent:Fire(
						zap.toggleCannon.Call(
							cannonName ~= gamepassConfig.artilleryGamepasses[tostring(gamepassConfig.buyArmyCannon.id)]
									and gamepassConfig.buyArmyCannon.id
								or "x"
						)
					)
				end
			end,
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local marketEvent = marketplaceUtil.getPlayerEvent(Players.LocalPlayer)
				trove:Add(marketEvent:Connect(function(id)
					if id ~= gamepassConfig.buyArmyCannon.id then
						return
					end
					updateEvent:Fire({
						title = "ARMY CANNON",
						description = "TOGGLE",
					})
				end))
			end,
			init = function()
				local Players = game:GetService("Players")
				local Player = Players.LocalPlayer
				if marketplaceUtil.userOwnsGamepass(Player, gamepassConfig.buyArmyCannon.id) then
					return {
						title = "ARMY CANNON",
						description = "TOGGLE",
					}
				else
					return {
						title = "ARMY CANNON",
						description = '100 <font color="#008000">\u{E002}</font>',
					}
				end
			end,
			title = "ARMY CANNON",
			description = '100 <font color="#008000">\u{E002}</font>',
			initModel = ReplicatedStorage.assets.cannons.armyCannon,
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
		circusCannon = {
			callback = function(callbackEvent)
				if not marketplaceUtil.userOwnsGamepass(Players.LocalPlayer, gamepassConfig.buyCircusCannon.id) then
					MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, gamepassConfig.buyCircusCannon.id)
				else
					local playerPlatform =
						workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
					local cannonName = playerPlatform
						:FindFirstChild("cannonPosition", true)
						:FindFirstChildWhichIsA("Folder")
						:GetAttribute("cannonName")
					callbackEvent:Fire(
						zap.toggleCannon.Call(
							cannonName
										~= gamepassConfig.artilleryGamepasses[tostring(
											gamepassConfig.buyCircusCannon.id
										)]
									and gamepassConfig.buyCircusCannon.id
								or "x"
						)
					)
				end
			end,
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local marketEvent = marketplaceUtil.getPlayerEvent(Players.LocalPlayer)
				trove:Add(marketEvent:Connect(function(id)
					if id ~= gamepassConfig.buyCircusCannon.id then
						return
					end
					updateEvent:Fire({
						title = "CIRCUS CANNON",
						description = "TOGGLE",
					})
				end))
			end,
			init = function()
				local Players = game:GetService("Players")
				local Player = Players.LocalPlayer
				if marketplaceUtil.userOwnsGamepass(Player, gamepassConfig.buyCircusCannon.id) then
					return {
						title = "CIRCUS CANNON",
						description = "TOGGLE",
					}
				else
					return {
						title = "CIRCUS CANNON",
						description = '100 <font color="#008000">\u{E002}</font>',
					}
				end
			end,
			title = "CIRCUS CANNON",
			description = '100 <font color="#008000">\u{E002}</font>',
			initModel = ReplicatedStorage.assets.cannons.circusCannon,
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
		artillery = {
			callback = function(callbackEvent)
				if not marketplaceUtil.userOwnsGamepass(Players.LocalPlayer, gamepassConfig.buyArtillery.id) then
					MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, gamepassConfig.buyArtillery.id)
				else
					local playerPlatform =
						workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
					local cannonName = playerPlatform
						:FindFirstChild("cannonPosition", true)
						:FindFirstChildWhichIsA("Folder")
						:GetAttribute("cannonName")
					callbackEvent:Fire(
						zap.toggleCannon.Call(
							cannonName ~= gamepassConfig.artilleryGamepasses[tostring(gamepassConfig.buyArtillery.id)]
									and gamepassConfig.buyArtillery.id
								or "x"
						)
					)
				end
			end,
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local marketEvent = marketplaceUtil.getPlayerEvent(Players.LocalPlayer)
				trove:Add(marketEvent:Connect(function(id)
					if id ~= gamepassConfig.buyArtillery.id then
						return
					end
					updateEvent:Fire({
						title = "ARTILLERY",
						description = "TOGGLE",
					})
				end))
			end,
			init = function()
				local Players = game:GetService("Players")
				local Player = Players.LocalPlayer
				if marketplaceUtil.userOwnsGamepass(Player, gamepassConfig.buyArtillery.id) then
					return {
						title = "ARTILLERY",
						description = "TOGGLE",
					}
				else
					return {
						title = "ARTILLERY",
						description = '100 <font color="#008000">\u{E002}</font>',
					}
				end
			end,
			title = "ARTILLERY",
			description = '100 <font color="#008000">\u{E002}</font>',
			initModel = ReplicatedStorage.assets.cannons.artillery,
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
		railgun = {
			callback = function(callbackEvent)
				if not marketplaceUtil.userOwnsGamepass(Players.LocalPlayer, gamepassConfig.buyRailgun.id) then
					MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, gamepassConfig.buyRailgun.id)
				else
					local playerPlatform =
						workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
					local cannonName = playerPlatform
						:FindFirstChild("cannonPosition", true)
						:FindFirstChildWhichIsA("Folder")
						:GetAttribute("cannonName")
					callbackEvent:Fire(
						zap.toggleCannon.Call(
							cannonName ~= gamepassConfig.artilleryGamepasses[tostring(gamepassConfig.buyRailgun.id)]
									and gamepassConfig.buyRailgun.id
								or "x"
						)
					)
				end
			end,
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local marketEvent = marketplaceUtil.getPlayerEvent(Players.LocalPlayer)
				trove:Add(marketEvent:Connect(function(id)
					if id ~= gamepassConfig.buyArtillery.id then
						return
					end
					updateEvent:Fire({
						title = "RAILGUN",
						description = "TOGGLE",
					})
				end))
			end,
			init = function()
				local Players = game:GetService("Players")
				local Player = Players.LocalPlayer
				if marketplaceUtil.userOwnsGamepass(Player, gamepassConfig.buyRailgun.id) then
					return {
						title = "RAILGUN",
						description = "TOGGLE",
					}
				else
					return {
						title = "RAILGUN",
						description = '100 <font color="#008000">\u{E002}</font>',
					}
				end
			end,
			title = "RAILGUN",
			description = '100 <font color="#008000">\u{E002}</font>',
			initModel = ReplicatedStorage.assets.cannons.railgun,
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
	platforms = {
		luckyBlock = {
			callback = function(callbackEvent)
				print("Start Lucky block")
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
							0,
							rewardsConfig.luckyBlockWaitTime
						)
					)

					updateEvent:Fire({
						title = timeLeft > 0 and reactUtil.secondsToMMSS(timeLeft) or "READY!",
						description = "UNTIL REWARD",
					})
				end)
			end,
			init = function()
				return {
					title = "Loading...",
					description = "UNTIL REWARD",
				}
			end,
			initModel = ReplicatedStorage.assets.cannons:WaitForChild("cannon1"),
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
			initModel = ReplicatedStorage.assets.cannons:FindFirstChild("cannon1"),
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
		floor = {
			callback = function(callbackEvent)
				local success = zap.purchaseUpgrade.Call("floor")
				callbackEvent:Fire(success)
			end,
			title = "+1 FLOOR",
			description = "N/A",
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.currentData
				local floorValue
				for _, v in pairs(stats:GetChildren()) do
					if v:GetAttribute("statName") ~= "floors" then
						continue
					end
					floorValue = v
					trove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
						print(tostring(floorConfig.costFormula(v.Value + 1, playerData.boughtFloors)))
						updateEvent:Fire({
							title = "LEVEL " .. tostring(v.Value),
							description = tostring(floorConfig.costFormula(v.Value + 1, playerData.boughtFloors))
								.. "$",
						})
					end))
				end
				trove:Add(dataController.dataChanged:Connect(function(newdata)
					print("go")
					playerData = newdata
					updateEvent:Fire({
						title = "LEVEL " .. tostring(floorValue.Value),
						description = tostring(floorConfig.costFormula(floorValue.Value + 1, playerData.boughtFloors))
							.. "$",
					})
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
			callback = function()
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, gamepassConfig.tenFloors.id)
			end,
			title = "+10 FLOORS",
			description = '100 <font color="#008000">\u{E002}</font>',
			initModel = ReplicatedStorage.assets.twofloors,
		},
		fiftyFloors = {
			callback = function()
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, gamepassConfig.fiftyFloors.id)
			end,
			title = "+40 FLOORS",
			description = '100 <font color="#008000">\u{E002}</font>',
			initModel = ReplicatedStorage.assets.fivefloors,
		},
		changeTower = {
			callback = function(callbackEvent)
				local result = zap.changePrivacy.Call()
				callbackEvent:Fire(result)
			end,
			title = "SET STATUS",
			description = "PUBLIC 👥",
			updateValues = function(trove, updateEvent)
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
					spr.target(states.model.touch, 0.9, 3, { Color = Color3.new(0, 1, 81 / 255) })
				end)
			end,
		},
	},
}
