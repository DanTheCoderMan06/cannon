local ReplicatedStorage = game:GetService("ReplicatedStorage")

local zap = require(ReplicatedStorage.zap)
local Signal = require(ReplicatedStorage.sharedPackages.Signal)

local dataChangedEvent = Signal.new()

local dataController = {}

dataController.dataChanged = dataChangedEvent

dataController.currentData = {}

function dataController.start()
	zap.dataChanged.SetCallback(function(data)
		dataChangedEvent:Fire(data)
	end)

	dataChangedEvent:Connect(function(newData)
		dataController.currentData = newData
	end)
end

return dataController
