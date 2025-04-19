local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- Needed for table manipulation potentially

local sharedPackages = ReplicatedStorage.sharedPackages
local React = require(sharedPackages.React)
local Sift = require(sharedPackages.Sift) -- For table manipulation (removing items)
local Trove = require(sharedPackages.Trove) -- For managing connections

local Notification = require(script.Parent) -- The individual notification component

-- props: { addNotificationEvent: Signal }
local function NotificationContainer(props)
	-- Store notifications as a dictionary/map: { [id: string] = notificationData }
	local notifications, setNotifications = React.useState({})

	local trove = React.useMemo(function()
		return Trove.new()
	end, {})

	-- Function to remove a notification by its ID
	local function handleComplete(id)
		setNotifications(function(currentNotifications)
			-- Create a new table without the completed notification
			local newNotifications = Sift.Dictionary.copyDeep(currentNotifications)
			newNotifications[id] = nil
			return newNotifications
		end)
	end

	-- Effect to listen for new notifications
	React.useEffect(function()
		local connection = trove:Connect(props.addNotificationEvent, function(notificationData)
			setNotifications(function(currentNotifications)
				-- Create a new table including the new notification
				local newNotifications = Sift.Dictionary.copyDeep(currentNotifications)
				newNotifications[notificationData.id] = notificationData
				return newNotifications
			end)
		end)

		-- Cleanup function: disconnect the signal when the component unmounts
		return function()
			trove:Destroy()
		end
	end, {}) -- Dependency array ensures effect runs if the event signal changes

	-- Create elements table for rendering
	local notificationElements = {}
	for id, data in pairs(notifications) do
		notificationElements[id] = React.createElement(Notification, {
			key = id, -- React key for list items
			id = id,
			text = data.text,
			color = data.color,
			start = data.start,
			onComplete = handleComplete, -- Pass the removal function
		})
	end

	return React.createElement("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10, -- Ensure it's above most UI
		IgnoreGuiInset = true,
		ResetOnSpawn = false, -- Important for persistent UI
	}, notificationElements) -- Render the table of notification elements
end

return NotificationContainer
