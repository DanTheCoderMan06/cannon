local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local zap = require(ServerStorage.zap)

local adminService = {}

local cmdr = require(game.ReplicatedStorage.Cmdr)

local players = game:GetService("Players")

function adminService.start()
	cmdr:RegisterDefaultCommands()
	cmdr:RegisterHooksIn(game.ReplicatedStorage:WaitForChild("cmdrHook"))
end

return adminService
