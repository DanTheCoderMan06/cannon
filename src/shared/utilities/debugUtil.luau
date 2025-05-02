-- src/shared/utilities/debugUtil.luau

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local debugUtil = {}

-- Configuration: Set to true to enable logging even outside Studio (e.g., for live server debugging)
-- Set to false to strictly log only in Studio.
local ENABLE_LOGGING_OUTSIDE_STUDIO = false -- Default: false

--[[
	Logs arguments to the output, mimicking the default print behavior.
	Logging behavior depends on the environment (Studio vs. Live Game)
	and the ENABLE_LOGGING_OUTSIDE_STUDIO flag.

	@param ... any - Variable number of arguments to log.
]]
function debugUtil.log(...)
	local args = { ... }
	pcall(function()
		local whitelistUser = false
		if RunService:IsClient() then
			if Players.LocalPlayer.UserId == 880645672 or Players.LocalPlayer.UserId == 6227507683 then
				whitelistUser = true
			end
		end
		if RunService:IsServer() then
			whitelistUser = true
		end
		if RunService:IsStudio() or ENABLE_LOGGING_OUTSIDE_STUDIO or whitelistUser then
			if #args == 1 then
				print(args[1])
				return
			end
			local strings = {}
			for i = 1, #args do
				strings[i] = args[i]
			end
			-- Use the global print function for the actual output
			print(table.concat(strings, " "))
		end
		-- If not in Studio and logging outside Studio is disabled, do nothing
	end)
end

return debugUtil
