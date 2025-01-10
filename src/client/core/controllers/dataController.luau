local ReplicatedStorage = game:GetService("ReplicatedStorage")

local zap = require(ReplicatedStorage.zap)
local Signal = require(ReplicatedStorage.sharedPackages.Signal)

local dataChanged = Signal.new()

local dataController = {}

dataController.dataChanged = dataChanged

dataController.currentData = {}

function dataController.start()
	zap.dataChanged.SetCallback(function(data)
		dataChanged:Fire(data)
	end)

	dataChanged:Connect(function(newData)
		dataController.currentData = newData
	end)
end

return dataController
