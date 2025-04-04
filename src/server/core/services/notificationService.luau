local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
-- Debug flag - set to true ONLY when actively debugging issues
local DEBUG = false

-- Debug logging function (kept for potential future debugging)
local function debugLog(message)
	if DEBUG then
		print("[NotificationService DEBUG] " .. message)
	end
end

-- Required modules
local OCUserNotification = require(ServerStorage.OpenCloud.V2.UserNotification)
-- local zap = require(ServerStorage.zap) -- Not used?
local Sift = require(ReplicatedStorage.sharedPackages.Sift)
-- local Signal = require(ReplicatedStorage.sharedPackages.Signal) -- Not used?
local dataService = require(ServerStorage.server.services.dataService)

-- Config references
local notificationConfig = require(ReplicatedStorage.shared.config.notificationConfig)

-- Service definition
local notificationService = {}

-- Constants
local GAME_JOB_ID = RunService:IsStudio() and "STUDIO" or game.JobId
local SERVER_HEARTBEAT_SECONDS = 15
local SERVER_TIMEOUT_SECONDS = 60
local SERVER_SELECTION_INTERVAL = 3
local TASK_KEY = "notification_tasks"
local ITEMS_PER_PAGE = 100
local MINIMUM_PLAYERS_FOR_TASK = 5

-- Memory stores
local availableServers = MemoryStoreService:GetHashMap("available_servers")
local taskInfo = MemoryStoreService:GetHashMap("notification_task_info")

-- DataStore
local playerBase = DataStoreService:GetDataStore("playersBaseStore")

-- Task state
local currentPage = 0
local currentIndex = 0
local isTaskServer = false
-- local isProcessingTask = false -- Not explicitly used after assignment
local assignedSuccessor = false
local predecessorExitHandled = false

-- Safe call wrapper for DataStore/MemoryStore operations
local function safeCall(callback, resultVar)
	if RunService:IsStudio() then
		resultVar.value = callback()
		return true
	end

	local success
	local attempts = 0
	local maxAttempts = 2

	repeat
		attempts = attempts + 1
		success = pcall(function()
			resultVar.value = callback()
		end)

		if not success then
			-- Minimal logging on failure attempts, rely on final warn/error
			task.wait(1)
		end
	until success or attempts >= maxAttempts

	return success
end

-- Sort notifications by priority (highest to lowest)
local function getSortedNotificationsByPriority()
	local sortedNotifications = {}
	for key, info in pairs(notificationConfig.notifications) do
		table.insert(sortedNotifications, {
			key = key,
			info = info,
			priority = info.priority or 0,
		})
	end
	table.sort(sortedNotifications, function(a, b)
		return a.priority > b.priority
	end)
	return sortedNotifications
end

function notificationService.sendNotification(userId, info, notificationKey, timeElapsed)
	local fetchedData = dataService.fetchOfflinePlayerData(userId)

	if not fetchedData then
		warn("[Notification Service] Failed to fetch data for user ID: " .. tostring(userId))
		return false
	end

	if typeof(fetchedData.notificationQueue) ~= "table" then
		warn(
			"[Notification Service] Invalid notificationQueue structure for user "
				.. userId
				.. " (Type: "
				.. typeof(fetchedData.notificationQueue)
				.. "). Skipping."
		)
		return false
	end

	local amountExisting = 1
	if info.multiple then
		for _, v in pairs(fetchedData.notificationQueue) do
			if v == notificationKey then
				amountExisting += 1
			end
		end
	else
		if Sift.Array.includes(fetchedData.notificationQueue, notificationKey) then
			return false
		end
	end

	if amountExisting * info.waitTime > timeElapsed then
		return false
	end

	print("Attempting to send notification " .. notificationKey .. " to user " .. userId)
	local userNotification = {
		payload = {
			messageId = info.assetid,
			type = "MOMENT",
			parameters = info.parseParameters(userId, fetchedData),
		},
	}

	local apiSuccess, result = pcall(function()
		return OCUserNotification.createUserNotification(userId, userNotification)
	end)

	local notificationSentSuccessfully = false
	if not apiSuccess then
		warn(
			"[Notification Service] Open Cloud API pcall failed for user ID: "
				.. tostring(userId)
				.. " - Error: "
				.. tostring(result)
		)
	elseif result.statusCode ~= 200 then
		local statusCode = result.statusCode or "unknown"
		local responseBody = result.body or "{no body}"
		warn(
			"[Notification Service] Open Cloud API Error for user ID: "
				.. tostring(userId)
				.. " - Status: "
				.. statusCode
				.. ", Body: "
				.. responseBody
		)
	else
		notificationSentSuccessfully = true
		print(
			"[Notification Service] Successfully sent notification "
				.. notificationKey
				.. " via API for user "
				.. userId
		)
	end

	if notificationSentSuccessfully then
		local updateSuccess = dataService.updateOfflinePlayerData(userId, function(offlineData)
			if typeof(offlineData.notificationQueue) == "table" then
				table.insert(offlineData.notificationQueue, notificationKey)
			else
				warn("[Notification Service] Initializing notificationQueue during update for user " .. userId)
				offlineData.notificationQueue = { notificationKey }
			end
		end)

		if updateSuccess then
			print("[Notification Service] Successfully updated notificationQueue for user " .. userId)
			return true
		else
			warn("[Notification Service] API call succeeded but failed to update notificationQueue for user " .. userId)
			return false
		end
	else
		return false
	end
