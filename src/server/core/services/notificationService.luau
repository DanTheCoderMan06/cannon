local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Debug flag - set to true to enable debug logging
local DEBUG = true

-- Debug logging function
local function debugLog(message)
    if DEBUG then
        print("[NotificationService DEBUG] " .. message)
    end
end

debugLog("Module loading started")

-- Required modules
local OCUserNotification = require(ServerStorage.OpenCloud.V2.UserNotification)
local zap = require(ServerStorage.zap)
local Sift = require(ReplicatedStorage.sharedPackages.Sift)
local Signal = require(ReplicatedStorage.sharedPackages.Signal)
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

debugLog("Constants initialized - Job ID: " .. GAME_JOB_ID)

-- Memory stores
local availableServers = MemoryStoreService:GetHashMap("available_servers")
local taskInfo = MemoryStoreService:GetHashMap("notification_task_info")

-- DataStore
local playerBase = DataStoreService:GetDataStore("playerBaseStore")

-- Task state
local currentPage = 0
local currentIndex = 0
local isTaskServer = false
local isProcessingTask = false
local assignedSuccessor = false
local predecessorExitHandled = false

debugLog("Initial task state setup")

-- Safe call wrapper for DataStore/MemoryStore operations
local function safeCall(callback, resultVar)
    debugLog("Performing safe call operation")
    
    if RunService:IsStudio() then
        debugLog("In Studio mode - skipping retries")
        resultVar.value = callback()
        return true
    end
    
    local success
    local attempts = 0
    local maxAttempts = 3
    
    repeat
        attempts = attempts + 1
        local errorMsg
        
        success = pcall(function()
            resultVar.value = callback()
        end)
        
        if not success then
            warn("[Notification Service] Attempt " .. attempts .. " failed. Retrying...")
            debugLog("Safe call attempt " .. attempts .. " failed, waiting to retry")
            task.wait(1)
        end
    until success or attempts >= maxAttempts
    
    debugLog("Safe call completed with success: " .. tostring(success) .. " after " .. attempts .. " attempts")
    return success
end

