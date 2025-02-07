local reactUtil = {}

function reactUtil.simpleBinding(binding, offset)
	local targetOffset = offset or 0
	return binding:map(function(val)
		local newval = val * (1 - targetOffset) + targetOffset
		if newval > 1 then
			newval = 1
		end
		return newval
	end)
end

function reactUtil.secondsToMMSS(seconds: string)
	local minutes = math.floor(seconds / 60)
	local secondsCalc = seconds % 60
	return string.format("%02d:%02d", minutes, secondsCalc)
end

function reactUtil.getValueIfAvailable(props, offset)
	return props.styles ~= nil and reactUtil.simpleBinding(props.styles.transparency, offset) or offset
end

return reactUtil
