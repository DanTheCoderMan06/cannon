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
			-- Get caller script information
			local source = debug.info(3, "s") -- Level 3 should be the caller
			local scriptName = "UnknownScript"
			if source then
				scriptName = string.match(source, "([^/\\]+)$") or scriptName -- Extract filename
			end
			local prefix = "[" .. scriptName .. "]: "

			if #args == 1 then
				print(prefix, args[1]) -- Prepend script name
				return
			end
			local strings = {}
			strings[1] = prefix -- Start with the prefix
			for i = 1, #args do
				strings[i + 1] = args[i] -- Shift original args
			end
			-- Use the global print function for the actual output
			print(table.concat(strings, " "))
		end
	end)
end

return debugUtil
