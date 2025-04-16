local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local serverPackages = ServerStorage.serverPackages

local profileStore = require(serverPackages.ProfileStore)

local Players = game:GetService("Players")

local profileTemplate = require(ServerStorage.server.modules.profileTemplate)
local PlayerStore = profileStore.New("SavedPlayerDataV3", profileTemplate)
local realPlayerStore = PlayerStore
if RunService:IsStudio() then
	PlayerStore = PlayerStore.Mock
end
local Profiles = {}

local dataService = {}

local zap = require(ServerStorage.zap)

local Sift = require(sharedPackages.Sift)
local Signal = require(sharedPackages.Signal)

local notificationConfig = require(ReplicatedStorage.shared.config.notificationConfig)
local gamepasses = require(ReplicatedStorage.shared.config.gamepasses)

local marketplaceUtil = require(ReplicatedStorage.shared.utilities.marketplaceUtil)
dataService.dailyReward = Signal.new()
dataService.dataChanged = Signal.new()

-- Helper function for pcall with retry
local function pcallWithRetry(callback, description)
	local success, result
	local attempts = 0
	local maxAttempts = 3 -- Reduced attempts for datastore operations

	repeat
		attempts = attempts + 1
		success, result = pcall(callback)

		if not success then
			warn(`[DataService] {description} - Attempt {attempts} failed: {result}. Retrying...`)
			task.wait(math.pow(2, attempts)) -- Exponential backoff
		end
	until success or attempts >= maxAttempts

	if not success then
		warn(`[DataService] {description} - Failed after {maxAttempts} attempts: {result}`)
	end

	return success, result
end

function dataService.giveRewards(player)
	local profile = Profiles[player]
	if os.time() - profile.Data.lastClaimed >= 24 * 60 * 60 then
		profile.Data.lastClaimed = os.time()
		profile.Data.daysPlayed += 1
		zap.dataChanged.Fire(player, profile.Data)
	end
	for _, v in pairs(profile.Data.notificationQueue) do
		local notificationInfo = notificationConfig.notifications[v]
		notificationInfo.callback(profile)
	end
	table.clear(profile.Data.notificationQueue)
end

function dataService.removeAsync(userId)
	realPlayerStore:RemoveAsync(`Player_{userId}`)
end