end

function notificationService.processPlayerNotifications(playerUserId)
	print("[Notification Service] Processing notifications for user ID: " .. tostring(playerUserId)) -- Added processing notification
	local lastPlayed = { value = nil }
	local success = safeCall(function()
		local time = playerBase:GetAsync(playerUserId)
		if not time then
			-- Keep this debug log as it indicates a potential issue or first-time player
			debugLog("No last played time found for user " .. playerUserId .. ", setting to current time")
			time = os.time()
			playerBase:SetAsync(playerUserId, time)
		end
		return time
	end, lastPlayed)

	if not success or not lastPlayed.value then
		warn(
			"[Notification Service] Failed to get/set last played time for user ID: "
				.. tostring(playerUserId)
				.. ". Skipping."
		) -- Added warning
		return -- Failed to get/set last played time
	end

	local timeElapsed = os.time() - lastPlayed.value
	local sortedNotifications = getSortedNotificationsByPriority()

	for _, notificationData in ipairs(sortedNotifications) do
		local sent = notificationService.sendNotification(
			tonumber(playerUserId),
			notificationData.info,
			notificationData.key,
			timeElapsed
		)
		if sent then
			break -- Only send one notification per check
		end
	end
end

-- Process a batch of players from the database
function notificationService.processBatch(pageIndex, startIndex)
	local keysPage = { value = nil }
	local success = safeCall(function()
		return playerBase:ListKeysAsync("", ITEMS_PER_PAGE)
	end, keysPage)

	if not success or not keysPage.value then
		if DEBUG then
			warn("[Notification Service] Failed to get player list")
		end
		return false, 0, 0
	end

	local currentPageNumber = 0
	while currentPageNumber < pageIndex and not keysPage.value.IsFinished do
		success = safeCall(function()
			keysPage.value:AdvanceToNextPageAsync()
			return true
		end, { value = nil })

		if not success then
			if DEBUG then
				warn("[Notification Service] Failed to advance to page " .. pageIndex)
			end
			return false, currentPageNumber, 0
		end
		currentPageNumber += 1
	end

	local entriesResult = { value = nil }
	success = safeCall(function()
		return keysPage.value:GetCurrentPage()
	end, entriesResult)

	if not success then
		return false, currentPageNumber, 0
	end

	local entries = entriesResult.value
	for i, entry in ipairs(entries) do
		if not tonumber(entry.KeyName) or tonumber(entry.KeyName) <= 0 then
			continue
		end
		if i < startIndex then
			continue
		end
		notificationService.processPlayerNotifications(entry.KeyName)
		currentIndex = i + 1 -- Update progress immediately after processing
	end

	local isFinished = keysPage.value.IsFinished
	local nextPage = isFinished and 0 or pageIndex + 1
	local nextIndex = isFinished and 0 or 0 -- Reset index if moving to next page or finished
	return true, nextPage, nextIndex
end

-- Save the current task progress
function notificationService.saveTaskProgress(nextPage, nextIndex, nextServerId)
	-- Keep this debug log as it's crucial for tracking task state
	if DEBUG then
		debugLog(
			"Saving task progress - page: "
				.. nextPage
				.. ", index: "
				.. nextIndex
				.. ", server: "
				.. (nextServerId or GAME_JOB_ID)
		)
	end

	local taskData = {
		page = nextPage,
		index = nextIndex,
		serverId = nextServerId or GAME_JOB_ID,
		updatedAt = os.time(),
	}

	safeCall(function()
		taskInfo:SetAsync(TASK_KEY, taskData, 7200 * 24) -- 48 hour expiry
		return true
	end, { value = nil })
end

