local ReplicatedStorage = game:GetService("ReplicatedStorage")

local motorController = {}
local currentMotors = {}

function motorController.start()
	local zap = require(ReplicatedStorage.zap)
	zap.replicateNewMotors.On(function(newMotors)
		currentMotors = newMotors
	end)
end

function motorController.getMotors()
	return currentMotors
end

return motorController