-- Sort notifications by priority (highest to lowest)
local function getSortedNotificationsByPriority()
    debugLog("Getting sorted notifications by priority")
    local sortedNotifications = {}
    
    -- Get all notifications
    for key, info in pairs(notificationConfig.notifications) do
        table.insert(sortedNotifications, {
            key = key,
            info = info,
            priority = info.priority or 0
        })
    end
    
    -- Sort by priority (highest first)
    table.sort(sortedNotifications, function(a, b)
        return a.priority > b.priority
    end)
    
    debugLog("Found " .. #sortedNotifications .. " notifications to process")
    return sortedNotifications
end

-- Send a notification to a user
function notificationService.sendNotification(userId, info, notificationKey, timeElapsed)
    debugLog("Attempting to send notification " .. notificationKey .. " to user " .. userId)
    
    -- Get player data
    local userData = {value = nil}
    local success = safeCall(function()
        return dataService.getGlobalPlayerData(userId)
    end, userData)
    
    local savedUserData = userData.value
    if not success or not savedUserData then
        warn("[Notification Service] Failed to get data for user ID: " .. tostring(userId))
        debugLog("Failed to get user data, aborting notification send")
        return false
    end
    
    -- Check for duplicate notifications or frequency limits
    local amountExisting = 0
    if info.multiple then
        for _, v in pairs(savedUserData.Data.notificationQueue) do
            if v == notificationKey then
                amountExisting += 1
            end
        end
        debugLog("User has " .. amountExisting .. " existing notifications of type " .. notificationKey)
    else
        if Sift.Array.includes(savedUserData.Data.notificationQueue, notificationKey) then
            debugLog("User already has this non-repeatable notification, skipping")
            return false
        end
    end
    
    -- Check frequency limit
    if amountExisting * info.waitTime > timeElapsed then
        debugLog("Too frequent, not sending notification. Wait time: " .. (amountExisting * info.waitTime) .. ", time elapsed: " .. timeElapsed)
        return false
    end
    
    -- Prepare notification content
    local userNotification = {
        payload = {
            messageId = info.assetid,
            type = "MOMENT",
            parameters = info.parseParameters(userId, savedUserData.Data)
        }
    }
    
    debugLog("Notification payload prepared, sending to OpenCloud")
    
    -- Send the notification
    local result = {value = nil}
    success = safeCall(function()
        return OCUserNotification.createUserNotification(userId, userNotification)
    end, result)
    
    if not success or result.value.statusCode ~= 200 then
        warn("[Notification Service] Failed to send notification to user ID: " .. tostring(userId))
        debugLog("Failed to send notification, status code: " .. (result.value and result.value.statusCode or "unknown"))
        return false
    end
    
    -- Record that we sent this notification
    table.insert(savedUserData.Data.notificationQueue, notificationKey)
    debugLog("Added notification to user's queue: " .. notificationKey)
    
    -- Update player data if not in game
    if not Players:GetPlayerByUserId(userId) then
        debugLog("Player not in game, updating stored data")
        success = safeCall(function()
            savedUserData:SetAsync()
        end, {value = nil})
    end
    
    print("[Notification Service] Sent notification " .. notificationKey .. " to user " .. userId)
    debugLog("Notification sent successfully")
    return true
end

-- Process notifications for a player
function notificationService.processPlayerNotifications(playerUserId)
    debugLog("Processing notifications for user ID: " .. playerUserId)
    local lastPlayed = {value = nil}
    
    -- Get last played time
    local success = safeCall(function()
        local time = playerBase:GetAsync(playerUserId)
        if not time then
            debugLog("No last played time found, setting to current time")
            time = os.time()
            playerBase:SetAsync(playerUserId, time)
        end
        return time
    end, lastPlayed)
    
    -- No last played time? Skip processing
    if not success or not lastPlayed.value then 
        debugLog("Failed to get last played time, skipping player")
        return 
    end
    
    -- Calculate time elapsed since last play
    local timeElapsed = os.time() - lastPlayed.value
    debugLog("Time since last play: " .. timeElapsed .. " seconds")
    
    -- Get sorted notifications by priority
    local sortedNotifications = getSortedNotificationsByPriority()
    
    -- Try to send notifications in priority order
    for _, notificationData in ipairs(sortedNotifications) do
        debugLog("Trying notification " .. notificationData.key .. " with priority " .. notificationData.priority)
        local success = notificationService.sendNotification(
            tonumber(playerUserId),
            notificationData.info,
            notificationData.key,
            timeElapsed
        )
        
        if success then
            debugLog("Notification sent, stopping processing for this player")
            break -- Only send one notification per check
        end
    end
end

-- Process a batch of players from the database
function notificationService.processBatch(pageIndex, startIndex)
    debugLog("Processing batch - page: " .. pageIndex .. ", start index: " .. startIndex)
    
    local keysPage = {value = nil}
    local success = safeCall(function()
        return playerBase:ListKeysAsync("", ITEMS_PER_PAGE)
    end, keysPage)
    
    if not success or not keysPage.value then
        warn("[Notification Service] Failed to get player list")
        debugLog("Failed to get player list from DataStore")
        return false, 0, 0
    end
    
    -- Skip to the target page
    local currentPageNumber = 0
    while currentPageNumber < pageIndex and not keysPage.value.IsFinished do
        debugLog("Advancing to page " .. (currentPageNumber + 1))
        success = safeCall(function()
            keysPage.value:AdvanceToNextPageAsync()
            return true
        end, {value = nil})
        
        if not success then
            warn("[Notification Service] Failed to advance to page " .. pageIndex)
            debugLog("Failed to advance page cursor")
            return false, currentPageNumber, 0
        end
        
        currentPageNumber += 1
    end
    
    -- Process entries on the current page
    local entriesResult = {value = nil}
    success = safeCall(function()
        return keysPage.value:GetCurrentPage()
    end, entriesResult)
    
    if not success then
        debugLog("Failed to get entries on current page")
        return false, currentPageNumber, 0
    end
    
    local entries = entriesResult.value
    local processedCount = 0
    
    debugLog("Retrieved " .. #entries .. " entries on current page")
    
    for i, entry in ipairs(entries) do
        -- Skip entries before our start index
        if i < startIndex then
            debugLog("Skipping entry " .. i .. " (before start index " .. startIndex .. ")")
            continue
        end
        
        debugLog("Processing entry " .. i .. ", user ID: " .. entry.KeyName)
        notificationService.processPlayerNotifications(entry.KeyName)
        processedCount += 1
        
        -- Update progress
        currentIndex = i + 1
    end
    
    debugLog("Processed " .. processedCount .. " entries")
    
    -- Check if we're at the end or should move to next page
    local isFinished = keysPage.value.IsFinished
    local nextPage = isFinished and 0 or pageIndex + 1
    local nextIndex = isFinished and 0 or 0
    
    debugLog("Batch complete - is finished: " .. tostring(isFinished) .. ", next page: " .. nextPage .. ", next index: " .. nextIndex)
    return true, nextPage, nextIndex
end

-- Save the current task progress
function notificationService.saveTaskProgress(nextPage, nextIndex, nextServerId)
    debugLog("Saving task progress - page: " .. nextPage .. ", index: " .. nextIndex .. ", server: " .. (nextServerId or GAME_JOB_ID))
    
    local taskData = {
        page = nextPage,
        index = nextIndex,
        serverId = nextServerId or GAME_JOB_ID,
        updatedAt = os.time()
    }
    
    local result = {value = nil}
    local success = safeCall(function()
        taskInfo:SetAsync(TASK_KEY, taskData, 7200 * 24) -- 48 hour expiry
        return true
    end, result)
    
    debugLog("Task progress saved: " .. tostring(success))
end

-- Get a list of available servers (excluding our own)
function notificationService.getAvailableServers()
    debugLog("Getting list of available servers")
    
    local availableServersList = {}
    
    -- Get all available servers
    local servers = {value = nil}
    local success = safeCall(function()
        return availableServers:GetRangeAsync(1, 100)
    end, servers)
    
    if success and servers.value then
        for _, serverData in ipairs(servers.value) do
            -- Exclude our own server ID
            if serverData.key ~= GAME_JOB_ID then
                table.insert(availableServersList, serverData.key)
                debugLog("Found available server: " .. serverData.key)
            end
        end
    end
    
    debugLog("Found " .. #availableServersList .. " available servers")
    return availableServersList
end

-- Choose the next task server
function notificationService.chooseNextTaskServer()
    debugLog("Choosing next task server")
    
    local availableServersList = notificationService.getAvailableServers()
    
    -- Choose a random server if available
    if #availableServersList > 0 then
        local selectedServer = availableServersList[math.random(1, #availableServersList)]
        debugLog("Selected server: " .. selectedServer)
        return selectedServer
    end
    
    -- No other servers available
    debugLog("No available servers found, returning NULL")
    return "NULL"
end

-- Check if this server should be the task server
function notificationService.checkTaskAssignment()
    debugLog("Checking if this server should be the task server")
    
    if RunService:IsStudio() then
        return true
    end

    -- Don't run in private servers
    if game.PrivateServerId ~= "" then 
        debugLog("In private server, not eligible")
        return false 
    end
    
    -- Only eligible if we have enough players to justify the overhead
    if #Players:GetPlayers() < MINIMUM_PLAYERS_FOR_TASK then 
        debugLog("Not enough players (" .. #Players:GetPlayers() .. " < " .. MINIMUM_PLAYERS_FOR_TASK .. "), not eligible")
        return false 
    end
    
    -- Check if there's an existing task assignment
    local currentTask = {value = nil}
    local success = safeCall(function()
        return taskInfo:GetAsync(TASK_KEY)
    end, currentTask)
    
    if success and currentTask.value then
        debugLog("Found existing task assignment to server: " .. currentTask.value.serverId)
        
        -- We're already assigned
        if currentTask.value.serverId == GAME_JOB_ID then
            debugLog("We are already the task server")
            return true
        end
        
        -- Check if we've been assigned as the new server
        if not predecessorExitHandled and currentTask.value.serverId == "PENDING_" .. GAME_JOB_ID then
            debugLog("We are the pending new task server, taking over")
            -- Take over the task
            notificationService.saveTaskProgress(currentTask.value.page, currentTask.value.index, GAME_JOB_ID)
            predecessorExitHandled = true
            return true
        end
        
        -- Check if the assigned server is still alive
        local serverTimestamp = {value = nil}
        success = safeCall(function()
            return availableServers:GetAsync(currentTask.value.serverId)
        end, serverTimestamp)
        
        -- If the server is gone or task is stale, take over
        if (not success or not serverTimestamp.value) and 
           (os.time() - currentTask.value.updatedAt > SERVER_TIMEOUT_SECONDS) and
           currentTask.value.serverId ~= "NULL" then
            debugLog("Current task server is gone or stale, taking over")
            notificationService.saveTaskProgress(currentTask.value.page, currentTask.value.index, GAME_JOB_ID)
            return true
        end
    else
        debugLog("No existing task assignment found")
        -- No existing task, claim it if we have enough players
        if #Players:GetPlayers() >= MINIMUM_PLAYERS_FOR_TASK then
            debugLog("No existing task, claiming it")
            notificationService.saveTaskProgress(0, 0, GAME_JOB_ID)
            return true
        end
    end
    
    debugLog("Not eligible to be task server")
    return false
end

-- Check if we're the task server (or should be) and verify the task record
function notificationService.verifyTaskAssignment()
    debugLog("Verifying task assignment")
    
    local currentTask = {value = nil}
    local success = safeCall(function()
        return taskInfo:GetAsync(TASK_KEY)
    end, currentTask)
    
    if success and currentTask.value then
        debugLog("Found task record assigned to: " .. currentTask.value.serverId)
        
        -- Check for the following situations:
        -- 1. Current task server is NULL (no server assigned)
        -- 2. Current task server is no longer available
        -- 3. Current task server assignment is stale
        
        if currentTask.value.serverId == "NULL" or
           (os.time() - currentTask.value.updatedAt > SERVER_TIMEOUT_SECONDS) then
            debugLog("Task server is NULL or stale (updated " .. (os.time() - currentTask.value.updatedAt) .. " seconds ago)")
            
            -- We can take over if we have enough players
            if #Players:GetPlayers() >= MINIMUM_PLAYERS_FOR_TASK then
                debugLog("Taking over task server role")
                notificationService.saveTaskProgress(currentTask.value.page, currentTask.value.index, GAME_JOB_ID)
                return true
            end
        else
            -- Check if the assigned server is still alive
            local serverTimestamp = {value = nil}
            success = safeCall(function()
                return availableServers:GetAsync(currentTask.value.serverId)
            end, serverTimestamp)
            
            if not success or not serverTimestamp.value then
                debugLog("Assigned server is no longer available")
                
                -- Server is gone, we can take over
                if #Players:GetPlayers() >= MINIMUM_PLAYERS_FOR_TASK then
                    debugLog("Taking over from unavailable server")
                    notificationService.saveTaskProgress(currentTask.value.page, currentTask.value.index, GAME_JOB_ID)
                    return true
                end
            end
        end
    else
        debugLog("No task record found")
        
        -- No task record, initialize one if we have enough players
        if #Players:GetPlayers() >= MINIMUM_PLAYERS_FOR_TASK then
            debugLog("Creating new task record")
            notificationService.saveTaskProgress(0, 0, GAME_JOB_ID)
            return true
        end
    end
    
    debugLog("Not taking task server role")
    return false
end

-- Main task processing loop
function notificationService.processNotificationTasks()
    debugLog("Starting notification task processing")
    isProcessingTask = true
    
    -- Get the current task state
    local currentTask = {value = nil}
    local success = safeCall(function()
        return taskInfo:GetAsync(TASK_KEY)
    end, currentTask)
    
    if not success or not currentTask.value then
        debugLog("No current task state, starting from beginning")
        currentTask.value = { page = 0, index = 0 }
    else
        debugLog("Resuming from page " .. currentTask.value.page .. ", index " .. currentTask.value.index)
    end
    
    currentPage = currentTask.value.page
    currentIndex = currentTask.value.index
    
    while isTaskServer do
        debugLog("Processing task batch (page " .. currentPage .. ", index " .. currentIndex .. ")")
        
        -- Process a batch of players
        local success, nextPage, nextIndex = notificationService.processBatch(currentPage, currentIndex)
        
        -- Update our progress
        if success then
            debugLog("Batch processing succeeded, updating progress")
            currentPage = nextPage
            currentIndex = nextIndex
            notificationService.saveTaskProgress(currentPage, currentIndex)
        else
            debugLog("Batch processing failed")
        end
        
        -- Small delay to prevent overloading
        task.wait(0.5)
    end
    
    debugLog("Exiting task processing loop")
    isProcessingTask = false
end

-- Assign a successor server and transition the task
function notificationService.assignSuccessor()
    debugLog("Assigning successor server")
    
    -- Only proceed if we haven't already assigned a successor
    if assignedSuccessor then 
        debugLog("Already assigned successor, skipping")
        return 
    end
    
    -- Get current task info to ensure we're still the assigned server
    local currentTask = {value = nil}
    local success = safeCall(function()
        return taskInfo:GetAsync(TASK_KEY)
    end, currentTask)
    
    -- Only proceed if we're the currently assigned server or no task info exists
    if not success or not currentTask.value or currentTask.value.serverId == GAME_JOB_ID then
        debugLog("We are still the task server, choosing successor")
        
        -- Choose the next server
        local nextServerId = notificationService.chooseNextTaskServer()
        
        -- Mark that we've handled successor assignment
        assignedSuccessor = true
        
        -- If we found a server, assign it as "PENDING" first
        if nextServerId ~= "NULL" then
            debugLog("Assigning PENDING successor: " .. nextServerId)
            local pendingId = "PENDING_" .. nextServerId
            notificationService.saveTaskProgress(currentPage, currentIndex, pendingId)
            
            -- Wait a moment to allow the successor to register, then finalize
            task.delay(2, function()
                debugLog("Finalizing successor assignment to: " .. nextServerId)
                -- Final update with the successor's ID
                notificationService.saveTaskProgress(currentPage, currentIndex, nextServerId)
            end)
        else
            debugLog("No successor found, setting to NULL")
            -- No successor found, just set to NULL
            notificationService.saveTaskProgress(currentPage, currentIndex, "NULL")
        end
    else
        debugLog("We are no longer the task server, not assigning successor")
    end
end

-- Remove server from the pool
function notificationService.unregisterServer()
    debugLog("Unregistering server from pool")
    
    -- Remove from available servers
    local result = {value = nil}
    safeCall(function()
        availableServers:RemoveAsync(GAME_JOB_ID)
        return true
    end, result)
    
    -- If this was the task server, assign a successor
    if isTaskServer then
        debugLog("We are the task server, assigning successor")
        notificationService.assignSuccessor()
    else
        debugLog("Checking if we need to assign successor even though we don't think we're the task server")
        
        -- Even if we're not the task server, check if we should assign a successor
        -- This handles the case where we're closing before we realized we were the task server
        local currentTask = {value = nil}
        local success = safeCall(function()
            return taskInfo:GetAsync(TASK_KEY)
        end, currentTask)
        
        if success and currentTask.value and currentTask.value.serverId == GAME_JOB_ID then
            debugLog("We ARE the task server according to records, assigning successor")
            notificationService.assignSuccessor()
        end
    end
end

-- Setup the server heartbeat
function notificationService.startServerHeartbeat()
    debugLog("Starting server heartbeat")
    
    -- Register with memory store
    local result = {value = nil}
    safeCall(function()
        availableServers:SetAsync(GAME_JOB_ID, os.time(), SERVER_TIMEOUT_SECONDS * 2)
        return true
    end, result)
    
    -- Start heartbeat loop
    task.spawn(function()
        while true do
            -- Update heartbeat
            local result = {value = nil}
            safeCall(function()
                availableServers:SetAsync(GAME_JOB_ID, os.time(), SERVER_TIMEOUT_SECONDS * 2)
                return true
            end, result)
            
            debugLog("Server heartbeat updated")
            task.wait(SERVER_HEARTBEAT_SECONDS)
        end
    end)
end

-- Initialize service
function notificationService.start()
    debugLog("Starting notification service")
    
    -- Don't run in private servers
    if game.PrivateServerId ~= "" then 
        debugLog("In private server, not starting service")
        return 
    end
    
    -- Track current players in system
    Players.PlayerAdded:Connect(function(player)
        debugLog("Player added: " .. player.Name)
        local result = {value = nil}
        safeCall(function()
            playerBase:SetAsync(player.UserId, os.time())
            return true
        end, result)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        debugLog("Player removing: " .. player.Name)
        local result = {value = nil}
        safeCall(function()
            playerBase:SetAsync(player.UserId, os.time())
            return true
        end, result)
    end)
    
    -- Register existing players
    debugLog("Registering " .. #Players:GetPlayers() .. " existing players")
    for _, player in pairs(Players:GetPlayers()) do
        local result = {value = nil}
        safeCall(function()
            playerBase:SetAsync(player.UserId, os.time())
            return true
        end, result)
    end
    
    -- Setup server heartbeat
    notificationService.startServerHeartbeat()
    
    -- Register server shutdown callback
    game:BindToClose(function()
        debugLog("Server shutting down, handling cleanup")
        notificationService.unregisterServer()
    end)
    
    -- Run an initial check to see if we should be the task server
    -- This handles cases where the previous server closed without assigning a successor
    task.delay(5, function()
        debugLog("Running initial task server eligibility check")
        if notificationService.verifyTaskAssignment() then
            isTaskServer = true
            task.spawn(notificationService.processNotificationTasks)
            print("[Notification Service] This server is now the notification task server (recovery)")
            debugLog("Became task server during recovery check")
        end
    end)
    
    -- Start task eligibility check loop
    task.spawn(function()
        while true do
            debugLog("Running periodic task server eligibility check")
            
            -- Check if we should be the task server
            local shouldBeTaskServer = notificationService.checkTaskAssignment()
            
            -- Start or stop task processing
            if shouldBeTaskServer and not isTaskServer then
                isTaskServer = true
                task.spawn(notificationService.processNotificationTasks)
                print("[Notification Service] This server is now the notification task server")
                debugLog("Became task server during periodic check")
            elseif not shouldBeTaskServer then
                if isTaskServer then
                    debugLog("No longer eligible to be task server")
                end
                isTaskServer = false
            end
            
            task.wait(SERVER_SELECTION_INTERVAL)
        end
    end)
    
    print("[Notification Service] Started successfully")
    debugLog("Service startup complete")
end

debugLog("Module definition complete")
return notificationService