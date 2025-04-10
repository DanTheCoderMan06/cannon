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
	zap.dataChanged.SetCallback(function(data)
		print("[DataController] Received data update via dataChanged event.")
		dataController.currentData = data
		if not loadedData then
			loadedData = true
			dataLoadedEvent:Fire() -- Fire loaded event if this is the first data received
		end
		dataChangedEvent:Fire(data) -- Fire specific changed event
	end)

	-- Request initial data with timeout
	task.spawn(function()
		task.wait(5)
		if loadedData then
			return
		end

		local result = zap.requestData.Call()
		dataController.currentData = result
		loadedData = true
		dataLoadedEvent:Fire()
		dataChangedEvent:Fire(dataController.currentData)
	end)
end

return dataController
