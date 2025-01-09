local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cannonConfig = require(ReplicatedStorage.shared.config.cannonConfig)
local boughtLevels = 0

return {
	cannon = {
		callback = function()
			print("Touched!")
		end,
		title = "UPGRADE CANNON",
		description = "N/A",
		updateValues = function(trove, updateEvent)
			local Players = game:GetService("Players")
			local stats = Players.LocalPlayer:WaitForChild("leaderstats")
			for _, v in pairs(stats:GetChildren()) do
				if v:GetAttribute("statName") ~= "cannon" then
					continue
				end
				trove:Add(v:GetPropertyChangedSignal("Value"):Connect(function()
					updateEvent:Fire({
						title = "LEVEL " .. v.Value,
						description = tostring(cannonConfig.costFormula(v.Value + 1, 0)) .. "$",
					})
				end))
			end
		end,
		init = function()
			local Players = game:GetService("Players")
			local stats = Players.LocalPlayer:WaitForChild("leaderstats")
			for _, v in pairs(stats:GetChildren()) do
				if v:GetAttribute("statName") == "cannon" then
					return {
						title = "LEVEL " .. v.Value,
						description = tostring(cannonConfig.costFormula(v.Value + 1, 0)) .. "$",
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
	},
	floor = {
		callback = function()
			print("Touched!")
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
	},
	tenFloors = {
		callback = function()
			print("Touched!")
		end,
		title = "+10 FLOORS",
		description = '100 <font color="#008000">\u{E002}</font>',
		initModel = ReplicatedStorage.assets.tenfloors,
	},
	fiftyFloors = {
		callback = function()
			print("Touched!")
		end,
		title = "+40 FLOORS",
		description = '100 <font color="#008000">\u{E002}</font>',
		initModel = ReplicatedStorage.assets.fiftyfloors,
	},
	doubleGunpowder = {
		callback = function()
			print("Touched!")
		end,
		title = "x2 POWER",
		description = '100 <font color="#008000">\u{E002}</font>',
		initModel = function(modelTrove, updateModelEvent)
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
	},
	newCannon = {
		callback = function()
			print("Touched!")
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
}
