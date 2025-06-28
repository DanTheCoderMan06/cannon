local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService") -- Added back
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService") -- Keep if OCUserNotification needs it implicitly

-- Debug flag
local DEBUG = true


-- Required modules
local OCUserNotification = require(ServerStorage.OpenCloud.V2.UserNotification)
local Sift = require(ReplicatedStorage.sharedPackages.Sift)
local dataService = require(ServerStorage.server.services.dataService) -- Assuming this fetches offline data needed for notifications

-- Config references
local notificationConfig = require(ReplicatedStorage.shared.config.notificationConfig)

-- Service definition
local notificationService = {}

-- Constants
local PLAYER_BASE_STORE_NAME = "playersBaseStore"
local WORK_LOOP_INTERVAL_SECONDS = 120 -- Wait 2 minutes between full processing cycles
local INTER_PAGE_WAIT = 15 -- Wait 15 seconds between processing pages of users
local INTRA_PAGE_WAIT = 2 -- Wait 2 seconds after processing a user assigned to this server
local LIST_KEYS_PAGE_SIZE = 100 -- Number of keys to fetch per ListKeysAsync page
local MAX_RETRY_ATTEMPTS = 3
local RETRY_DELAY_SECONDS = 10

-- DataStores & MemoryStores
local playerBase = DataStoreService:GetDataStore(PLAYER_BASE_STORE_NAME)


-- Retries a function if it fails.
local function pcallWithRetry(func)
	local success, result
	for i = 1, MAX_RETRY_ATTEMPTS do
		success, result = pcall(func)
		if success then
			return success, result
		end
		warn(string.format("[NotificationService] pcall attempt %d/%d failed: %s", i, MAX_RETRY_ATTEMPTS, tostring(result)))
		if i < MAX_RETRY_ATTEMPTS then
			task.wait(RETRY_DELAY_SECONDS)
		end
	end
	return success, result -- Return the final failure
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

-- Send a notification to a specific user via OpenCloud
function notificationService.sendNotification(userId, info, notificationKey, timeElapsed)
	local fetchedData = dataService.fetchOfflinePlayerData(userId)

	if not fetchedData then
		warn("[Notification Service] Failed to fetch data for user ID: " .. tostring(userId))
		return false
	end

	-- Validate notificationQueue structure
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

	-- Check 1: Prevent duplicates if multiple is false
	if not info.multiple and Sift.Array.includes(fetchedData.notificationQueue, notificationKey) then
		if DEBUG then
			print(
				"[NotificationService DEBUG] "
					.. "Skipping notification "
					.. notificationKey
					.. " for user "
					.. userId
					.. ": Already sent (multiple=false)."
			)
		end
		return false
	end

	-- Check 2: Use custom checker if available (overrides default waitTime)
	if typeof(info.customChecker) == "function" then
		local customCheckPassed = info.customChecker(userId, fetchedData, timeElapsed)
		if not customCheckPassed then
			if DEBUG then
				print(
					"[NotificationService DEBUG] "
						.. "Custom checker returned false for notification "
						.. notificationKey
						.. " for user "
						.. userId
				)
			end
			return false
		end
		-- If custom checker passes, we proceed directly to sending (skipping default waitTime)
	else
		-- Check 3: Default waitTime logic (only if no custom checker)
		if info.multiple then
			-- Calculate amountExisting only if needed for multiple=true waitTime check
			local amountExisting = 0
			for _, v in pairs(fetchedData.notificationQueue) do
				if v == notificationKey then
					amountExisting += 1
				end
			end
			if (amountExisting + 1) * info.waitTime > timeElapsed then
				if DEBUG then
					print(
						"[NotificationService DEBUG] "
							.. "Skipping notification "
							.. notificationKey
							.. " for user "
							.. userId
							.. ": Default waitTime not met (multiple=true)."
					)
				end
				return false
			end
		else
			-- The duplicate check for multiple=false was already done. Only need waitTime check.
			if info.waitTime > timeElapsed then
				if DEBUG then
					print(
						"[NotificationService DEBUG] "
							.. "Skipping notification "
							.. notificationKey
							.. " for user "
							.. userId
							.. ": Default waitTime not met (multiple=false)."
					)
				end
				return false
			end
		end
	end

	if DEBUG then
		print("[NotificationService DEBUG] " .. "Attempting to send notification " .. notificationKey .. " to user " .. userId)
	end
	local userNotification = {
		payload = {
			messageId = info.assetid,
			type = "MOMENT",
			parameters = info.parseParameters(userId, fetchedData),
		},
	}

	local notificationSentSuccessfully = false
	local apiCallSuccess, result = pcallWithRetry(function()
		return OCUserNotification.createUserNotification(userId, userNotification)
	end)

	if apiCallSuccess then
		if typeof(result) == "table" and result.statusCode then
			if result.statusCode == 200 then
				notificationSentSuccessfully = true
				if DEBUG then
					print(
						"[NotificationService DEBUG] "
							.. "[Notification Service] Successfully sent notification "
							.. notificationKey
							.. " via API for user "
							.. userId
					)
				end
			else
				local errorMsg = result.error and result.error.message or (result.body or "Unknown API error")
				warn(
					string.format(
						"[Notification Service] Open Cloud API Error for user ID %s - Status: %d, Error: %s",
						tostring(userId),
						result.statusCode,
						tostring(errorMsg)
					)
				)
			end
		else
			warn(
				"[Notification Service] Unexpected Open Cloud API response format for user ID: "
					.. tostring(userId)
					.. " - Response: "
					.. tostring(result)
			)
		end
	else
		warn(
			"[Notification Service] pcallWithRetry failed for createUserNotification for user ID: "
				.. tostring(userId)
				.. " - Error: "
				.. tostring(result)
		)
	end

	-- Update player data only if notification was sent successfully
	if notificationSentSuccessfully then
		local updateSuccess = dataService.updateOfflinePlayerData(userId, function(offlineData)
			if typeof(offlineData.notificationQueue) ~= "table" then
				warn("[Notification Service] Initializing notificationQueue during update for user " .. userId)
				offlineData.notificationQueue = {}
			end
			table.insert(offlineData.notificationQueue, notificationKey)
		end)

		if updateSuccess then
			if DEBUG then
				print("[NotificationService DEBUG] " .. "[Notification Service] Successfully updated notificationQueue for user " .. userId)
			end
			return true
		else
			warn("[Notification Service] API call succeeded but failed to update notificationQueue for user " .. userId)
			return false
		end
	else
		return false
	end
