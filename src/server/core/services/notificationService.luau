local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService") -- Added back
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService") -- Keep if OCUserNotification needs it implicitly

-- Debug flag
local DEBUG = false

-- Debug logging function
local function debugLog(message)
	if DEBUG then
		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
			"[NotificationService DEBUG] " .. message
		)
	end
end

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
local TOTAL_USERS_MS_NAME = "notificationPlayerBase_3" -- MemoryStore HashMap name
local KEY_TOTAL_USERS_MS = "totalUsersData" -- Key within the MemoryStore HashMap
local USER_COUNT_UPDATE_INTERVAL_SECONDS = 3600 -- Check/update total user count every hour
local USER_COUNT_MS_EXPIRY_SECONDS = USER_COUNT_UPDATE_INTERVAL_SECONDS * 2 -- Expire MemoryStore data after 2 intervals
local WORK_LOOP_INTERVAL_SECONDS = 600 -- Wait 10 minutes between full processing cycles
local RECALCULATION_WAIT_SECONDS = 30 -- Wait after recalculating user count before starting work
local INTER_PAGE_WAIT = 1 -- Wait 1 second between processing pages of users
local INTRA_PAGE_WAIT = 0.1 -- Wait 0.1 seconds after processing a user assigned to this server
local LIST_KEYS_PAGE_SIZE = 100 -- Number of keys to fetch per ListKeysAsync page
local MAX_SAFE_CALL_ATTEMPTS = 3
local SAFE_CALL_RETRY_DELAY = 1

-- DataStores & MemoryStores
local playerBase = DataStoreService:GetDataStore(PLAYER_BASE_STORE_NAME)
local totalUsersMemoryStore = MemoryStoreService:GetHashMap(TOTAL_USERS_MS_NAME) -- Using MemoryStore HashMap

-- Hashing (xxhash32 implementation - unchanged)
local PRIME_1 = 0x9e3779B1
local PRIME_2 = 0x85ebca77
local PRIME_3 = 0xc2B2ae3d
local PRIME_4 = 0x27d4eb2f
local PRIME_5 = 0x165667b1

local function mult(a: number, b: number): number
	local ah, al = bit32.rshift(a, 16), a % 2 ^ 16
	local bh, bl = bit32.rshift(b, 16), b % 2 ^ 16
	return bit32.lshift((ah * bl) + (al * bh), 16) + (al * bl)
end

local function xxhash32(message: string, seed: number?): number
	local rSeed = if seed == nil then 0 else bit32.bor(seed, 0)
	local messageLen = #message

	local wordC = 1
	local i = 1
	local digest: number

	if messageLen >= 16 then
		local accum1 = rSeed + PRIME_1 + PRIME_2
		local accum2 = rSeed + PRIME_2
		local accum3 = rSeed
		local accum4 = rSeed - PRIME_1
		for _ = 0, messageLen - 16, 16 do
			local d1, c1, b1, a1, d2, c2, b2, a2, d3, c3, b3, a3, d4, c4, b4, a4 = string.byte(message, i, i + 15)
			accum1 = mult(
				bit32.lrotate(
					accum1
						+ mult(bit32.bor(bit32.lshift(a1, 24), bit32.lshift(b1, 16), bit32.lshift(c1, 8), d1), PRIME_2),
					13
				),
				PRIME_1
			)
			accum2 = mult(
				bit32.lrotate(
					accum2
						+ mult(bit32.bor(bit32.lshift(a2, 24), bit32.lshift(b2, 16), bit32.lshift(c2, 8), d2), PRIME_2),
					13
				),
				PRIME_1
			)
			accum3 = mult(
				bit32.lrotate(
					accum3
						+ mult(bit32.bor(bit32.lshift(a3, 24), bit32.lshift(b3, 16), bit32.lshift(c3, 8), d3), PRIME_2),
					13
				),
				PRIME_1
			)
			accum4 = mult(
				bit32.lrotate(
					accum4
						+ mult(bit32.bor(bit32.lshift(a4, 24), bit32.lshift(b4, 16), bit32.lshift(c4, 8), d4), PRIME_2),
					13
				),
				PRIME_1
			)
			wordC += 4
			i += 16
		end
		digest = bit32.lrotate(accum1, 1)
			+ bit32.lrotate(accum2, 7)
			+ bit32.lrotate(accum3, 12)
			+ bit32.lrotate(accum4, 18)
	else
		digest = bit32.bor(rSeed + PRIME_5, 0)
	end

	digest = bit32.bor(digest + messageLen, 0)

	for _ = wordC, messageLen // 4 do
		local d, c, b, a = string.byte(message, i, i + 3)
		digest += mult(bit32.bor(bit32.lshift(a, 24), bit32.lshift(b, 16), bit32.lshift(c, 8), d), PRIME_3)
		digest = mult(bit32.lrotate(digest, 17), PRIME_4)
		wordC += 1
		i += 4
	end

	for j = -(messageLen % 4), -1 do
		digest += mult(string.byte(message, j), PRIME_5)
		digest = mult(bit32.lrotate(digest, 11), PRIME_1)
	end

	digest = mult(bit32.bxor(digest, bit32.rshift(digest, 15)), PRIME_2)
	digest = mult(bit32.bxor(digest, bit32.rshift(digest, 13)), PRIME_3)
	digest = bit32.bxor(digest, bit32.rshift(digest, 16))

	return digest
