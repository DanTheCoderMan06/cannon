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

local playerBase = DataStoreService:GetDataStore("playerBaseStore")
local availableServers = MemoryStoreService:GetHashMap("availableServers")
local currentInfo = MemoryStoreService:GetHashMap("currentInfo")

local TASK_KEY = "tasks"
local IDS_PER_TASK = 5
local GAME_JOB_ID = not RunService:IsStudio() and game.JobId or "STUDIO"

print(GAME_JOB_ID)

local currentIndex = 0
local currentPage = 0

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

function notificationService.sendNotification(userId, info, notificationKey, timeElapsed)
	local savedUserData = dataService.getGlobalPlayerData(userId)

	if not savedUserData then
		warn("Tried to get data for " .. tostring(userId))
		return false
	end

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
		if not lastPlayed then
			lastPlayed:SetAsync(dataEntry.KeyName, os.time())
		end
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
	local keysPage

	pcallFunction(function()
		keysPage = playerBase:ListKeysAsync("", IDS_PER_TASK)
	end)

	currentPage = 0
	currentIndex = 0

	local currentPageCounter = 0

	while true do
		if currentPage < taskInfo.page then
			if keysPage.IsFinished then
				return
			end
			pcallFunction(function()
				keysPage:AdvanceToNextPageAsync()
			end)
			continue
		end

		currentPage += 1

		local currentUserPage
		pcallFunction(function()
			currentUserPage = keysPage:GetCurrentPage()
		end)

		for i, v in ipairs(currentUserPage) do
			print(v)
			if i < taskInfo.start then
				continue
			end
			currentIndex += 1
			notificationService.sendNotifications(v)
		end

		currentIndex = 0
		if keysPage.IsFinished then
			return
		end
		pcallFunction(function()
			keysPage:AdvanceToNextPageAsync()
		end)

		taskInfo.page = currentPage
		taskInfo.start = 0
	end
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

function notificationService.updateTaskInfo(newInfo: table)
	pcallFunction(function()
		currentInfo:SetAsync(TASK_KEY, newInfo, 7200)
	end)
end

function notificationService.fetchServer()
	local servers
	local serverIds = {}
	local targetServer = "NULL"

	pcallFunction(function()
		servers = availableServers:ListItemsAsync(100)
	end)

	pcallFunction(function()
		while not servers.IsFinished do
			local currentServerPage = servers:GetCurrentPage()

			for _, entry in pairs(currentServerPage) do
				table.insert(serverIds, entry.value)
			end

			if not servers.IsFinished then
				servers:AdvanceToNextPageAsync()
			end
		end
	end)

	if #serverIds > 0 then
		targetServer = serverIds[math.random(1, #serverIds)]
	end

	return targetServer
end

function notificationService.start()
	if game.PrivateServerId ~= "" or RunService:IsStudio() then
		return
	end

	local startedWork = false

	pcallFunction(function()
		availableServers:SetAsync(GAME_JOB_ID, "Available", 300000)
	end)

	local currentTaskInfo

	--[[
	zap.hasNotificationsEnabled.SetCallback(function(player, data)
		local result = notificationService.canSendNotification(player)
		return result
	end)
	--]]

	if game.PrivateServerId ~= "" then
		return
	end

	local canWork = Signal.new()

	Players.PlayerAdded:Connect(function(player)
		pcallFunction(function()
			playerBase:SetAsync(player.UserId, os.time())
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		pcallFunction(function()
			playerBase:SetAsync(player.UserId, os.time())
		end)
	end)

	for _, v in pairs(Players:GetPlayers()) do
		pcallFunction(function()
			playerBase:SetAsync(v.UserId, os.time())
		end)
	end

	game:BindToClose(function()
		pcallFunction(function()
			availableServers:RemoveAsync(GAME_JOB_ID)
		end)
		if startedWork then
			currentTaskInfo.start = currentIndex
			currentTaskInfo.page = currentPage
			currentTaskInfo.jobId = notificationService.fetchServer()
			notificationService.updateTaskInfo(currentTaskInfo)
		else
			pcallFunction(function()
				currentTaskInfo = currentInfo:GetAsync(TASK_KEY)
			end)
			--Edge case for if shut down before work even though it was assigned here:
			if currentTaskInfo.jobId == GAME_JOB_ID then
				currentTaskInfo.jobId = notificationService.fetchServer()
				notificationService.updateTaskInfo(currentTaskInfo)
			end
		end
	end)

	task.spawn(function()
		while true do
			pcallFunction(function()
				currentTaskInfo = currentInfo:GetAsync(TASK_KEY)
			end)
			if not currentTaskInfo then
				canWork:Fire()
				return
			end
			if currentTaskInfo.jobId == GAME_JOB_ID or currentTaskInfo.jobId == "NULL" then
				canWork:Fire()
			end
			task.wait(2)
		end
	end)

	canWork:Wait()

	startedWork = true

	if not currentTaskInfo then
		currentTaskInfo = {
			start = 0,
			page = 0,
		}
	end

	currentTaskInfo.jobId = GAME_JOB_ID

	notificationService.updateTaskInfo(currentTaskInfo)

	local foundTask
	task.spawn(function()
		while true do
			local taskInfo = {
				start = currentTaskInfo.start,
				page = currentTaskInfo.page,
			}

			notificationService.completeWork(taskInfo)
			currentTaskInfo.start = 0
			currentTaskInfo.page = 0

			task.wait(10)

			print("FINISHED TASK: ")

			task.wait(10)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(15)
			notificationService.updateTaskInfo(currentTaskInfo)
		end
	end)
end

return notificationService
