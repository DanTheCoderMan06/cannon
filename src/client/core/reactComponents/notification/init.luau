local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local Sift = require(sharedPackages.Sift)
local reactUtil = require(shared.utilities.reactUtil)
local components = ReplicatedStorage.client.reactComponents

-- props: { id: string, text: string, color: Color3, start: UDim2, onComplete: (id: string) -> () }
return function(props)
	local styles, api = ReactSpring.useSpring(function()
		return { transparency = 0, position = 0 }
	end)

	local visible, setVisible = React.useBinding(false)

	React.useLayoutEffect(function()
		setVisible(true)
		api.start({
			position = 1,
			config = { tension = 300, friction = 120 },
		})
		task.wait(0.5) -- Reduced wait time
		api.start({
			transparency = 1,
			config = { tension = 300, friction = 60 },
		})
		task.wait(1) -- Reduced wait time
		props.onComplete(props.id) -- Call onComplete with the notification's ID
	end, {})

	-- Removed the wrapping ScreenGui, render TextLabel directly
	return React.createElement("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
		Position = styles.position:map(function(val)
			return props.start:Lerp(props.start + UDim2.fromScale(0.0, 0.3), val)
		end),
		Size = UDim2.fromScale(0.46 * 1.3, 0.0443 * 1.3),
		Text = props.text,
		TextColor3 = props.color,
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
		TextTransparency = styles.transparency,
		Visible = visible,
	}, {
		uIStroke = React.createElement("UIStroke", {
			Thickness = reactUtil.scalePixelSize(1),
			Transparency = styles.transparency,
		}),

		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 5,
		}),
	}) -- Removed trailing comma here
	-- Removed extra closing bracket }) here
	-- End of TextLabel element
end
