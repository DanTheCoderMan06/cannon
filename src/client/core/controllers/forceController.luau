local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local utilities = ReplicatedStorage.shared.utilities
local forceUtil = require(utilities.forceUtil)

--[[ FUNCTIONS ]]
--
local function ApplyForce(data)
	forceUtil:OnApplyForce(data.part, data.velocity, data.rotvelocity, data.position)
end

--[[ INITIAL ]]
--
local forceController = {}
local zap = require(ReplicatedStorage.zap)

function forceController.start()
	print("Start")
	zap.applyForceLocally.On(ApplyForce)
end

return forceController
