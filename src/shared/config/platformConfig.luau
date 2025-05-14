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

local startTimeLuckyBlock = tick() - rewardsConfig.luckyBlockSkipInitial

local changedCannonSignal = Signal.new()

-- Define standard colors for callback feedback
local SUCCESS_COLOR = Color3.fromRGB(233, 255, 87) -- Greenish-yellow
local FAILURE_COLOR = Color3.fromRGB(255, 94, 88) -- Red
local GREY_FLASH_COLOR = Color3.new(0.8, 0.8, 0.8) -- Grey for specific feedback

-- Helper function to format numbers into K/M strings

local function switchPlatformColor(model, target)
	spr.target(model.touch, 0.9, 2.5, { ["Color"] = target })
	spr.target(model.color, 0.9, 2.5, { ["Color"] = target })
end

return {
	cannonIndex = 1,
	defaultHoverDistance = 5,
	uiHoverDistance = 0,
	changedCannonSignal = changedCannonSignal,
	platforms = {
		luckyBlock = {
			targetColor = Color3.fromRGB(98, 252, 255),
			hoverDistance = 2,
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
				trove:Add(task.spawn(function()
					while true do
						-- Get current player cannon level
						local playerData = dataController.getData()
						local cannonLevel = playerData.cannon or 1 -- Default to level 1

						-- Calculate wait time directly based on cannon level
						local currentWaitTime = rewardsConfig.luckyBlockWaitTime(cannonLevel)

						local timeLeft = math.floor(math.clamp(
							currentWaitTime - (tick() - startTimeLuckyBlock), -- Use dynamic wait time
							-10,
							currentWaitTime -- Use dynamic wait time for clamp max
						))

						updateEvent:Fire({
							title = timeLeft > 0 and reactUtil.secondsToMMSS(timeLeft) or "READY!",
							description = "UNTIL REWARD",
						})

						if Players.LocalPlayer:GetAttribute("autoFarming") == true then
							local success = zap.requestLuckyBlock.Call()
						end
						task.wait(1)
					end
				end))
			end,
			init = function()
				return {
					title = "Loading...",
					description = "UNTIL REWARD",
				}
			end,
			initModel = ReplicatedStorage.assets.playerCastleAssets:WaitForChild("luckyBlock"),
			callbackFunction = function(success, states)
				if success then
					switchPlatformColor(states.model, SUCCESS_COLOR)
				else
					local luckyBlockId = gamepassConfig.luckyBlockSkip.getId(dataController.getData())
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, luckyBlockId)
					switchPlatformColor(states.model, FAILURE_COLOR)
				end

				task.delay(0.5, function()
					switchPlatformColor(states.model, states.targetColor)
				end)
			end,
		},
		tasks = {
			targetColor = Color3.fromRGB(98, 252, 255),
			hoverDistance = 2.5,
			callback = function(callbackEvent)
				local playerData = dataController.getData()
				if not playerData.joinedGroupReward then
					-- State 1: Group reward not claimed. Try opening group page. Callback always fails visually.
					pcall(function()
						game:GetService("GuiService"):OpenBrowserWindow("https://www.roblox.com/groups/13101898")
					end)
					callbackEvent:Fire(false) -- Indicate failure for visual feedback, reward is server-side.
				else
					-- State 2: Group reward claimed. Proceed with friend invite/notification logic.
					local success = false
					if uiController.canPromptIn() then
						uiController.promptOptIn()
						success = uiController.promptInEvent:Wait() -- Wait for the prompt result
					else
						local s, r = pcall(function()
							SocialService:PromptGameInvite(Players.LocalPlayer)
						end)
						success = s -- Success is true if the prompt showed without error
					end
					callbackEvent:Fire(success) -- Fire success/failure for visual feedback
				end
			end,
			-- Title will now be dynamic based on player's potential reward
			title = "LOADING...", -- Initial title, updated dynamically
			description = "LOADING...", -- Initial description, updated dynamically
			updateValues = function(trove, updateEvent)
				local currentFloors = -1
				local currentBoughtFloors = -1
				local currentDescription = "" -- Track current description state for comparison
				local currentJoinedGroupReward = nil -- Track group reward state for comparison

				-- Function to update the display based on joinedGroupReward status
				local function updateDisplay(playerData)
					local newState = {}
					if not playerData.joinedGroupReward then
						-- State 1: Show Group Reward Prompt
						newState.title = "LIKE & JOIN GROUP"
						newState.description = "+20 FLOORS!"
					else
						-- State 2: Show Friend Invite Prompt
						local rewardAmount = rewardsConfig.playerJoinReward(playerData.floors, playerData.boughtFloors)
						newState.title = reactUtil.formatNumber(rewardAmount) .. " REWARD!"
						local canPromptIn = uiController.canPromptIn()
						newState.description = if canPromptIn then "ENABLE NOTIFICATIONS" else "INVITE A NEW PLAYER"
					end

					-- Only fire update if title or description actually changes
					if
						newState.title ~= (updateEvent.CurrentValue and updateEvent.CurrentValue.title)
						or newState.description ~= currentDescription
						or playerData.joinedGroupReward ~= currentJoinedGroupReward -- Also update if state itself changed
					then
						updateEvent:Fire(newState)
						currentDescription = newState.description -- Update tracked description
					end

					-- Update tracked state variables
					currentJoinedGroupReward = playerData.joinedGroupReward
					currentFloors = playerData.floors
					currentBoughtFloors = playerData.boughtFloors
				end

				-- Handle notification prompt success (only relevant if group reward is claimed)
				trove:Add(uiController.promptInEvent:Connect(function(success)
					local currentData = dataController.getData()
					-- Re-run updateDisplay if the prompt succeeded AND we are in the friend invite state
					if success and currentData.joinedGroupReward then
						updateDisplay(currentData)
					end
				end))

				-- Handle relevant player data changes
				trove:Add(dataController.dataChanged:Connect(function(newData)
					local oldData = dataController.lastData or {}
					-- Check if any relevant data point changed that affects the current state's display
					if
						newData.joinedGroupReward ~= currentJoinedGroupReward -- State changed
						or (
							newData.joinedGroupReward -- Only check floor/boughtFloors if in friend reward state
							and (newData.floors ~= currentFloors or newData.boughtFloors ~= currentBoughtFloors)
						)
					then
						updateDisplay(newData)
					end
				end))

				-- Initial update call after setup
				local initialData = dataController.getData()
				updateDisplay(initialData) -- This sets initial tracked values too
			end,
			init = function()
				-- Determine initial state based on joinedGroupReward
				local playerData = dataController.getData()
				if not playerData.joinedGroupReward then
					-- State 1: Group Reward
					return { title = "LIKE & JOIN GROUP", description = "+20 FLOORS!" }
				else
					-- State 2: Friend Invite
					local initialReward = rewardsConfig.playerJoinReward(playerData.floors, playerData.boughtFloors)
					local formattedReward = reactUtil.formatNumber(initialReward) .. " REWARD!"
					local canPromptIn = uiController.canPromptIn()
					local initialDescription = if canPromptIn then "ENABLE NOTIFICATIONS" else "INVITE A NEW PLAYER"
					return { title = formattedReward, description = initialDescription }
				end
			end,
			initModel = ReplicatedStorage.assets.purchaseAssets.rewardSuitcase,
			callbackFunction = function(success, states)
				local playerData = dataController.getData()
				local targetColor
				if not playerData.joinedGroupReward then
					-- State 1: Group reward not claimed. Flash grey as feedback for clicking.
					targetColor = GREY_FLASH_COLOR -- Use defined grey flash
				else
					-- State 2: Group reward claimed. Show success/fail for friend invite action.
					if success then
						targetColor = SUCCESS_COLOR
					else
						targetColor = FAILURE_COLOR
					end
				end

				-- Apply the determined color flash
				switchPlatformColor(states.model, targetColor)

				-- Reset color after delay, ensuring model still exists
				task.delay(0.5, function()
					switchPlatformColor(states.model, states.targetColor) -- Reset to default blue
				end)
			end,
		},
		oneLevel = {
			targetColor = Color3.fromRGB(255, 212, 103),
			hoverDistance = 3,
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
						if v.Value == cannonConfig.maxLevel then
							updateEvent:Fire({
								title = "LEVEL " .. tostring(v.Value),
								description = "MAX",
							})
						else
							updateEvent:Fire({
								title = "LEVEL " .. tostring(v.Value),
								description = "$ " .. tostring(
									reactUtil.formatNumber(
										cannonConfig.costFormula(v.Value + 1, playerData.boughtLevels)
									)
								), -- Fixed $ placement
							})
						end
					end))
				end
				trove:Add(dataController.dataChanged:Connect(function(newdata)
					playerData = newdata
					if cannonValue.Value == cannonConfig.maxLevel then
						updateEvent:Fire({
							title = "LEVEL " .. tostring(cannonValue.Value),
							description = "MAX",
						})
					else
						updateEvent:Fire({
							title = "LEVEL " .. tostring(cannonValue.Value),

							description = "$ " .. tostring(
								reactUtil.formatNumber(
									cannonConfig.costFormula(cannonValue.Value + 1, playerData.boughtLevels)
								)
							),
						})
					end
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
							description = "$ "
								.. tostring(
									reactUtil.formatNumber(
										cannonConfig.costFormula(v.Value + 1, playerData.boughtLevels)
									)
								), -- Fixed $ placement
						}
					end
				end
			end,
			initModel = function(modelTrove, updateModelEvent)
				local Players = game:GetService("Players")
				local leaderstatsstats = Players.LocalPlayer:WaitForChild("leaderstats")
				local function updateModel(value)
					local newModel = ReplicatedStorage.assets.cannons:FindFirstChild(cannonConfig.getCannon(value + 1))
					require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(newModel.Name)
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
					switchPlatformColor(states.model, SUCCESS_COLOR)
				else
					switchPlatformColor(states.model, FAILURE_COLOR)
				end

				task.delay(0.5, function()
					switchPlatformColor(states.model, states.targetColor)
				end)
			end,
		},
		upgradeFloor = {
			checkToHide = function(hideEvent)
				local localPlayer = Players.LocalPlayer
				if not localPlayer then
					return
				end -- Guard clause
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):FindFirstChild(localPlayer.Name)
				if not playerPlatform then
					return
				end -- Guard clause

				local currentEquippedCannonIndex = 0 -- Assume 0 is default cannon index (matches switchCannon logic)

				local trove = require(ReplicatedStorage.sharedPackages.Trove)
				local connections = trove.new()

				local function updateVisibility()
					if not playerPlatform:IsDescendantOf(workspace) then -- Check if platform still exists
						connections:Destroy()
						return
					end
					local isViewingOwnTower = (playerPlatform:GetAttribute("currentTower") == localPlayer.Name)
						or not playerPlatform:GetAttribute("currentTower")
					local isDefaultCannonEquipped = (currentEquippedCannonIndex == 0)

					print(isViewingOwnTower)

					hideEvent:Fire(isViewingOwnTower)
				end

				connections:Add(changedCannonSignal:Connect(function(newIndex)
					currentEquippedCannonIndex = newIndex
					updateVisibility()
				end))

				connections:Add(playerPlatform:GetAttributeChangedSignal("currentTower"):Connect(updateVisibility))

				-- Clean up connections when the hideEvent itself is disconnected (e.g. UI unmounts)
				-- This assumes hideEvent has a :Disconnect() or similar mechanism if it's a custom signal wrapper
				-- If hideEvent is a simple function callback, alternative cleanup is needed, e.g. via parent UI lifecycle
				if
					typeof(hideEvent) == "RBXScriptSignal" or (typeof(hideEvent) == "table" and hideEvent.Disconnect)
				then
					local disconnector = typeof(hideEvent) == "RBXScriptSignal" and hideEvent:Connect(function() end)
						or hideEvent
					connections:Add(disconnector) -- Add the signal itself or its disconnect method to trove
				end

				updateVisibility() -- Initial check
				return connections -- Return trove for external cleanup if needed by the caller of checkToHide
			end,
			targetColor = Color3.fromRGB(255, 212, 103),
			hoverDistance = 2,
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
						override = true,
					})
					-- Check gift tier, defaulting to 0 if nil
					if (playerData.productTiers.gifts["floors"] or 0) >= 5 then
						MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.tenFloorsTier2.id)
						callbackEvent:Fire(true)
						return
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
								description = "$ " .. tostring(
									reactUtil.formatNumber(
										floorConfig.costFormula(v.Value + 1, playerData.boughtFloors)
									)
								), -- Fixed $ placement
							})
						end
					end))
				end

				trove:Add(dataController.dataChanged:Connect(function(newdata)
					require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log("go")
					playerData = newdata
					if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
						updateEvent:Fire({
							title = "LEVEL " .. tostring(floorValue.Value),

							description = "$ " .. tostring(
								reactUtil.formatNumber(
									floorConfig.costFormula(floorValue.Value + 1, playerData.boughtFloors)
								)
							),
						})
					end
				end))

				local function updateFloorDisplay()
					local newPlayerData = dataController.getData()
					if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
						updateEvent:Fire({
							title = "LEVEL " .. tostring(floorValue.Value),

							description = "$ " .. tostring(
								reactUtil.formatNumber(
									floorConfig.costFormula(floorValue.Value + 1, newPlayerData.boughtFloors)
								)
							),
						})
					else
						-- Fetch dynamic price for gifting
						local giftId = giftConfig.tenFloors.id
						-- TODO: Add logic to check playerData.productTiers.gifts["floors"] for tier 2 ID if necessary
						local itemInfo
						local title = "GIFT 10 FLOORS"
						-- Check product tier, defaulting to 0 if nil
						if (newPlayerData.productTiers.gifts["floors"] or 0) >= 5 then
							giftId = giftConfig.tenFloorsTier2.id
							itemInfo = marketplaceUtil.getProductInfo(giftId, Enum.InfoType.Product)
							title = "GIFT 10 FLOORS (TIER 2)"
							require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(itemInfo)
						end
						itemInfo = itemInfo or marketplaceUtil.getProductInfo(giftId, Enum.InfoType.Product)
						local priceDesc = itemInfo and itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
							or "Loading..."
						updateEvent:Fire({
							title = title,
							description = priceDesc,
						})
					end
				end

				trove:Add(playerPlatform:GetAttributeChangedSignal("currentTower"):Connect(function()
					updateFloorDisplay()
				end))

				local currentData = dataController.getData()
				local oldGifts = currentData.productTiers.gifts["floors"] or 0
				local oldDevs = currentData.productTiers.products["floors"] or 0
				trove:Add(
					dataController.dataChanged:Connect(function(newData)
						-- Check product and gift tiers, defaulting to 0 if nil
						local newGifts = newData.productTiers.gifts["floors"] or 0
						local newDevs = newData.productTiers.products["floors"] or 0
						if oldGifts == newGifts and oldDevs == newDevs then
							return
						end

						oldDevs = newDevs
						oldGifts = newGifts
						updateFloorDisplay()
					end),
					"Disconnect"
				)
			end,
			init = function()
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.currentData
				for _, v in pairs(stats:GetChildren()) do
					if v:GetAttribute("statName") == "floors" then
						return {
							title = "LEVEL " .. v.Value,
							description = "$ "
								.. tostring(
									reactUtil.formatNumber(
										floorConfig.costFormula(v.Value + 1, playerData.boughtFloors)
									)
								), -- Fixed $ placement
						}
					end
				end
			end,
			initModel = ReplicatedStorage.assets.purchaseAssets.miniFloor,
			callbackFunction = function(success, states)
				if success then
					switchPlatformColor(states.model, SUCCESS_COLOR)
				else
					switchPlatformColor(states.model, FAILURE_COLOR)
				end

				task.delay(0.5, function()
					switchPlatformColor(states.model, states.targetColor)
				end)
			end,
		},
		tenFloors = {
			targetColor = Color3.fromRGB(70, 255, 113),
			hoverDistance = 2,
			callback = function(callbackEvent)
				local playerData = dataController.getData()
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)
				if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
					-- Check product tier, defaulting to 0 if nil
					if (playerData.productTiers.products["floors"] or 0) >= 5 then
						MarketplaceService:PromptProductPurchase(Players.LocalPlayer, gamepassConfig.tenFloorsTier2.id)
					else
						MarketplaceService:PromptProductPurchase(Players.LocalPlayer, gamepassConfig.tenFloors.id)
					end
					callbackEvent:Fire(true)
				else
					local playerData = dataController.getData()
					zap.checkRecipient.Call({
						selectedPlayer = playerPlatform:GetAttribute("currentTower"),
						selectedGift = "tenFloors", -- Corrected from fiftyFloors
						override = true,
					})
					-- Check gift tier, defaulting to 0 if nil
					if (playerData.productTiers.gifts["floors"] or 0) >= 5 then
						MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.tenFloorsTier2.id)
						callbackEvent:Fire(true)
						return
					end
					MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.tenFloors.id)
					callbackEvent:Fire(true)
				end
			end,
			init = function()
				-- Fetch initial dynamic price for self-purchase
				local productId = gamepassConfig.tenFloors.id
				-- TODO: Add logic to check playerData.productTiers.products["floors"] for tier 2 ID if necessary
				local itemInfo = marketplaceUtil.getProductInfo(productId, Enum.InfoType.Product)
				local priceDesc = itemInfo and itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
					or "Loading..."
				return { title = "+10 FLOORS", description = priceDesc }
			end,
			title = "+10 FLOORS", -- Title remains static
			description = "Loading...", -- Initial description, updated by init/updateValues
			initModel = ReplicatedStorage.assets.purchaseAssets.fiveFloors,
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local floorValue
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)

				-- Local function to update the platform display based on current tower
				local function updateTenFloorsDisplay()
					local playerData = dataController.getData() -- Get current data for tier checks
					local title, productId, giftId
					require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
						playerData.productTiers.products
					)
					if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
						title = "+10 FLOORS"
						productId = gamepassConfig.tenFloors.id
						local itemInfo
						-- Check product tier, defaulting to 0 if nil
						if (playerData.productTiers.products["floors"] or 0) >= 5 then
							productId = gamepassConfig.tenFloorsTier2.id
							title = "+10 FLOORS (TIER 2)"
							itemInfo = marketplaceUtil.getProductInfo(productId, Enum.InfoType.Product)
						end
						itemInfo = itemInfo or marketplaceUtil.getProductInfo(productId, Enum.InfoType.Product)
						local priceDesc = itemInfo and itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
							or "Loading..."
						updateEvent:Fire({ title = title, description = priceDesc })
					else
						title = "GIFT 10 FLOORS" -- Corrected: was GIFT 50 FLOORS
						local itemInfo
						giftId = giftConfig.tenFloors.id -- Corrected: was fiftyFloors
						-- Check gift tier, defaulting to 0 if nil
						if (playerData.productTiers.gifts["floors"] or 0) >= 5 then
							giftId = giftConfig.tenFloorsTier2.id -- Corrected
							title = "GIFT 10 FLOORS (TIER 2)" -- Corrected
							itemInfo = marketplaceUtil.getProductInfo(giftId, Enum.InfoType.Product)
						end
						itemInfo = itemInfo or marketplaceUtil.getProductInfo(giftId, Enum.InfoType.Product)
						local priceDesc = itemInfo and itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
							or "Loading..."
						updateEvent:Fire({ title = title, description = priceDesc })
					end
				end

				-- Connect the attribute change signal to the update function
				trove:Add(playerPlatform:GetAttributeChangedSignal("currentTower"):Connect(updateTenFloorsDisplay))

				local currentData = dataController.getData()
				local oldGifts = currentData.productTiers.gifts["floors"] or 0
				local oldDevs = currentData.productTiers.products["floors"] or 0
				dataController.dataChanged:Connect(function(newData)
					-- Check product and gift tiers, defaulting to 0 if nil
					local newGifts = newData.productTiers.gifts["floors"] or 0
					local newDevs = newData.productTiers.products["floors"] or 0
					if oldGifts == newGifts and oldDevs == newDevs then
						return
					end
					oldDevs = newDevs
					oldGifts = newGifts
					updateTenFloorsDisplay()
				end)

				-- Call the function once initially to set the correct state
				updateTenFloorsDisplay()
			end,
			-- initModel = ReplicatedStorage.assets.purchaseAssets.fivefloors, -- Replaced by dynamic initModel function
		},
		fiftyFloors = {
			targetColor = Color3.fromRGB(70, 255, 113),
			hoverDistance = 2,
			callback = function(callbackEvent)
				local playerData = dataController.getData()
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)
				if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
					-- Check product tier, defaulting to 0 if nil
					if (playerData.productTiers.products["floors"] or 0) >= 5 then
						MarketplaceService:PromptProductPurchase(
							Players.LocalPlayer,
							gamepassConfig.fiftyFloorsTier2.id
						)
					else
						MarketplaceService:PromptProductPurchase(Players.LocalPlayer, gamepassConfig.fiftyFloors.id)
					end
					callbackEvent:Fire(true)
				else
					local playerData = dataController.getData()
					zap.checkRecipient.Call({
						selectedPlayer = playerPlatform:GetAttribute("currentTower"),
						selectedGift = "fiftyFloors", -- Corrected: was twoHundredFifty
						override = true,
					})
					-- Check gift tier, defaulting to 0 if nil
					if (playerData.productTiers.gifts["floors"] or 0) >= 5 then
						MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.fiftyFloorsTier2.id) -- Corrected
						callbackEvent:Fire(true)
						return
					end
					MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.fiftyFloors.id) -- Corrected
					callbackEvent:Fire(true)
				end
			end,
			init = function()
				-- Fetch initial dynamic price for self-purchase
				local productId = gamepassConfig.fiftyFloors.id
				-- TODO: Add logic to check playerData.productTiers.products["floors"] for tier 2 ID if necessary
				local itemInfo = marketplaceUtil.getProductInfo(productId, Enum.InfoType.Product)
				local priceDesc = itemInfo and itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
					or "Loading..."
				return { title = "+50 FLOORS", description = priceDesc }
			end,
			title = "+50 FLOORS", -- Title remains static
			description = "Loading...", -- Initial description, updated by init/updateValues
			initModel = ReplicatedStorage.assets.purchaseAssets.fiftyFloors,
			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local floorValue
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)

				-- Local function to update the platform display based on current tower
				local function updateFiftyFloorsDisplay()
					local playerData = dataController.getData() -- Get current data for tier checks
					local title, productId, giftId
					if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
						title = "+50 FLOORS"
						productId = gamepassConfig.fiftyFloors.id
						local itemInfo
						-- Check product tier, defaulting to 0 if nil
						if (playerData.productTiers.products["floors"] or 0) >= 5 then
							title = "+50 FLOORS (TIER 2)"
							productId = gamepassConfig.fiftyFloorsTier2.id
							itemInfo = marketplaceUtil.getProductInfo(productId, Enum.InfoType.Product)
						end
						itemInfo = itemInfo or marketplaceUtil.getProductInfo(productId, Enum.InfoType.Product)
						local priceDesc = itemInfo and itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
							or "Loading..."
						updateEvent:Fire({ title = title, description = priceDesc })
					else
						local itemInfo
						title = "GIFT 50 FLOORS" -- Corrected: was GIFT 250 FLOORS
						giftId = giftConfig.fiftyFloors.id -- Corrected: was twoHundredFifty
						-- Check gift tier, defaulting to 0 if nil
						if (playerData.productTiers.gifts["floors"] or 0) >= 5 then
							giftId = giftConfig.fiftyFloorsTier2.id -- Corrected
							title = "GIFT 50 FLOORS (TIER 2)" -- Corrected
							itemInfo = marketplaceUtil.getProductInfo(giftId, Enum.InfoType.Product)
						end
						itemInfo = itemInfo or marketplaceUtil.getProductInfo(giftId, Enum.InfoType.Product)
						local priceDesc = itemInfo and itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
							or "Loading..."
						updateEvent:Fire({ title = title, description = priceDesc })
					end
				end

				-- Connect the attribute change signal to the update function
				trove:Add(playerPlatform:GetAttributeChangedSignal("currentTower"):Connect(updateFiftyFloorsDisplay))

				local currentData = dataController.getData()
				local oldGifts = currentData.productTiers.gifts["floors"] or 0
				local oldDevs = currentData.productTiers.products["floors"] or 0
				dataController.dataChanged:Connect(function(newData)
					-- Check product and gift tiers, defaulting to 0 if nil
					local newGifts = newData.productTiers.gifts["floors"] or 0
					local newDevs = newData.productTiers.products["floors"] or 0
					if oldGifts == newGifts and oldDevs == newDevs then
						return
					end
					oldDevs = newDevs
					oldGifts = newGifts
					updateFiftyFloorsDisplay()
				end)

				-- Call the function once initially to set the correct state
				updateFiftyFloorsDisplay()
			end,
		},

		changeTowerPrivacy = {
			targetColor = Color3.fromRGB(70, 255, 113),
			callback = function(callbackEvent)
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)
				if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
					local result = zap.changePrivacy.Call()
					callbackEvent:Fire(result)
				else
					local result = zap.selectPlatform.Call(localPlayer)
					callbackEvent:Fire(result)
				end
			end,
			title = "SET STATUS",
			description = "PUBLIC 👥",
			updateValues = function(trove, updateEvent, states)
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)

				local function updateColor()
					local playerData = dataController.currentData
					if playerData.towerStatus == 0 then
						switchPlatformColor(states.model, Color3.fromRGB(70, 255, 113))
					elseif playerData.towerStatus == 1 then
						switchPlatformColor(states.model, Color3.fromRGB(95, 84, 255))
					else
						switchPlatformColor(states.model, Color3.new(1, 0, 0)) -- Bright Red for Private
					end
				end

				trove:Add(playerPlatform:GetAttributeChangedSignal("currentTower"):Connect(function()
					if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
						local playerData = dataController.getData()
						updateColor()
						updateEvent:Fire({
							title = "TOWER STATUS",
							description = if playerData.towerStatus == 0
								then "PUBLIC 🌐"
								elseif playerData.towerStatus == 1 then "FRIENDS ONLY 👥"
								else "PRIVATE 🔒",
						})
					else
						switchPlatformColor(states.model, Color3.fromRGB(70, 255, 113))
						updateEvent:Fire({
							title = "TELEPORT",
							description = "RETURN TO YOUR TOWER",
						})
					end
				end))

				trove:Add(dataController.dataChanged:Connect(function(newdata)
					if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
						updateEvent:Fire({
							title = "TOWER STATUS",
							description = if newdata.towerStatus == 0
								then "PUBLIC 🌐"
								elseif newdata.towerStatus == 1 then "FRIENDS ONLY 👥"
								else "PRIVATE 🔒",
						})
					end
				end))

				updateColor()
			end,
			init = function()
				local playerData = dataController.getData()
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
					switchPlatformColor(states.model, SUCCESS_COLOR)
				else
					switchPlatformColor(states.model, FAILURE_COLOR)
				end

				task.delay(0.5, function()
					local newData = dataController.getData()
					if newData.towerStatus == 0 then
						switchPlatformColor(states.model, states.targetColor) -- Public uses default blue
					elseif newData.towerStatus == 1 then
						switchPlatformColor(states.model, Color3.new(0.474509, 0.505882, 0.792156)) -- Friends Only (keep specific color)
					else
						switchPlatformColor(states.model, FAILURE_COLOR) -- Private uses failure red
					end
				end)
			end,
		},
		oneTier = {
			targetColor = Color3.fromRGB(70, 255, 113),
			hoverDistance = 3,
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
						title = if #tierConfig.cannonTiers ~= playerData.cannonTier
							then "TIER " .. playerData.cannonTier + 1
							else "MAX TIER",
						description = if #tierConfig.cannonTiers ~= playerData.cannonTier
							then itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
							else " ",
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
					title = if #tierConfig.cannonTiers ~= playerData.cannonTier
						then "TIER " .. playerData.cannonTier + 1
						else "MAX TIER",
					description = if #tierConfig.cannonTiers ~= playerData.cannonTier
						then itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
						else " ",
				}
			end,
			initModel = function(modelTrove, updateModelEvent)
				local Players = game:GetService("Players")
				local leaderstatsstats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.getData()
				local function updateModel(value, cannonTier)
					local cannonAsset = ReplicatedStorage.assets.cannons:FindFirstChild(cannonConfig.getCannon(value))
					local modelToDisplay = cannonAsset -- Default to the original asset
					local targetColor
					local targetScaleUp

					if playerData.cannonTier == 0 then
						targetColor = Color3.new(0.827450, 0.827450, 0.827450)
						targetScaleUp = 1
					elseif playerData.cannonTier == 1 then
						targetColor = Color3.new(0.576470, 0.925490, 0.576470)
						targetScaleUp = 1.25
					elseif playerData.cannonTier == 2 then
						targetColor = Color3.new(0.635294, 0.776470, 0.819607)
						targetScaleUp = 1.5
					elseif playerData.cannonTier == 3 then
						targetColor = Color3.new(0.713725, 0.301960, 0.301960)
						targetScaleUp = 1.75
						-- modelToDisplay remains cannonAsset
					elseif playerData.cannonTier == 4 then
						targetColor = Color3.new(0.678431, 0.301960, 0.713725)
						targetScaleUp = 2
						-- modelToDisplay remains cannonAsset
					else
						-- Potentially handle other tiers or ensure targetScaleUp is defined for safety.
						-- Current logic matches original behavior where they might be nil if tier is unexpected.
					end
					updateModelEvent:Fire(modelToDisplay, targetColor, targetScaleUp)
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
					switchPlatformColor(states.model, SUCCESS_COLOR)
				else
					switchPlatformColor(states.model, FAILURE_COLOR)
				end

				task.delay(0.5, function()
					switchPlatformColor(states.model, states.targetColor)
				end)
			end,
		},
		switchCannon = {
			targetColor = Color3.fromRGB(70, 255, 113),
			hoverDistance = 3,
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
						require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log("Update")
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
						changedCannonSignal:Fire(0)
					end))

					updateDefaultModel(v.Value)
				end
			end,
			callbackFunction = function(success, states)
				if success then
					switchPlatformColor(states.model, SUCCESS_COLOR)
				else
					switchPlatformColor(states.model, FAILURE_COLOR)
				end

				task.delay(0.5, function()
					switchPlatformColor(states.model, states.targetColor)
				end)
			end,
		},
		twoHundredFiftyFloors = {
			-- checkToHide = function(hideEvent) -- Removed as per requirement to transform, not hide
			-- 	local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(Players.LocalPlayer.Name)
			-- 	playerPlatform:GetAttributeChangedSignal("currentTower"):Connect(function()
			-- 		hideEvent:Fire(playerPlatform:GetAttribute("currentTower") == Players.LocalPlayer.Name)
			-- 	end)
			-- end,
			targetColor = Color3.fromRGB(95, 84, 255),
			hoverDistance = 2,
			callback = function(callbackEvent)
				local playerData = dataController.getData()
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)
				if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
					-- Check product tier, defaulting to 0 if nil
					if (playerData.productTiers.products["floors"] or 0) >= 5 then
						MarketplaceService:PromptProductPurchase(
							Players.LocalPlayer,
							gamepassConfig.twoHundredFiftyFloorsTier2.id
						)
					else
						MarketplaceService:PromptProductPurchase(
							Players.LocalPlayer,
							gamepassConfig.twoHundredFiftyFloors.id
						)
					end
					callbackEvent:Fire(true)
				else
					local playerData = dataController.getData()
					zap.checkRecipient.Call({
						selectedPlayer = playerPlatform:GetAttribute("currentTower"),
						selectedGift = "twoHundredFifty",
						override = true,
					})
					-- Check gift tier, defaulting to 0 if nil
					if (playerData.productTiers.gifts["floors"] or 0) >= 5 then
						MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.twoHundredFiftyTier2.id)
						callbackEvent:Fire(true)
						return
					end
					MarketplaceService:PromptProductPurchase(localPlayer, giftConfig.twoHundredFifty.id)
					callbackEvent:Fire(true)
				end
			end,
			init = function()
				-- Fetch initial dynamic price for self-purchase
				local productId = gamepassConfig.twoHundredFiftyFloors.id
				-- TODO: Add logic to check playerData.productTiers.products["floors"] for tier 2 ID if necessary
				local itemInfo = marketplaceUtil.getProductInfo(productId, Enum.InfoType.Product)
				local priceDesc = itemInfo and itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
					or "Loading..."
				return { title = "+250 FLOORS", description = priceDesc }
			end,
			title = "+250 FLOORS", -- Title remains static
			description = "Loading...", -- Initial description, updated by init/updateValues
			initModel = ReplicatedStorage.assets.purchaseAssets.twoHundredFiftyFloors,

			updateValues = function(trove, updateEvent)
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local floorValue
				local localPlayer = Players.LocalPlayer
				local playerPlatform = workspace:WaitForChild("playerPlatforms"):WaitForChild(localPlayer.Name)

				-- Local function to update the platform display based on current tower
				local function updateTwoHundredFiftyFloorsDisplay() -- Renamed for clarity
					local playerData = dataController.getData() -- Get current data for tier checks
					local title, productId, giftId
					if playerPlatform:GetAttribute("currentTower") == localPlayer.Name then
						title = "+250 FLOORS"
						productId = gamepassConfig.twoHundredFiftyFloors.id
						local itemInfo
						-- Check product tier, defaulting to 0 if nil
						if (playerData.productTiers.products["floors"] or 0) >= 5 then
							title = "+250 FLOORS (TIER 2)"
							productId = gamepassConfig.twoHundredFiftyFloorsTier2.id
							itemInfo = marketplaceUtil.getProductInfo(productId, Enum.InfoType.Product)
						end
						itemInfo = itemInfo or marketplaceUtil.getProductInfo(productId, Enum.InfoType.Product)
						local priceDesc = itemInfo and itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
							or "Loading..."
						updateEvent:Fire({ title = title, description = priceDesc })
					else
						local itemInfo
						title = "GIFT 250 FLOORS"
						giftId = giftConfig.twoHundredFifty.id
						-- Check gift tier, defaulting to 0 if nil
						if (playerData.productTiers.gifts["floors"] or 0) >= 5 then
							giftId = giftConfig.twoHundredFiftyTier2.id
							title = "GIFT 250 FLOORS (TIER 2)"
							itemInfo = marketplaceUtil.getProductInfo(giftId, Enum.InfoType.Product)
						end
						itemInfo = itemInfo or marketplaceUtil.getProductInfo(giftId, Enum.InfoType.Product)
						local priceDesc = itemInfo and itemInfo.PriceInRobux .. ' <font color="#008000">\u{E002}</font>'
							or "Loading..."
						updateEvent:Fire({ title = title, description = priceDesc })
					end
				end

				-- Connect the attribute change signal to the update function
				trove:Add(
					playerPlatform:GetAttributeChangedSignal("currentTower"):Connect(updateTwoHundredFiftyFloorsDisplay)
				) -- Renamed for clarity

				local currentData = dataController.getData()
				local oldGifts = currentData.productTiers.gifts["floors"] or 0
				local oldDevs = currentData.productTiers.products["floors"] or 0
				dataController.dataChanged:Connect(function(newData)
					-- Check product and gift tiers, defaulting to 0 if nil
					local newGifts = newData.productTiers.gifts["floors"] or 0
					local newDevs = newData.productTiers.products["floors"] or 0
					if oldGifts == newGifts and oldDevs == newDevs then
						return
					end
					oldDevs = newDevs
					oldGifts = newGifts
					updateTwoHundredFiftyFloorsDisplay() -- Renamed for clarity
				end)

				-- Call the function once initially to set the correct state
				updateTwoHundredFiftyFloorsDisplay() -- Renamed for clarity
			end,
		},
		tenLevels = {
			targetColor = Color3.fromRGB(70, 255, 113),
			hoverDistance = 3,
			callback = function(callbackEvent)
				local id = gamepassConfig.upgradeCannon.getId(dataController.getData())
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, id)
				callbackEvent:Fire(true)
			end,
			title = "+10 LEVELS",
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
				end
				trove:Add(dataController.dataChanged:Connect(function(newdata)
					if playerData.cannon == newdata.cannon then
						return
					end
					playerData = newdata
					if cannonValue.Value == cannonConfig.maxLevel then
						updateEvent:Fire({
							title = "LEVEL " .. tostring(cannonValue.Value),
							description = "MAX",
						})
					else
						local id = gamepassConfig.upgradeCannon.getId(playerData)
						local itemInfo = marketplaceUtil.getProductInfo(id, Enum.InfoType.Product)
						updateEvent:Fire({
							title = "LEVEL " .. tostring(math.min(cannonConfig.maxLevel, cannonValue.Value + 10)),
							description = '<font color="#008000">\u{E002}</font>' .. itemInfo.PriceInRobux, -- Fixed $ placement
						})
					end
				end))
			end,
			init = function()
				local Players = game:GetService("Players")
				local stats = Players.LocalPlayer:WaitForChild("leaderstats")
				local playerData = dataController.currentData
				for _, v in pairs(stats:GetChildren()) do
					if v:GetAttribute("statName") == "cannon" then
						local id = gamepassConfig.upgradeCannon.getId(dataController.getData())
						local itemInfo = marketplaceUtil.getProductInfo(id, Enum.InfoType.Product)
						return {
							title = "LEVEL " .. tostring(math.min(cannonConfig.maxLevel, v.Value + 10)),
							description = '<font color="#008000">\u{E002}</font>' .. itemInfo.PriceInRobux,
						}
					end
				end
			end,
			initModel = function(modelTrove, updateModelEvent)
				local Players = game:GetService("Players")
				local leaderstatsstats = Players.LocalPlayer:WaitForChild("leaderstats")
				local function updateModel(value)
					local newModel = ReplicatedStorage.assets.cannons:FindFirstChild(cannonConfig.getCannon(value + 1))
					require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(newModel.Name)
					updateModelEvent:Fire(newModel)
				end
				for _, v in pairs(leaderstatsstats:GetChildren()) do
					if v:GetAttribute("statName") ~= "cannon" then
						continue
					end
					modelTrove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
						updateModel(math.min(cannonConfig.maxLevel, v.Value + 10))
					end))
					updateModel(math.min(cannonConfig.maxLevel, v.Value + 10))
				end
			end,
			callbackFunction = function(success, states)
				if success then
					switchPlatformColor(states.model, SUCCESS_COLOR)
				else
					switchPlatformColor(states.model, FAILURE_COLOR)
				end

				task.delay(0.5, function()
					switchPlatformColor(states.model, states.targetColor)
				end)
			end,
		},
	},
}