end

-- Calculate a unique starting offset for this server based on its JobId
local SERVER_START_INDEX = xxhash32(game.JobId or "STUDIO")

-- Safe call wrapper for DataStore/API/MemoryStore operations
-- Safe call wrapper for DataStore/API/MemoryStore operations
-- Executes the callback, retrying on failure. Logs errors.
-- Returns true if the callback executed successfully at least once, false otherwise.
local function safeCall(callback)
	local success = false
	local attempts = 0
	local lastError = nil

	repeat
		attempts += 1
		success, lastError = pcall(callback) -- lastError will contain results on success, error on failure

		if not success then
			warn(string.format("[NotificationService] safeCall attempt %d failed: %s", attempts, tostring(lastError)))
			if attempts < MAX_SAFE_CALL_ATTEMPTS then
				task.wait(SAFE_CALL_RETRY_DELAY)
			else
				warn("[NotificationService] safeCall failed after max attempts.")
			end
		end
	until success or attempts >= MAX_SAFE_CALL_ATTEMPTS

	return success -- Only return success status; callback handles results/actions internally
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
		debugLog(
			"Skipping notification " .. notificationKey .. " for user " .. userId .. ": Already sent (multiple=false)."
		)
		return false
	end

	-- Check 2: Use custom checker if available (overrides default waitTime)
	if typeof(info.customChecker) == "function" then
		local customCheckPassed = info.customChecker(userId, fetchedData, timeElapsed)
		if not customCheckPassed then
			debugLog("Custom checker returned false for notification " .. notificationKey .. " for user " .. userId)
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
				debugLog(
					"Skipping notification "
						.. notificationKey
						.. " for user "
						.. userId
						.. ": Default waitTime not met (multiple=true)."
				)
				return false
			end
		else
			-- The duplicate check for multiple=false was already done. Only need waitTime check.
			if info.waitTime > timeElapsed then
				debugLog(
					"Skipping notification "
						.. notificationKey
						.. " for user "
						.. userId
						.. ": Default waitTime not met (multiple=false)."
				)
				return false
			end
		end
	end

	require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
		"Attempting to send notification " .. notificationKey .. " to user " .. userId
	)
	local userNotification = {
		payload = {
			messageId = info.assetid,
			type = "MOMENT",
			parameters = info.parseParameters(userId, fetchedData),
		},
	}

	local notificationSentSuccessfully = false
	local apiCallSuccess = safeCall(function()
		-- Type definition for clarity (based on feedback)
		-- type UserNotificationResult = { statusCode: number, response: UserNotification, error: OpenCloudError }
		local result: any = OCUserNotification.createUserNotification(userId, userNotification)

		if typeof(result) == "table" and result.statusCode then
			if result.statusCode == 200 then
				notificationSentSuccessfully = true -- Set flag for later data update
				require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
					"[Notification Service] Successfully sent notification "
						.. notificationKey
						.. " via API for user "
						.. userId
				)
			else
				-- Log specific error details if available
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
			-- Handle cases where the result isn't the expected table or pcall failed internally before API call
			warn(
				"[Notification Service] Unexpected Open Cloud API response format or internal error for user ID: "
					.. tostring(userId)
					.. " - Response/Error: "
					.. tostring(result)
			)
		end
		-- No return needed from callback, success is determined by side effect on notificationSentSuccessfully
	end)

	-- Check if the safeCall itself completed without exhausting retries, even if API call within failed
	if not apiCallSuccess then
		warn("[Notification Service] safeCall wrapper failed to execute API call for user ID: " .. tostring(userId))
		-- notificationSentSuccessfully remains false
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
			require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
				"[Notification Service] Successfully updated notificationQueue for user " .. userId
			)
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
	debugLog("Processing notifications for user ID: " .. tostring(playerUserId))

	local lastPlayedTime = nil
	local success = false -- Flag to track if GetAsync succeeded within safeCall
	safeCall(function()
		lastPlayedTime = playerBase:GetAsync(tostring(playerUserId)) -- Assign inside callback
		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
			playerUserId .. "'s lastJoined " .. lastPlayedTime .. " TimeElapsed " .. os.time() - lastPlayedTime
		)
		success = true -- Mark success if pcall didn't error
	end)

	-- If safeCall failed entirely (all retries exhausted), success remains false
	if not success then
		warn(
			"[Notification Service] Failed to get last played time for user ID (after retries): "
				.. tostring(playerUserId)
				.. ". Skipping."
		)
		return -- Critical failure
	end
	-- Continue knowing lastPlayedTime is either the value or nil (if GetAsync returned nil successfully)

	local currentTime = os.time()

	if not lastPlayedTime then
		debugLog("No last played time found for user " .. playerUserId .. ", setting to current time.")
		lastPlayedTime = currentTime
		-- Use safeCall just for retry/error logging, action is inside
		safeCall(function()
			playerBase:SetAsync(tostring(playerUserId), currentTime)
			-- No need to check success here unless SetAsync itself can return specific errors we need to handle
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
		-- Use safeCall just for retry/error logging, action is inside
		safeCall(function()
			playerBase:SetAsync(tostring(playerUserId), currentTime)
		end)
		-- Log is handled by safeCall on failure
	end

	debugLog("Finished processing notifications for user ID: " .. tostring(playerUserId))
end

-- Fetch total user count data from MemoryStore
local function getTotalUsersData()
	local data = nil
	local success = safeCall(function()
		data = totalUsersMemoryStore:GetAsync(KEY_TOTAL_USERS_MS) -- Assign inside
	end)

	if not success then
		warn("[Notification Service] Failed to get total users data from MemoryStore after retries.")
		return nil -- Indicate critical failure
	end

	-- Now process the 'data' retrieved (or nil if GetAsync returned nil successfully)
	if
		data
		and typeof(data) == "table"
		and typeof(data.userAmount) == "number"
		and typeof(data.lastUpdated) == "number"
	then
		return data
	else
		-- No data yet (or expired), or invalid data format
		debugLog("No valid user count data found in MemoryStore, will trigger update.")
		return { userAmount = 0, lastUpdated = 0 } -- Return default to trigger update
	end
end

-- Recalculate total user count and update MemoryStore
local function updateTotalUsersData()
	require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
		"[Notification Service] Starting recalculation of total users..."
	)
	local userCount = 0
	local pages = nil
	local success

	local listKeysSuccess = safeCall(function()
		pages = playerBase:ListKeysAsync("", LIST_KEYS_PAGE_SIZE) -- Assign inside
	end)

	if not listKeysSuccess or not pages then -- Check if safeCall failed OR ListKeysAsync returned nil
		warn("[Notification Service] Failed to initiate ListKeysAsync for user count after retries.")
		return false
	end

	while true do
		local items = nil
		local getPageSuccess = safeCall(function()
			items = pages:GetCurrentPage() -- Assign inside
		end)

		if not getPageSuccess then
			warn("[Notification Service] Failed to get current page during user count after retries.")
			return false -- Error during pagination
		end
		-- If successful but items is nil/empty, loop will handle it correctly below

		for i, v in pairs(items) do
			require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(tostring(v.KeyName))
		end

		userCount += #items

		if pages.IsFinished then
			break
		end

		local advanceSuccess = safeCall(function()
			pages:AdvanceToNextPageAsync() -- Action inside
		end)

		if not advanceSuccess then
			warn("[Notification Service] Failed to advance page during user count after retries.")
			return false -- Error advancing page
		end
		task.wait(INTER_PAGE_WAIT) -- Be nice to DataStore APIs
	end

	local newData = {
		userAmount = userCount,
		lastUpdated = os.time(),
	}

	-- Save to MemoryStore with expiry
	local setSuccess = safeCall(function()
		totalUsersMemoryStore:SetAsync(KEY_TOTAL_USERS_MS, newData, USER_COUNT_MS_EXPIRY_SECONDS) -- Action inside
	end)

	if setSuccess then
		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
			"[Notification Service] Successfully updated total users count in MemoryStore to: " .. userCount
		)
		return true
	else
		-- safeCall already warned
		return false
	end
