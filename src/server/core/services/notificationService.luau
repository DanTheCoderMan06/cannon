local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local zap = require(ServerStorage.zap)
local Sift = require(ReplicatedStorage.sharedPackages.Sift)
local Signal = require(ReplicatedStorage.sharedPackages.Signal)

local folderService = require(script.Parent.folderService)

local notificationService = {}

notificationService.currentTasks = {}

notificationService.currentTask = nil

local playerBase = DataStoreService:GetDataStore("playerBase")
local serverTasks = DataStoreService:GetDataStore("serverTasks")

local currentPageIndex = 0
local idsPerTask = 500

local function pcallFunction(callback)
	local s, r = pcall(callback)

	while not s do
		task.wait(1)
		warn(r .. " RETRYING.")
		s, r = pcall(callback)
	end
end

function notificationService.retrieveTask()
	local currentTasks = pcallFunction(function()
		serverTasks:ListKeysAsync("", 100)
	end)
	local foundTask
	local lastTask
	while not foundTask do
		local currentPage = currentTasks:GetCurrentPage()
		for _, key in pairs(currentPage) do
			local taskInfo = pcallFunction(function()
				serverTasks:GetAsync(key)
			end)
			lastTask = taskInfo
			if taskInfo.occupied then
				continue
			end
			foundTask = taskInfo
		end
		if currentPage.IsFinished then
			break
		end
		pcallFunction(function()
			currentPage:AdvanceToNextPageAsync()
		end)
	end
	return { found = foundTask, last = lastTask }
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

function notificationService.sendNotifications(userid)
	task.wait(1)
	print("Send em to " .. userid)
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
	for _, v in pairs(currentPage) do
		notificationService.sendNotifications(v)
	end
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
			end
		end)
	end)
	for _, v in pairs(Players:GetPlayers()) do
		pcallFunction(function()
			if not playerBase:GetAsync(v.UserId) then
				playerBase:SetAsync(v.UserId, os.time())
			end
		end)
	end

	canWork:Wait()

	local foundTask
	task.spawn(function()
		while true do
			foundTask = notificationService.retrieveTask()
			local target = foundTask.found
			if not target then
				foundTask = notificationService.addTask(foundTask.last.finish)
			end
			notificationService.completeWork(foundTask)
			task.wait(10)
			serverTasks:RemoveAsync(foundTask.id)
			task.wait(10)
		end
	end)

	game:BindToClose(function()
		if foundTask then
			foundTask.occupied = false
			pcallFunction(function()
				serverTasks:SetAsync(foundTask.id, foundTask)
			end)
		end
	end)
end

return notificationService
