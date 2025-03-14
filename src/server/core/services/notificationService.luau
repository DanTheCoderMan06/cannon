local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local OCUserNotification = require(ServerStorage.OpenCloud.V2.UserNotification)
local zap = require(ServerStorage.zap)
local Sift = require(ReplicatedStorage.sharedPackages.Sift)
local Signal = require(ReplicatedStorage.sharedPackages.Signal)

local folderService = require(script.Parent.folderService)

local notificationService = {}

notificationService.currentTasks = {}

notificationService.currentTask = nil

local playerBase = DataStoreService:GetDataStore("playerBase")
local serverTasks = MemoryStoreService:GetHashMap("serverTasks")
local lastChecked = MemoryStoreService:GetHashMap("lastChecked")

local currentIndex = 0
local idsPerTask = 1

local notificationConfig = require(ReplicatedStorage.shared.config.notificationConfig)
local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

local dataService = require(ServerStorage.server.services.dataService)

local function pcallFunction(callback)
	if RunService:IsStudio() then
		callback()
		return
	end
	local s, r = pcall(callback)

	while not s do
		task.wait(1)
		warn(r .. " RETRYING.")
		s, r = pcall(callback)
	end
end

function notificationService.retrieveTask()
	local currentTasks
	pcallFunction(function()
		print("Access")
		currentTasks = serverTasks:ListItemsAsync(5)
	end)

	local foundTask
	local lastTask
	local foundKey

	while not foundTask do
		local currentPage = currentTasks:GetCurrentPage()
		for _, key in pairs(currentPage) do
			print(key.KeyName)
			local taskInfo
			pcallFunction(function()
				print("Access")
				taskInfo = serverTasks:GetAsync(key.KeyName)
			end)
			if RunService:IsStudio() then
				print("TASK FOUND: " .. HttpService:JSONEncode(taskInfo))
			end
			if not lastTask then
				lastTask = taskInfo
			elseif tonumber(lastTask.timeCreated) < tonumber(taskInfo.timeCreated) then
				lastTask = taskInfo
			end
			if taskInfo.occupied then
				continue
			end
			foundTask = taskInfo
			foundKey = key.KeyName
		end
		if currentTasks.IsFinished then
			break
		end
		pcallFunction(function()
			currentTasks:AdvanceToNextPageAsync()
		end)
	end
	return { found = foundTask, last = lastTask, foundIndex = foundKey }
end

function notificationService.addTask(endTask)
	local lastCheckedIndex
	local startIndex = 0

	if endTask then
		if endTask.finish < notificationService.totalPlayerBase then
			startIndex = endTask.finish
		end
	else
		pcallFunction(function()
			print("Access")
			lastCheckedIndex = lastChecked:GetAsync("lastChecked")
		end)
		if lastCheckedIndex then
			if lastCheckedIndex < notificationService.totalPlayerBase then
				startIndex = lastCheckedIndex
			end
		end
	end

	local currentTime = os.time()
	local uid = HttpService:GenerateGUID(false)
	local newTask = {
		start = startIndex,
		finish = startIndex + idsPerTask,
		occupied = true,
		timeCreated = currentTime,
		id = uid,
	}
	pcallFunction(function()
		print("Access")
		serverTasks:SetAsync(uid, newTask, 300000)
	end)
	return newTask
end

--For simple Notification (So that other services can use)
function notificationService.sendSimpleNotification(userId, assetId, params)
	local newParams = {}
	for key, value in pairs(params) do
		newParams[key] = { stringValue = value }
	end
	local userNotification = {
		payload = {
			messageId = assetId,
			type = "MOMENT",
			parameters = newParams,
		},
	}

	local result

	result = OCUserNotification.createUserNotification(userId, userNotification)

	local tries = 0

	while tries < 3 and result.statusCode ~= 200 do
		task.wait(1)
		warn("RETRYING TO SEND NOTIFICATION TO USER " .. userId)
		result = OCUserNotification.createUserNotification(userId, userNotification)
		tries += 1
	end
end

function notificationService.fetchMax()
	local keysPage
	local totalMax = 0
	pcallFunction(function()
		keysPage = playerBase:ListKeysAsync("", idsPerTask)
	end)
	totalMax += idsPerTask
	while true do
		if keysPage.IsFinished then
			break
		end
		pcallFunction(function()
			keysPage:AdvanceToNextPageAsync()
		end)
		totalMax += idsPerTask
	end
	return totalMax
end

