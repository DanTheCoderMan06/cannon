local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local Trove = require(sharedPackages.Trove)

local reactUtil = require(shared.utilities.reactUtil)

return function(props)
	print("Go")

	local elapsedTime, setElapsedTime = React.useBinding(0)

	React.useEffect(function()
		local startedTime = tick()
		local uiTrove = Trove.new()
		uiTrove:Add(task.spawn(function()
			while true do
				task.wait()
				setElapsedTime(tick() - startedTime)
			end
		end))
		return function()
			uiTrove:Destroy()
		end
	end, {})

	return React.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, {
		var_stats = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.6, 0),
			Size = UDim2.fromScale(0.36, 1),
		}, {
			distance = React.createElement("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(-0.0011, 0.271),
				RichText = true,
				Size = UDim2.fromScale(1, 0.125),
				Text = tostring(reactUtil.formatNumber(props.distance)) .. " STUDS",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}, {
				stroke = React.createElement("UIStroke"),
			}),
			newFloors = React.createElement("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(-0.0011, 0.271 + 0.125 * 2),
				RichText = true,
				Size = UDim2.fromScale(1, 0.125),
				Text = "+ " .. reactUtil.formatNumber(props.floors) .. " FLOORS",
				TextColor3 = Color3.fromRGB(142, 172, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}, {
				stroke = React.createElement("UIStroke"),
			}),

			money = React.createElement("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(1.87e-07, 0),
				RichText = true,
				Size = UDim2.fromScale(1, 0.304),
				Text = "$" .. tostring(reactUtil.formatNumber(props.reward)),
				TextColor3 = Color3.fromRGB(249, 233, 3),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, {
				stroke1 = React.createElement("UIStroke"),
			}),

			record = React.createElement("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(1.87e-07, 0.725),
				RichText = true,
				Size = UDim2.fromScale(1, 0.275),
				Text = "NEW RECORD",
				TextColor3 = elapsedTime:map(function(val)
					return reactUtil.getSmoothColorFromElapsedTime(val, 1)
				end),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				Visible = props.isHighscore,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, {
				stroke2 = React.createElement("UIStroke"),
			}),

			duration = React.createElement("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
				Position = UDim2.fromScale(-0.0011, 0.396),
				RichText = true,
				Size = UDim2.fromScale(1, 0.125),
				Text = if type(props.duration) == "number"
					then props.duration .. " SECONDS"
					else props.duration:map(function(val)
						return val .. " SECONDS"
					end),
				TextColor3 = Color3.fromRGB(158, 255, 158),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, {
				stroke1 = React.createElement("UIStroke"),
			}),
		}),
	})
end
