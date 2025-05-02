-- src/shared/services/DebugService.luau

local RunService = game:GetService("RunService")

local DebugService = {}

--[[
	Logs arguments to the output only if running in Roblox Studio.
	Mimics the behavior of the global print function by converting all arguments
	to strings and concatenating them with spaces.

	@param ... any - Variable number of arguments to log.
]]
function DebugService.log(...)
	if RunService:IsStudio() then
		local args = { ... }
		local strings = {}
		for i = 1, #args do
			strings[i] = tostring(args[i])
		end
		-- Use the global print function for the actual output in Studio
		print(table.concat(strings, " "))
	end
	-- If not in Studio, do nothing
end

return DebugService