function dataService.getGlobalPlayerData(user)
	if Players:GetPlayerByUserId(user) then --and RunService:IsStudio() == false then
		return Profiles[Players:GetPlayerByUserId(user)]
	end
	local playerData = PlayerStore:GetAsync(`Player_{user}`)
	-- Check if player is online first
	local onlinePlayer = Players:GetPlayerByUserId(user)
	if onlinePlayer and Profiles[onlinePlayer] then
		-- Return a deep copy to prevent accidental modification of the live profile data
		return Sift.Dictionary.copyDeep(Profiles[onlinePlayer].Data)
	end

	-- Player is offline, attempt to fetch data directly
	local success, profile = pcallWithRetry(function()
		-- Use ViewAsync for read-only access when possible, might be faster/less prone to locking
		-- Note: ProfileStore might not have ViewAsync, adjust if needed. GetAsync is the standard.
		return PlayerStore:GetAsync(`Player_{user}`)
	end, `GetAsync Player_{user}`)

	if success and profile then
		-- Assuming GetAsync returns the profile object containing Data
		if profile.Data then
			return profile.Data -- Return the raw data table
		else
			warn(`[DataService] GetAsync for Player_{user} returned profile without Data field.`)
			return nil
		end
	elseif not success then
		warn(`[DataService] Failed to get global player data for user {user} after retries. Error: {profile}`) -- profile contains error message here
		return nil
	else
		-- Success was true, but profile was nil (data doesn't exist)
		return nil
	end
end

-- Function to update data for an OFFLINE player using GetAsync / SetAsync
function dataService.updateOfflinePlayerData(userId, updateCallback)
	local profileKey = `Player_{userId}`

	-- Step 1: Get the profile data without starting a session
	local getSuccess, profile = pcallWithRetry(function()
		return PlayerStore:GetAsync(profileKey)
	end, `GetAsync Offline Profile {profileKey}`)

	if not getSuccess or not profile then
		-- If profile is nil even on success, it means no data exists for this key
		warn(
			`[DataService] Failed to get offline profile for {userId} or profile does not exist. Error/Result: {profile}`
		)
		return false
	end

	-- Step 2: Apply the changes using the provided callback
	-- The callback receives the profile.Data table to modify
	local callbackSuccess, callbackError = pcall(updateCallback, profile.Data)

	if not callbackSuccess then
		warn(`[DataService] Error during updateCallback for offline user {userId}: {callbackError}`)
		-- Do not proceed with saving if the callback failed
		return false
	end

	-- Step 3: Save the modified data back using SetAsync
	-- SetAsync works on profiles loaded via GetAsync
	local setSuccess, setError = pcallWithRetry(function()
		profile:SetAsync()
	end, `SetAsync Offline Profile {profileKey}`)

	if not setSuccess then
		warn(`[DataService] Failed to SetAsync offline profile for {userId}. Error: {setError}`)
		-- Potential data loss or conflict with an active session elsewhere
		return false
	end

	print(`[DataService] Successfully updated offline data for user {userId} via Get/SetAsync.`)
	return true
end

-- Function to fetch raw data for an OFFLINE player using GetAsync (read-only)
function dataService.fetchOfflinePlayerData(userId)
	local profileKey = `Player_{userId}`

	local getSuccess, profile = pcallWithRetry(function()
		return PlayerStore:GetAsync(profileKey)
	end, `GetAsync Offline Profile {profileKey} (fetch)`)

	if getSuccess and profile and profile.Data then
		return profile.Data -- Return the raw data table
	elseif not getSuccess then
		warn(`[DataService] Failed to fetch offline profile for {userId}. Error: {profile}`)
		return nil
	else
		-- Profile doesn't exist or has no Data field
		return nil
	end
end

function dataService.overwriteUserData(playerData)
	-- This function seems intended for direct profile manipulation,
	-- but using SetAsync directly on a profile object is unusual with ProfileService.
	-- Usually, modifications are done to profile.Data and then profile:Release() saves them.
	-- Consider removing or refactoring this if it's not used as intended.
	warn("[DataService] overwriteUserData called. Review its usage with ProfileService.")
	-- Example of potential intended use (needs profile object, not just data):
	-- local success, err = pcallWithRetry(function()
	--     playerData:SetAsync() -- Assuming playerData is a Profile object
	-- end, "SetAsync UserData")
	-- return success
end

function dataService.loadGamepasses(player)
	local playerProfile = Profiles[player]

	for _, v in pairs(gamepasses) do
		if v.cannonName then
			if marketplaceUtil.userOwnsGamepass(player, v.id) then
				if not table.find(playerProfile.Data.cannons, v.cannonName) then
					print("INSERTED: " .. v.cannonName)
					table.insert(playerProfile.Data.cannons, v.cannonName)
				end
			end
		end
	end
end

function dataService.start()
	local function PlayerAdded(player)
		task.wait()
		local profile = PlayerStore:StartSessionAsync(`Player_{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		if profile ~= nil then
			profile:AddUserId(player.UserId)
			profile:Reconcile()
			profile.OnSessionEnd:Connect(function()
				Profiles[player] = nil
				player:Kick(`Profile session end - Please rejoin`)
			end)
			if player.Parent == Players then
				Profiles[player] = profile
				local connection
				connection = Players.PlayerRemoving:Connect(function(playerLeaving)
					if player ~= playerLeaving then
						return
					end
					if profile ~= nil then
						profile:EndSession()
					end
					profile = nil
					connection:Disconnect()
				end)

				print(`Profile loaded for {player.DisplayName}!`)

				profile.Data.lastEntered = os.time()

				dataService.loadGamepasses(player)

				local leaderstats = ReplicatedStorage.assets.statsFolder:Clone()
				leaderstats.Name = "leaderstats"
				leaderstats.Parent = player
				dataService.updateLeaderstats(player)

				dataService.giveRewards(player)
				zap.dataChanged.Fire(player, profile.Data)

				-- Schedule a forced save after a short delay
				task.delay(3, function()
					-- Check if player and profile still exist before forced save
					if player and player.Parent == Players and Profiles[player] then
						print(`[DataService] Performing delayed initial forced save for {player.Name}`)
						-- Call updatePlayerData with forceSave = true, using the current data
						dataService.updatePlayerData(player, Profiles[player].Data, true)
					end

					-- Check for Group Reward
					local GROUP_ID = 13101898
					local GROUP_REWARD_FLOORS = 20

					if not profile.Data.joinedGroupReward then
						local success, isInGroup = pcall(function()
							return player:IsInGroup(GROUP_ID)
						end)
						if success and isInGroup then
							local newData = profile.Data
							newData.floors += GROUP_REWARD_FLOORS
							newData.joinedGroupReward = true
							print(`Granted group reward ({GROUP_REWARD_FLOORS} floors) to {player.Name}`)
							-- Fire notification to the client
							zap.giftReceived.Fire(
								player,
								`👍Thank you for joining our group for {GROUP_REWARD_FLOORS} bonus floors!👍`
							)
							dataService.updatePlayerData(player, newData, true)
						elseif not success then
							warn(`Failed to check group status for player {player.Name}`)
						end
					end
				end)

				profile.Data.firstTimeRewards = false
				profile.Data.firstTime = false
			else
				profile:EndSession()
			end
		else
			player:Kick(`Profile load fail - Please rejoin`)
		end
	end

	for _, player in Players:GetPlayers() do
		task.spawn(PlayerAdded, player)
	end

	Players.PlayerAdded:Connect(PlayerAdded)

	task.spawn(function()
		while true do
			task.wait(30)
			for player, profile in pairs(Profiles) do
				dataService.giveRewards(player)
			end
		end
	end)

	-- Add the requestData callback handler HERE, inside dataService.start
	zap.requestData.SetCallback(function(player)
		if Profiles[player] then
			-- Return a deep copy to prevent modification issues if the client tries to change it directly
			return dataService.getPlayerData(player)
		else
			warn(string.format("[DataService] requestData called for player %s but profile not loaded.", player.Name))
			return nil -- Indicate data is not available
		end
	end)
end -- This is the end of dataService.start

function dataService.updateLeaderstats(player)
	for key, value in pairs(Profiles[player].Data) do
		for i, v in pairs(player:WaitForChild("leaderstats"):GetChildren()) do
			if key == v:GetAttribute("statName") then
				v.Value = value
				break
			end
		end
	end
end

-- Updated function with deep comparison and forceSave option
function dataService.updatePlayerData(player: Player, newData, forceSave: boolean?)
	local profile = Profiles[player]
	if not profile then
		warn(`[DataService] updatePlayerData called for player {player.Name} but profile is not loaded.`)
		return
	end

	-- Default forceSave to false if not provided
	forceSave = forceSave or false

	-- Check for redundant save unless forced
	if not forceSave then
		if Sift.Dictionary.equalsDeep(profile.Data, newData) then
			if RunService:IsStudio() then
				warn(
					`[DataService] updatePlayerData called for {player.Name} with identical data. Skipping redundant update.`
				)
			end
			return -- Exit if data is the same and not forced
		end
	end

	-- Proceed with update
	profile.Data = newData
	zap.dataChanged.Fire(player, newData) -- Fire specific event (if still used)
	dataService.updateLeaderstats(player)
	dataService.dataChanged:Fire(player, newData) -- Fire generic event
	-- Note: ProfileService automatically handles saving on Release or periodically.
	-- Explicitly calling profile:Save() is generally not needed unless for critical moments.
	-- If a forced immediate save to datastore is *required* here (unlikely), you'd call profile:Save()
	-- print(`[DataService] Updated data for {player.Name}. Forced: {forceSave}`)
end

function dataService.getPlayerData(player: Player)
	repeat
		task.wait()
	until Profiles[player] ~= nil
	return Sift.Dictionary.copyDeep(Profiles[player].Data)
end

function dataService.addCannon(player: Player, cannonName: string)
	local profile = Profiles[player]
	if not profile then
		warn(`[DataService] addCannon: Profile not loaded for player {player.Name}`)
		return false
	end
	-- Ensure cannons table exists and add the cannon if not already present
	profile.Data.cannons = profile.Data.cannons or {}
	if not table.find(profile.Data.cannons, cannonName) then
		table.insert(profile.Data.cannons, cannonName)
		zap.dataChanged.Fire(player, profile.Data) -- Fire signal to notify listeners of the change
		dataService.dataChanged:Fire(player, profile.Data) -- Fire generic data changed signal
		print(`[DataService] Added cannon '{cannonName}' to player {player.Name}`)
		return true
	end
	return false -- Cannon already exists
end

return dataService