function notificationService.sendNotification(userId, info, notificationKey, timeElapsed)
	local savedUserData = dataService.getGlobalPlayerData(userId)

	local amountExisting = 0

	if info.multiple then
		for _, v in pairs(savedUserData.Data.notificationQueue) do
			if v == notificationKey then
				amountExisting += 1
			end
		end
	else
		if Sift.Array.includes(savedUserData.Data.notificationQueue, notificationKey) then
			return false
		end
	end

	print(amountExisting)

	if amountExisting * info.waitTime > timeElapsed then
		return false
	end

	local userNotification = {
		payload = {
			messageId = info.assetid,
			type = "MOMENT",
			parameters = info.parseParameters(userId, savedUserData.Data),
		},
	}

	local result

	result = OCUserNotification.createUserNotification(userId, userNotification)

	local tries = 0

	while tries < 3 and result.statusCode ~= 200 do
		task.wait(1)
		warn("RETRYING TO SEND NOTIFICATION TO USER " .. userId)
		result = OCUserNotification.createUserNotification(userId, userNotification)
		tries += 1
	end

	table.insert(savedUserData.Data.notificationQueue, notificationKey)

	if not Players:GetPlayerByUserId(userId) or RunService:IsStudio() then
		pcallFunction(function()
			savedUserData:SetAsync()
		end)
	end

	print(result)

	return true
end

function notificationService.sendNotifications(dataEntry)
	task.wait(1)
	print("SENDING TO USER: " .. dataEntry.KeyName)
	local lastPlayed

	pcallFunction(function()
		lastPlayed = playerBase:GetAsync(dataEntry.KeyName)
	end)

	for i, v in pairs(notificationConfig.notifications) do
		print(os.time() - lastPlayed)
		print(v.waitTime)
		local success = notificationService.sendNotification(tonumber(dataEntry.KeyName), v, i, os.time() - lastPlayed)
		if success then
			break -- max is one
		end
	end
end

function notificationService.completeWork(taskInfo)
	pcallFunction(function()
		lastChecked:SetAsync("lastChecked", taskInfo.finish, 300000)
	end)

	local keysPage
	pcallFunction(function()
		keysPage = playerBase:ListKeysAsync("", idsPerTask)
	end)
	for i = 1, math.floor(taskInfo.start / idsPerTask) do
		if keysPage.IsFinished then
			return
		end
		pcallFunction(function()
			keysPage:AdvanceToNextPageAsync()
		end)
	end
	local currentPage
	pcallFunction(function()
		currentPage = keysPage:GetCurrentPage()
	end)
	currentIndex = 0
	print(currentPage)
	for i, v in ipairs(currentPage) do
		currentIndex += 1
		if taskInfo.stop then
			if currentIndex < taskInfo.stop then
				continue
			end
		end
		notificationService.sendNotifications(v)
	end
	currentIndex = taskInfo.finish
end

function notificationService.canSendNotification(player)
	local newParams = {}
	local userNotification = {
		payload = {
			messageId = notificationConfig.testNotification,
			type = "MOMENT",
			parameters = { name = { stringValue = player.Name } },
		},
	}

	local result

	result = OCUserNotification.createUserNotification(player.UserId, userNotification)

	local tries = 0

	while tries < 3 and result.statusCode ~= 200 do
		task.wait(1)
		warn("RETRYING TO SEND NOTIFICATION TO USER " .. player.UserId)
		result = OCUserNotification.createUserNotification(player.UserId, userNotification)
		tries += 1
	end

	return result.statusCode == 200
end

function notificationService.start()
	zap.hasNotificationsEnabled.SetCallback(function(player, data)
		local result = notificationService.canSendNotification(player)
		return result
	end)

	if game.PrivateServerId ~= "" or RunService:IsStudio() then
		return
	end
	local canWork = Signal.new()
	Players.PlayerAdded:Connect(function(player)
		if #Players:GetPlayers() > 7 then
			canWork:Fire()
		end
		pcallFunction(function()
			playerBase:SetAsync(player.UserId, os.time())
		end)
	end)
	for _, v in pairs(Players:GetPlayers()) do
		pcallFunction(function()
			playerBase:SetAsync(v.UserId, os.time())
		end)
	end

	if RunService:IsStudio() then
		task.delay(1, function()
			canWork:Fire()
		end)
	end

	--canWork:Wait()

	notificationService.totalPlayerBase = notificationService.fetchMax()

	local foundTask
	task.spawn(function()
		while true do
			foundTask = notificationService.retrieveTask()
			print("Retrieved Info" .. HttpService:JSONEncode(foundTask))
			local target = foundTask.found
			local endTask = foundTask.last

			if not target then
				target = notificationService.addTask(endTask)
			else
				target.occupied = true
				pcallFunction(function()
					print("Access")
					serverTasks:SetAsync(foundTask.foundIndex, target, 300000)
				end)
			end

			foundTask = target
			print("FOUND TASK: " .. HttpService:JSONEncode(foundTask))

			notificationService.completeWork(foundTask)
			task.wait(10)

			print("FINISHED TASK: " .. foundTask.id)

			serverTasks:RemoveAsync(foundTask.id)
			foundTask = nil
			task.wait(10)
		end
	end)

	game:BindToClose(function()
		if foundTask then
			print("Didnt Finish, Saving: " .. foundTask.id)
			foundTask.occupied = false
			foundTask.stop = currentIndex
			pcallFunction(function()
				serverTasks:SetAsync(foundTask.id, foundTask, 300000)
				print("Added task!")
			end)
		end
	end)
end

return notificationService
