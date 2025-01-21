local ReplicatedStorage = game:GetService("ReplicatedStorage")

local zap = require(ReplicatedStorage.zap)
local Signal = require(ReplicatedStorage.sharedPackages.Signal)

local dataChangedEvent = Signal.new()
local dataLoadedEvent = Signal.new()
local dataController = {}

dataController.dataChanged = dataChangedEvent

dataController.currentData = {}

local loadedData = false

function dataController.getData()
	if not loadedData then
		dataLoadedEvent:Wait()
	end
	return dataController.currentData
end

function dataController.start()
	zap.dataChanged.SetCallback(function(data)
		dataChangedEvent:Fire(data)
	end)

	dataChangedEvent:Connect(function(newData)
		dataController.currentData = newData
		loadedData = true
		dataLoadedEvent:Fire()
	end)
end

return dataController
