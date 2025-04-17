local ReplicatedStorage = game:GetService("ReplicatedStorage")

local zap = require(ReplicatedStorage.zap)
local Signal = require(ReplicatedStorage.sharedPackages.Signal)
local Sift = require(ReplicatedStorage.sharedPackages.Sift)
local Promise = require(ReplicatedStorage.sharedPackages.Promise) -- Assuming Promise library

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
	return Sift.Dictionary.copyDeep(dataController.currentData)
end

function dataController.start()
	-- Listen for subsequent data changes from the server
	local initialData = zap.requestData.Call()

	while not initialData do
		task.wait()
		initialData = zap.requestData.Call()
	end

	task.delay(2, function()
		loadedData = true
		dataController.currentData = initialData
		dataLoadedEvent:Fire()
		task.delay(1, function()
			dataChangedEvent:Fire(initialData)
		end)
	end)

	zap.dataChanged.SetCallback(function(data)
		print("[DataController] Received data update via dataChanged event.")
		dataChangedEvent:Fire(data)
		dataController.currentData = data
	end)

	task.spawn(function()
		while true do
			local newData = zap.requestData.Call()
			dataChangedEvent:Fire(newData)
			dataController.currentData = newData
			task.wait(10)
		end
	end)
end

return dataController
