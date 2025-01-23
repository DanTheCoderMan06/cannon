local DataStoreService = game:GetService("DataStoreService")
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
local serverTasks = DataStoreService:GetDataStore("notificationTask")

local currentIndex = 0
local idsPerTask = 500

local notificationConfig = require(ReplicatedStorage.shared.config.notificationConfig)
local rewardsConfig = require(ReplicatedStorage.shared.config.rewardsConfig)

local dataService = require(ServerStorage.server.services.dataService)

local function pcallFunction(callback)
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
		currentTasks = serverTasks:ListKeysAsync("", 100, "", true)
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
				taskInfo = serverTasks:GetAsync(key.KeyName)
			end)
			if not lastTask then
				lastTask = taskInfo
			elseif lastTask.finish < taskInfo.finish then
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

function notificationService.addTask(startIndex)
	local currentTime = os.time()
	local newTask = {
		start = startIndex,
		finish = startIndex + idsPerTask,
		occupied = true,
		id = currentTime,
	}
	pcallFunction(function()
		serverTasks:SetAsync(currentTime, newTask)
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
		task.wait(3)
		warn("RETRYING TO SEND NOTIFICATION TO USER " .. userId)
		result = OCUserNotification.createUserNotification(userId, userNotification)
		tries += 1
	end
end

function notificationService.sendNotification(userId, info, notificationKey)
	local savedUserData = dataService.getGlobalPlayerData(userId)

	if Sift.Array.includes(savedUserData.Data.notificationQueue, notificationKey) and userId ~= "880645672" then -- DEBUG: 880645672
		return
	end

	local userNotification = {
		payload = {
			messageId = info.assetid,
			type = "MOMENT",
			parameters = info.parseParameters(userId, savedUserData),
		},
	}

	local result

	result = OCUserNotification.createUserNotification(userId, userNotification)

	local tries = 0

	while tries < 3 and result.statusCode ~= 200 do
		task.wait(3)
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
		if os.time() - lastPlayed > v.waitTime then
			notificationService.sendNotification(tonumber(dataEntry.KeyName), v, i)
		end
	end
end

function notificationService.completeWork(taskInfo)
	local keysPage
	pcallFunction(function()
		keysPage = playerBase:ListKeysAsync("", idsPerTask)
	end)
	for i = 1, math.floor(taskInfo.start / idsPerTask) do
		if keysPage.IsFinished then
			return -- No tasks to do
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

function notificationService.start()
	if game.PrivateServerId ~= "" then
		return -- Private Server
	end
	local canWork = Signal.new()
	Players.PlayerAdded:Connect(function(player)
		if #Players:GetPlayers() > 7 then
			canWork:Fire()
		end
		pcallFunction(function()
			if not playerBase:GetAsync(player.UserId) then
				playerBase:SetAsync(player.UserId, os.time())
			else
				playerBase:SetAsync(player.UserId, os.time())
			end
		end)
	end)
	for _, v in pairs(Players:GetPlayers()) do
		pcallFunction(function()
			if not playerBase:GetAsync(v.UserId) then
				playerBase:SetAsync(v.UserId, os.time())
			else
				playerBase:SetAsync(v.UserId, os.time())
			end
		end)
	end

	if RunService:IsStudio() then
		task.delay(1, function()
			canWork:Fire()
		end)
	end

	canWork:Wait()

	local foundTask
	task.spawn(function()
		while true do
			foundTask = notificationService.retrieveTask()
			print("Retrieved Info" .. HttpService:JSONEncode(foundTask))
			local target = foundTask.found
			local endTask = foundTask.last

			if not target then
				target = notificationService.addTask(endTask ~= nil and endTask.finish or 0)
			else
				target.occupied = true
				pcallFunction(function()
					serverTasks:SetAsync(foundTask.foundIndex, target)
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
				serverTasks:SetAsync(foundTask.id, foundTask)
				print("Added task!")
			end)
		end
	end)

	dataService.dailyReward:Connect(function(player: Player, day: IntValue)
		local dailyReward = rewardsConfig.getDailyReward(day)
		if dailyReward then
			notificationService.sendSimpleNotification(player.UserId, rewardsConfig.rewardNotification.assetId, {
				rewardName = dailyReward.name,
			})
		end
	end)
end

return notificationService
