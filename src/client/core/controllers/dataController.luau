local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService") -- Added SoundService

local zap = require(ReplicatedStorage.zap)
local Signal = require(ReplicatedStorage.sharedPackages.Signal)
local Sift = require(ReplicatedStorage.sharedPackages.Sift)
local Promise = require(ReplicatedStorage.sharedPackages.Promise) -- Assuming Promise library

local dataChangedEvent = Signal.new()
local dataLoadedEvent = Signal.new()
local dataController = {}

local upgradeSound = SoundService:WaitForChild("effects"):WaitForChild("upgrade") -- Get upgrade sound

dataController.dataChanged = dataChangedEvent

dataController.currentData = {}

local loadedData = false
local previousData = nil -- Variable to store the previous data state

-- Helper function to check for upgrades and play sound
local function checkAndPlayUpgradeSound(newData, oldData)
	if not oldData then
		return -- Don't compare if there's no previous data
	end

	local playSound = false

	-- Check floors
	if newData.floors and oldData.floors and newData.floors > oldData.floors then
		playSound = true
	end

	-- Check cannon level
	if not playSound and newData.cannon and oldData.cannon and newData.cannon > oldData.cannon then
		playSound = true
	end

	-- Check gamepasses (assuming it's a dictionary/map)
	if not playSound and newData.cannons and oldData.cannons then
		local diff = Sift.Array.difference(oldData.cannons, newData.cannons)
		if #diff > 0 then
			playSound = true
		end
	end

	if playSound then
		upgradeSound:Play()
	end
end

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

	task.delay(0.1, function()
		loadedData = true
		previousData = initialData -- Store initial data as previous
		dataController.currentData = initialData
		dataLoadedEvent:Fire()
		task.delay(0.1, function()
			dataChangedEvent:Fire(initialData) -- Fire event AFTER setting previousData
		end)
	end)

	zap.dataChanged.SetCallback(function(data)
		print("[DataController] Received data update via dataChanged event.")
		checkAndPlayUpgradeSound(data, previousData) -- Check before updating previousData
		dataController.currentData = data
		previousData = data -- Update previousData
		dataChangedEvent:Fire(data)
	end)
end

return dataController