-- Get a list of available servers (excluding our own)
function notificationService.getAvailableServers()
	local availableServersList = {}
	local servers = { value = nil }
	local success = safeCall(function()
		return availableServers:GetRangeAsync(1, 100)
	end, servers)

	if success and servers.value then
		for _, serverData in ipairs(servers.value) do
			if serverData.key ~= GAME_JOB_ID then
				table.insert(availableServersList, serverData.key)
			end
		end
	end
	return availableServersList
end

-- Choose the next task server
function notificationService.chooseNextTaskServer()
	local availableServersList = notificationService.getAvailableServers()
	if #availableServersList > 0 then
		return availableServersList[math.random(1, #availableServersList)]
	end
	-- Keep this debug log as it's important for task assignment issues
	if DEBUG then
		debugLog("No available servers found, returning NULL")
	end
	return "NULL"
end

-- Check if this server should be the task server
function notificationService.checkTaskAssignment()
	if RunService:IsStudio() then
		return true
	end
	if game.PrivateServerId ~= "" then
		return false
	end
	if #Players:GetPlayers() < MINIMUM_PLAYERS_FOR_TASK then
		return false
	end

	local currentTask = { value = nil }
	local success = safeCall(function()
		return taskInfo:GetAsync(TASK_KEY)
	end, currentTask)

	if success and currentTask.value then
		if currentTask.value.serverId == GAME_JOB_ID then
			return true -- Already assigned to us
		end
		if not predecessorExitHandled and currentTask.value.serverId == "PENDING_" .. GAME_JOB_ID then
			notificationService.saveTaskProgress(currentTask.value.page, currentTask.value.index, GAME_JOB_ID)
			predecessorExitHandled = true
			return true -- Assigned as pending, take over
		end

		local serverTimestamp = { value = nil }
		success = safeCall(function()
			return availableServers:GetAsync(currentTask.value.serverId)
		end, serverTimestamp)

		if
			(not success or not serverTimestamp.value)
			and (os.time() - currentTask.value.updatedAt > SERVER_TIMEOUT_SECONDS)
			and currentTask.value.serverId ~= "NULL"
		then
			notificationService.saveTaskProgress(currentTask.value.page, currentTask.value.index, GAME_JOB_ID)
			return true -- Task server gone or stale, take over
		end
	else
		if #Players:GetPlayers() >= MINIMUM_PLAYERS_FOR_TASK then
			notificationService.saveTaskProgress(0, 0, GAME_JOB_ID)
			return true -- No task, claim it
		end
	end
	return false -- Not eligible
end

-- Check if we're the task server (or should be) and verify the task record
function notificationService.verifyTaskAssignment()
	local currentTask = { value = nil }
	local success = safeCall(function()
		return taskInfo:GetAsync(TASK_KEY)
	end, currentTask)

	if success and currentTask.value then
		if
			currentTask.value.serverId == "NULL"
			or (os.time() - currentTask.value.updatedAt > SERVER_TIMEOUT_SECONDS)
		then
			-- Keep this debug log as it's important for task recovery
			if DEBUG then
				debugLog(
					"Task server is NULL or stale (updated "
						.. (os.time() - currentTask.value.updatedAt)
						.. " seconds ago)"
				)
			end
			if #Players:GetPlayers() >= MINIMUM_PLAYERS_FOR_TASK then
				notificationService.saveTaskProgress(currentTask.value.page, currentTask.value.index, GAME_JOB_ID)
				return true -- Take over NULL or stale task
			end
		else
			local serverTimestamp = { value = nil }
			success = safeCall(function()
				return availableServers:GetAsync(currentTask.value.serverId)
			end, serverTimestamp)
			if not success or not serverTimestamp.value then
				if #Players:GetPlayers() >= MINIMUM_PLAYERS_FOR_TASK then
					notificationService.saveTaskProgress(currentTask.value.page, currentTask.value.index, GAME_JOB_ID)
					return true -- Take over from unavailable server
				end
			end
		end
	else
		if #Players:GetPlayers() >= MINIMUM_PLAYERS_FOR_TASK then
			notificationService.saveTaskProgress(0, 0, GAME_JOB_ID)
			return true -- No task record, create one
		end
	end
	return false -- Not taking task server role
end

-- Main task processing loop
function notificationService.processNotificationTasks()
	isProcessingTask = true
	local currentTask = { value = nil }
	local success = safeCall(function()
		return taskInfo:GetAsync(TASK_KEY)
	end, currentTask)

	if not success or not currentTask.value then
		currentTask.value = { page = 0, index = 0 }
	end

	currentPage = currentTask.value.page
	currentIndex = currentTask.value.index

	while isTaskServer do
		local batchSuccess, nextPage, nextIndex = notificationService.processBatch(currentPage, currentIndex)
		if batchSuccess then
			currentPage = nextPage
			currentIndex = nextIndex
			notificationService.saveTaskProgress(currentPage, currentIndex)

			-- Check if we finished the list
			if nextPage == 0 and nextIndex == 0 then
				-- Finished processing all players, wait 20 seconds before restarting
				if DEBUG then
					debugLog("Finished processing all players, waiting 20 seconds.")
				end
				task.wait(20)
			else
				-- Wait 10 seconds before processing the next batch
				if DEBUG then
					debugLog("Batch processed, waiting 10 seconds.")
				end
				task.wait(10)
			end
		else
			-- If batch processing failed, wait 10 seconds before retrying
			if DEBUG then
				debugLog("Batch processing failed, waiting 10 seconds.")
			end
			task.wait(10)
		end
		-- Original task.wait(0.5) removed
	end
	isProcessingTask = false
end

-- Assign a successor server and transition the task
function notificationService.assignSuccessor()
	if assignedSuccessor then
		return
	end

	local currentTask = { value = nil }
	local success = safeCall(function()
		return taskInfo:GetAsync(TASK_KEY)
	end, currentTask)

	if not success or not currentTask.value or currentTask.value.serverId == GAME_JOB_ID then
		local nextServerId = notificationService.chooseNextTaskServer()
		assignedSuccessor = true
		if nextServerId ~= "NULL" then
			local pendingId = "PENDING_" .. nextServerId
			notificationService.saveTaskProgress(currentPage, currentIndex, pendingId)
			task.delay(2, function()
				notificationService.saveTaskProgress(currentPage, currentIndex, nextServerId)
			end)
		else
			notificationService.saveTaskProgress(currentPage, currentIndex, "NULL")
		end
	end
end

-- Remove server from the pool
function notificationService.unregisterServer()
	safeCall(function()
		availableServers:RemoveAsync(GAME_JOB_ID)
		return true
	end, { value = nil })

	if isTaskServer then
		notificationService.assignSuccessor()
	else
		local currentTask = { value = nil }
		local success = safeCall(function()
			return taskInfo:GetAsync(TASK_KEY)
		end, currentTask)
		if success and currentTask.value and currentTask.value.serverId == GAME_JOB_ID then
			notificationService.assignSuccessor() -- Assign successor even if we didn't know we were the task server
		end
	end
end

-- Setup the server heartbeat
function notificationService.startServerHeartbeat()
	safeCall(function()
		availableServers:SetAsync(GAME_JOB_ID, os.time(), SERVER_TIMEOUT_SECONDS * 2)
		return true
	end, { value = nil })

	task.spawn(function()
		while true do
			safeCall(function()
				availableServers:SetAsync(GAME_JOB_ID, os.time(), SERVER_TIMEOUT_SECONDS * 2)
				return true
			end, { value = nil })
			task.wait(SERVER_HEARTBEAT_SECONDS)
		end
	end)
end

-- Initialize service
function notificationService.start()
	if game.PrivateServerId ~= "" then
		return
	end -- Don't run in private servers

	Players.PlayerAdded:Connect(function(player)
		safeCall(function()
			playerBase:SetAsync(player.UserId, os.time())
			return true
		end, { value = nil })
	end)

	Players.PlayerRemoving:Connect(function(player)
		safeCall(function()
			playerBase:SetAsync(player.UserId, os.time())
			return true
		end, { value = nil })
	end)

	for _, player in pairs(Players:GetPlayers()) do
		safeCall(function()
			playerBase:SetAsync(player.UserId, os.time())
			return true
		end, { value = nil })
	end

	notificationService.startServerHeartbeat()

	game:BindToClose(function()
		notificationService.unregisterServer()
	end)

	task.delay(5, function()
		if notificationService.verifyTaskAssignment() then
			isTaskServer = true
			task.spawn(notificationService.processNotificationTasks)
			-- Keep important state change log
			-- print("[Notification Service] This server is now the notification task server (recovery)") -- Removed as potentially noisy
		end
	end)

	task.spawn(function()
		while true do
			local shouldBeTaskServer = notificationService.checkTaskAssignment()
			if shouldBeTaskServer and not isTaskServer then
				isTaskServer = true
				task.spawn(notificationService.processNotificationTasks)
				-- Keep important state change log
				-- print("[Notification Service] This server is now the notification task server") -- Removed as potentially noisy
			elseif not shouldBeTaskServer then
				isTaskServer = false
			end
			task.wait(SERVER_SELECTION_INTERVAL)
		end
	end)
end

return notificationService