end

-- Process notifications for a single player
function notificationService.processPlayerNotifications(playerUserId)
	if DEBUG then
		print("[NotificationService DEBUG] " .. "Processing notifications for user ID: " .. tostring(playerUserId))
	end

	local lastPlayedTime = nil
	local success, result = pcallWithRetry(function()
		return playerBase:GetAsync(tostring(playerUserId))
	end)

	if not success then
		warn(
			"[Notification Service] Failed to get last played time for user ID "
				.. tostring(playerUserId)
				.. " after retries. Skipping."
		)
		return
	end

	lastPlayedTime = result
	if DEBUG then
		print(
			"[NotificationService DEBUG] "
				.. tostring(playerUserId)
				.. "'s lastJoined "
				.. tostring(lastPlayedTime)
				.. " TimeElapsed "
				.. os.time() - (lastPlayedTime or os.time())
		)
	end
	-- Continue knowing lastPlayedTime is either the value or nil (if GetAsync returned nil successfully)

	local currentTime = os.time()

	if not lastPlayedTime then
		if DEBUG then
			print("[NotificationService DEBUG] " .. "No last played time found for user " .. playerUserId .. ", setting to current time.")
		end
		lastPlayedTime = currentTime
		pcallWithRetry(function()
			playerBase:SetAsync(tostring(playerUserId), currentTime)
		end)
		-- Log is handled by safeCall on failure
	end

	local timeElapsed = currentTime - lastPlayedTime
	local sortedNotifications = getSortedNotificationsByPriority()
	local notificationSent = false
	for _, notificationData in ipairs(sortedNotifications) do
		local sent = notificationService.sendNotification(
			tonumber(playerUserId),
			notificationData.info,
			notificationData.key,
			timeElapsed
		)
		if sent then
			notificationSent = true
			break -- Only send one notification per check cycle for a user
		end
	end

	if success then -- Ensure we didn't fail the initial GetAsync
		pcallWithRetry(function()
			playerBase:SetAsync(tostring(playerUserId), currentTime)
		end)
		-- Log is handled by safeCall on failure
	end

	if DEBUG then
		print("[NotificationService DEBUG] " .. "Finished processing notifications for user ID: " .. tostring(playerUserId))
	end
end


-- Main processing loop run by each server
local function runProcessingLoop()
	while true do
		if DEBUG then
			print("[NotificationService DEBUG] Starting new processing cycle.")
		end

		local success, pages = pcallWithRetry(function()
			return playerBase:ListKeysAsync("", LIST_KEYS_PAGE_SIZE)
		end)

		if not success then
			warn("[NotificationService] Failed to start ListKeysAsync, retrying after main loop wait. Error: " .. tostring(pages))
			task.wait(WORK_LOOP_INTERVAL_SECONDS)
			continue
		end

		local processedCount = 0
		while true do
			local getPageSuccess, items = pcallWithRetry(function()
				return pages:GetCurrentPage()
			end)

			if getPageSuccess and items then
				for _, itemData in ipairs(items) do
					local userIdNum = tonumber(itemData.KeyName)
					if userIdNum and userIdNum > 0 then
						processedCount += 1
						if DEBUG then
							print(
								"[NotificationService DEBUG] "
									.. string.format("Processing user %s (Count: %d)", tostring(userIdNum), processedCount)
							)
						end
						task.spawn(notificationService.processPlayerNotifications, userIdNum)
						task.wait(INTRA_PAGE_WAIT)
					end
				end
			end

			if pages.IsFinished then
				break
			end

			local advanceSuccess, err = pcallWithRetry(function()
				pages:AdvanceToNextPageAsync()
			end)

			if not advanceSuccess then
				warn("[NotificationService] Failed to advance page, breaking cycle. Error: " .. tostring(err))
				break
			end
			task.wait(INTER_PAGE_WAIT)
		end

		if DEBUG then
			print(
				"[NotificationService DEBUG] "
					.. string.format(
						"[Notification Service] Finished processing cycle. Processed %d users.",
						processedCount
					)
			)
		end
		task.wait(WORK_LOOP_INTERVAL_SECONDS)
	end
end

-- Initialize service
function notificationService.start()
	if RunService:IsStudio() then
		if DEBUG then
			print("[NotificationService DEBUG] " .. "[Notification Service] Running in Studio mode.")
		end
		-- Optionally trigger a single update/process cycle for testing
		-- task.spawn(runProcessingLoop)
		-- return
	end


	-- Update player's last played time on join/leave
	local function updatePlayerTimestamp(player)
		local userId = player.UserId
		pcallWithRetry(function()
			playerBase:SetAsync(tostring(userId), os.time())
		end)
	end

	Players.PlayerAdded:Connect(updatePlayerTimestamp)
	Players.PlayerRemoving:Connect(updatePlayerTimestamp)

	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerTimestamp(player)
	end

	task.spawn(runProcessingLoop)

	if DEBUG then
		print("[NotificationService DEBUG] " .. "[Notification Service] Started.")
	end
end

return notificationService
