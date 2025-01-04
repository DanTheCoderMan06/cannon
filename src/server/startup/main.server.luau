local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverModules = ServerStorage.server
local sharedModules = ReplicatedStorage.shared

local startupUtil = require(sharedModules.utilities.startupUtil)

local SERVICE_NAME_FORMAT = "Service$"

startupUtil.startup({
	path = serverModules.services,
	nameFormat = SERVICE_NAME_FORMAT,
}, serverModules.components)
