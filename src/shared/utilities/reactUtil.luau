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

function reactUtil.getSmoothColorFromElapsedTime(elapsedTime, speed)
	local speed = speed or 1

	local r = (math.sin(elapsedTime * speed) + 1) / 2
	local g = (math.sin(elapsedTime * speed + 2) + 1) / 2
	local b = (math.sin(elapsedTime * speed + 4) + 1) / 2

	return Color3.new(r, g, b)
end

-- Helper function for formatting numbers with suffixes
local function formatWithSuffix(num, divisor, suffix)
	local val = num / divisor
	local formatted = string.format("%.2f", val) -- Format to 2 decimal places

	-- Remove trailing ".00"
	if string.sub(formatted, -3) == ".00" then
		formatted = string.sub(formatted, 1, -4)
	-- Remove trailing "0" after decimal point (e.g., "1.20" -> "1.2")
	elseif string.sub(formatted, -1) == "0" and string.find(formatted, "%.", 1, true) then
		formatted = string.sub(formatted, 1, -2)
	end
	return formatted .. suffix
end

-- Format a number with appropriate suffix (k, M, B) and clean decimal places
function reactUtil.formatNumber(number)
	if number == nil then
		return "0"
	end

	local num = tonumber(number)
	if num == nil then
		-- Handle cases where input might not be a number directly
		return tostring(number) -- Or return "0" or an error indicator
	end

	-- Handle suffix formatting
	if num >= 1000000000000000 then
		return formatWithSuffix(num, 1000000000000000, "Q")
	elseif num >= 1000000000000 then
		return formatWithSuffix(num, 1000000000000, "T")
	elseif num >= 1000000000 then
		return formatWithSuffix(num, 1000000000, "B")
	elseif num >= 1000000 then
		return formatWithSuffix(num, 1000000, "M")
	elseif num >= 1000 then
		return formatWithSuffix(num, 1000, "k")
	-- Handle numbers less than 1000
	else
		-- Check if the number is an integer or effectively an integer after potential floating point noise
		if math.abs(num - math.floor(num + 0.00001)) < 0.0001 then -- Check if it's very close to an integer
			return string.format("%d", math.floor(num + 0.5)) -- Return as integer (round to nearest)
		else
			-- Format to max 2 decimal places, remove trailing zeros
			local formatted = string.format("%.2f", num)
			-- Remove trailing ".00"
			if string.sub(formatted, -3) == ".00" then
				formatted = string.sub(formatted, 1, -4)
			-- Remove trailing "0" after decimal point
			elseif string.sub(formatted, -1) == "0" and string.find(formatted, "%.", 1, true) then
				formatted = string.sub(formatted, 1, -2)
			end
			return formatted
		end
	end
end

-- Scales a target pixel size based on the current screen width relative to a 1920px base width.
-- @param targetPixelSize number - The desired pixel size at 1920px width.
-- @return number - The scaled pixel size for the current viewport width.
function reactUtil.scalePixelSize(targetPixelSize: number): number
	local camera = workspace.CurrentCamera
	if not camera then
		warn("reactUtil.scalePixelSize: Could not find workspace.CurrentCamera")
		return targetPixelSize -- Return original size if camera isn't available
	end

	local viewportSize = camera.ViewportSize
	local scaleFactor = viewportSize.X / 1920

	-- Ensure scaleFactor is not zero to avoid division by zero or unexpected results
	if scaleFactor <= 0 then
		warn("reactUtil.scalePixelSize: Invalid viewport width or scale factor <= 0. ViewportSize.X:", viewportSize.X)
		return targetPixelSize -- Return original size on invalid scale
	end

	return targetPixelSize * scaleFactor
end
return reactUtil