end

-- Helper function to get all keys from the playerBase DataStore
local function getAllPlayerKeys()
	local allKeys = {}
	local pages = nil

	local listKeysSuccess = safeCall(function()
		pages = playerBase:ListKeysAsync("", LIST_KEYS_PAGE_SIZE) -- Start pagination
	end)

	if not listKeysSuccess or not pages then
		warn("[Notification Service] Failed to initiate ListKeysAsync for getting all keys.")
		return nil -- Indicate failure to get keys
	end

	while true do
		local items = nil
		local getPageSuccess = safeCall(function()
			items = pages:GetCurrentPage() -- Get current page items
		end)

		if not getPageSuccess then
			warn("[Notification Service] Failed to get current page while fetching all keys.")
			return nil -- Indicate failure
		end

		-- Add keys from the current page to the list
		if items then
			for _, itemData in ipairs(items) do
				table.insert(allKeys, itemData.KeyName)
			end
		end

		if pages.IsFinished then
			break -- Exit loop if all pages are processed
		end

		-- Advance to the next page
		local advanceSuccess = safeCall(function()
			pages:AdvanceToNextPageAsync()
		end)

		if not advanceSuccess then
			warn("[Notification Service] Failed to advance page while fetching all keys.")
			return nil -- Indicate failure
		end

		task.wait(INTER_PAGE_WAIT) -- Be nice to DataStore APIs between page fetches
	end

	require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
		string.format("[Notification Service] Successfully fetched %d total player keys.", #allKeys)
	)
	return allKeys
