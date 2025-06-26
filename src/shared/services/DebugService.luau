-- src/shared/services/DebugService.luau

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local debugUtil = require(ReplicatedStorage.shared.utilities.debugUtil)

local DebugService = {}

--[[
	Logs arguments to the output only if running in Roblox Studio.
	Mimics the behavior of the global print function by converting all arguments
	to strings and concatenating them with spaces.

	@param ... any - Variable number of arguments to log.
]]
function DebugService.log(...)
	if RunService:IsStudio() then
		debugUtil.log(...)
	end
	-- If not in Studio, do nothing
end

return DebugService
