local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local boughtLevels = 0

local dataController = require(ReplicatedStorage.client.controllers.dataController)

local zap = require(ReplicatedStorage.zap)

local spr = require(ReplicatedStorage.sharedPackages.spr)

local gamepassConfig = require(ReplicatedStorage.shared.config.gamepassConfig)

return {
	cannon = {
		callback = function(callbackEvent)
			local success = zap.purchaseCannon.Call("cannon")
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
						title = "LEVEL " .. v.Value,
						description = tostring(cannonConfig.costFormula(v.Value + 1, playerData.boughtFloors)) .. "$",
					})
				end))
			end
			trove:Add(dataController.dataChanged:Connect(function(newdata)
				playerData = newdata
				updateEvent:Fire({
					title = "LEVEL " .. cannonValue.Value,
					description = tostring(cannonConfig.costFormula(cannonValue.Value + 1, playerData.boughtFloors))
						.. "$",
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
						description = tostring(cannonConfig.costFormula(v.Value + 1, playerData.boughtFloors)) .. "$",
					}
				end
			end
		end,
		initModel = function(modelTrove, updateModelEvent)
			local Players = game:GetService("Players")
			local stats = Players.LocalPlayer:WaitForChild("leaderstats")
			local function updateModel(value)
				local newModel =
					ReplicatedStorage.assets.minicannons:FindFirstChild(cannonConfig.getCannon(value + 1)):Clone()
				updateModelEvent:Fire(newModel)
			end
			for _, v in pairs(stats:GetChildren()) do
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
			for _, v in pairs(stats:GetChildren()) do
				if v:GetAttribute("statName") ~= "floors" then
					continue
				end
				trove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
					updateEvent:Fire({
						title = "+1 FLOOR",
						description = tostring(cannonConfig.costFormula(v.Value + 1, boughtLevels)) .. "$",
					})
				end))
			end
		end,
		init = function()
			local Players = game:GetService("Players")
			local stats = Players.LocalPlayer:WaitForChild("leaderstats")
			for _, v in pairs(stats:GetChildren()) do
				if v:GetAttribute("statName") == "floors" then
					return {
						title = "+1 FLOOR",
						description = tostring(cannonConfig.costFormula(v.Value + 1, boughtLevels)) .. "$",
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
	buyArtillery = {
		callback = function()
			MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, gamepassConfig.buyArtillery.id)
		end,
		title = "ARTILLERY",
		description = '100 <font color="#008000">\u{E002}</font>',
		initModel = ReplicatedStorage.assets.miniArtillery,
		--[[function(modelTrove, updateModelEvent) old double cannon
			local function updateModel(value)
				local newModel =
					ReplicatedStorage.assets.minicannons:FindFirstChild(cannonConfig.getNextCannon(value)):Clone()
				local newModel2 = newModel:Clone()
				local oldNewModelCFrame = newModel.PrimaryPart.CFrame

				newModel:PivotTo(oldNewModelCFrame * CFrame.new(0, 0, 2))
				newModel2:PivotTo(oldNewModelCFrame * CFrame.new(0, 0, -2))

				local newDoubleModel = Instance.new("Model")
				local newPrimaryPart = newModel.PrimaryPart:Clone()
				newPrimaryPart:ClearAllChildren()

				newPrimaryPart.Parent = newDoubleModel
				newDoubleModel.PrimaryPart = newPrimaryPart
				newPrimaryPart.CFrame = oldNewModelCFrame

				newModel.Parent = newDoubleModel
				newModel2.Parent = newDoubleModel

				for _, v in pairs(newDoubleModel:GetChildren()) do
					if v:IsA("Model") then
						local w = Instance.new("Weld")
						w.Part0 = newDoubleModel.PrimaryPart
						w.Part1 = v.PrimaryPart
						w.C0 = v.PrimaryPart.CFrame:ToObjectSpace(newDoubleModel.PrimaryPart.CFrame)
						w.Name = "DoubleWeld"
						w.Parent = newDoubleModel.PrimaryPart
						v.PrimaryPart.Anchored = false
					end
				end

				updateModelEvent:Fire(newDoubleModel)
			end
			local Players = game:GetService("Players")
			local stats = Players.LocalPlayer:WaitForChild("leaderstats")
			for _, v in pairs(stats:GetChildren()) do
				if v:GetAttribute("statName") ~= "cannon" then
					continue
				end
				modelTrove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
					updateModel(v.Value)
				end))
				updateModel(v.Value)
			end
		end,
		--]]
	},
	newCannon = {
		callback = function()
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, gamepassConfig.newCannon.id)
		end,
		title = "UPGRADE CANNON",
		description = '100 <font color="#008000">\u{E002}</font>',
		initModel = function(modelTrove, updateModelEvent)
			local Players = game:GetService("Players")
			local stats = Players.LocalPlayer:WaitForChild("leaderstats")
			local function updateModel(value)
				local newModel =
					ReplicatedStorage.assets.minicannons:FindFirstChild(cannonConfig.getNextCannon(value)):Clone()
				updateModelEvent:Fire(newModel)
			end
			for _, v in pairs(stats:GetChildren()) do
				if v:GetAttribute("statName") ~= "cannon" then
					continue
				end
				modelTrove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
					updateModel(v.Value)
				end))
				updateModel(v.Value)
			end
		end,
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
}