end

-- Main processing loop run by each server
local function runProcessingLoop()
	while true do
		-- 1. Check and potentially update total user count
		local usersData = getTotalUsersData()
		if not usersData then
			warn("[Notification Service] Failed to get user data from MemoryStore, waiting before retry...")
			task.wait(WORK_LOOP_INTERVAL_SECONDS)
			continue
		end

		-- Check if data is stale (older than the update interval)
		if os.time() - usersData.lastUpdated > USER_COUNT_UPDATE_INTERVAL_SECONDS then
			require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
				"[Notification Service] User count data is stale or missing, triggering update."
			)
			-- Call update function; it returns true/false based on its internal safeCalls
			if not updateTotalUsersData() then
				warn("[Notification Service] Failed to update user count, waiting before retry...")
				task.wait(WORK_LOOP_INTERVAL_SECONDS) -- Wait longer on failure
			else
				require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
					"[Notification Service] User count updated, waiting before starting work loop..."
				)
				task.wait(RECALCULATION_WAIT_SECONDS)
			end
			continue -- Restart loop to re-fetch potentially updated data
		end

		local totalUsers = usersData.userAmount
		if totalUsers <= 0 then
			debugLog("No users found in playerBase or count is zero according to MemoryStore. Waiting.")
			task.wait(WORK_LOOP_INTERVAL_SECONDS)
			continue
		end

		-- 2. Fetch all user keys for this cycle
		local allUserKeys = getAllPlayerKeys()

		if not allUserKeys then
			warn("[Notification Service] Failed to get all user keys for processing cycle. Waiting.")
			task.wait(WORK_LOOP_INTERVAL_SECONDS)
			continue
		end

		local totalUserKeys = #allUserKeys
		if totalUserKeys <= 0 then
			debugLog("No user keys found in playerBase. Waiting.")
			task.wait(WORK_LOOP_INTERVAL_SECONDS)
			continue
		end

		-- 3. Calculate the starting index for this server (1-based)
		-- Ensure totalUserKeys > 0 before modulo
		local startIndex = (SERVER_START_INDEX % totalUserKeys) + 1
		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
			string.format(
				"[Notification Service] Starting processing cycle for %d users. This server starts at index %d.",
				totalUserKeys,
				startIndex
			)
		)

		local processedCount = 0

		-- 4. Process from startIndex to end
		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
			string.format("[Notification Service] Processing from index %d to %d", startIndex, totalUserKeys)
		)
		for i = startIndex, totalUserKeys do
			local userIdStr = allUserKeys[i]
			local userIdNum = tonumber(userIdStr)
			if userIdNum and userIdNum > 0 then
				processedCount += 1
				require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
					string.format("[Notification Service] Processing user %s (Index %d)", userIdStr, i)
				) -- Uncommented print
				task.spawn(notificationService.processPlayerNotifications, userIdNum)
				task.wait(INTRA_PAGE_WAIT) -- Wait between processing individual users
			else
				debugLog("Skipping invalid key at index " .. i .. ": " .. userIdStr)
			end
		end

		-- 5. Process from beginning to startIndex - 1 (wrap around)
		if startIndex > 1 then
			require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
				string.format("[Notification Service] Processing wrapped from index 1 to %d", startIndex - 1)
			)
			for i = 1, startIndex - 1 do
				local userIdStr = allUserKeys[i]
				local userIdNum = tonumber(userIdStr)
				if userIdNum and userIdNum > 0 then
					processedCount += 1
					require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
						string.format("[Notification Service] Processing user %s (Index %d - wrapped)", userIdStr, i)
					) -- Uncommented print
					task.spawn(notificationService.processPlayerNotifications, userIdNum)
					task.wait(INTRA_PAGE_WAIT) -- Wait between processing individual users
				else
					debugLog("Skipping invalid key at index " .. i .. " (wrapped): " .. userIdStr)
				end
			end
		end

		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
			string.format("[Notification Service] Finished processing cycle. Processed %d users.", processedCount)
		)
		task.wait(WORK_LOOP_INTERVAL_SECONDS) -- Wait before starting the next full cycle
	end
end

-- Initialize service
function notificationService.start()
	if RunService:IsStudio() then
		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
			"[Notification Service] Running in Studio mode."
		)
		-- Optionally trigger a single update/process cycle for testing
		-- task.spawn(runProcessingLoop)
		-- return
	end

	if game.PrivateServerId ~= "" then
		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
			"[Notification Service] Disabled in private servers."
		)
		return
	end

	-- Update player's last played time on join/leave
	local function updatePlayerTimestamp(player)
		local userId = player.UserId
		-- Use safeCall just for retry/error logging, action is inside
		safeCall(function()
			playerBase:SetAsync(tostring(userId), os.time())
		end)
		-- Log is handled by safeCall on failure
	end

	Players.PlayerAdded:Connect(updatePlayerTimestamp)
	Players.PlayerRemoving:Connect(updatePlayerTimestamp)

	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerTimestamp(player)
	end

	task.spawn(runProcessingLoop)

	require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log("[Notification Service] Started.")
end

return notificationService
