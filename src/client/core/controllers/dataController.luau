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
		task.wait(5) -- Wait initial 5 seconds
		if loadedData then
			return -- Data already loaded via push event
		end

		local result = nil
		local retries = 0
		local MAX_RETRIES = 3
		local RETRY_DELAY = 2 -- seconds

		while not result and retries < MAX_RETRIES do
			print(
				string.format("[DataController] Requesting initial data (Attempt %d/%d)...", retries + 1, MAX_RETRIES)
			)
			result = zap.requestData.Call() -- Attempt to get data

			if not result then
				retries += 1
				if retries < MAX_RETRIES then
					print(string.format("[DataController] Data request failed. Retrying in %d seconds...", RETRY_DELAY))
					task.wait(RETRY_DELAY)
				else
					warn("[DataController] Failed to load initial data after multiple retries.")
					-- Optionally handle persistent failure here, e.g., show an error UI
					return -- Exit the task if all retries fail
				end
			end
		end

		-- Only proceed if data was successfully loaded
		if result then
			print("[DataController] Initial data loaded successfully via request.")
			dataController.currentData = result
			loadedData = true
			dataLoadedEvent:Fire()
			dataChangedEvent:Fire(dataController.currentData)
		end
	end)
end

return dataController
