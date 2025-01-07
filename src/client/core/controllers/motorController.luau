local ReplicatedStorage = game:GetService("ReplicatedStorage")

local motorController = {}
local currentMotors = {}
local Sift = require(ReplicatedStorage.sharedPackages.Sift)

function motorController.updateMotors(newMotors)
	currentMotors = Sift.Array.filter(currentMotors, function(value, index, array)
		if not value then
			return
		end

		return value:GetAttribute("serverLoaded")
	end)
	for i, v in pairs(newMotors) do
		v:SetAttribute("serverLoaded", true)
		table.insert(currentMotors, v)
	end
end

function motorController.clearLocalMotors()
	currentMotors = Sift.Array.filter(currentMotors, function(value, index, array)
		if not value then
			return
		end

		return not value:GetAttribute("serverLoaded")
	end)
end

function motorController.addMotor(addedMotor)
	table.insert(currentMotors, addedMotor)
end

function motorController.start()
	local zap = require(ReplicatedStorage.zap)
	zap.replicateNewMotors.On(function(newMotors)
		motorController.updateMotors(newMotors)
	end)
end

function motorController.getMotors()
	return currentMotors
end

return motorController
