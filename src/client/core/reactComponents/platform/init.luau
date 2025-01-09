local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local Trove = require(sharedPackages.Trove)
local Signal = require(sharedPackages.Signal)

local initializedPlatforms = {}

local function textBox(props)
	return React.createElement("TextLabel", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
		Position = UDim2.fromScale(0, 0.295),
		Size = UDim2.fromScale(0.3, 1),
		Text = props.value,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
		RichText = true,
	}, {
		uIStroke = React.createElement("UIStroke"),
	})
end

local function imageIcon(props)
	return React.createElement("ImageLabel", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Image = props.value or "",
		Size = UDim2.fromScale(0.08, 1),
		LayoutOrder = 1,
	})
end

return function(props)
	local title, setTitle = React.useState(props.title)
	local description, setDescription =
		React.useState({ type(props.description) == "table" and unpack(props.description) or props.description })

	local function renderElements()
		local render = {}
		for _, v in pairs(description) do
			if type(v) == "number" then
				table.insert(render, imageIcon({ value = v }))
			else
				table.insert(render, textBox({ value = v }))
			end
		end
	end

	if props.updateValues then
		React.useEffect(function()
			if not initializedPlatforms[props.name] then
				local initializedValues = props.init()
				setTitle(initializedValues.title)
				setDescription({
					type(initializedValues.description) == "table" and unpack(initializedValues.description)
						or initializedValues.description,
				})
				initializedPlatforms[props.name] = true
			end

			local bTrove = Trove.new()
			local editSignal = Signal.new()

			editSignal:Connect(function(newinfo)
				setTitle(newinfo.description)
				setDescription({
					type(newinfo.description) == "table" and unpack(newinfo.description) or newinfo.description,
				})
			end)

			props.updateValues(bTrove, editSignal)

			return function()
				bTrove:Destroy()
				editSignal:DisconnectAll()
				editSignal:Destroy()
			end
		end, { title, description })
	end

	return React.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.999,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, {
		title = React.createElement("TextLabel", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
			Position = UDim2.fromScale(0, 0.295),
			Size = UDim2.fromScale(1, 0.25),
			Text = title,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
		}, {
			uIStroke = React.createElement("UIStroke"),
		}),

		description = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 0.545),
			Size = UDim2.fromScale(1, 0.16),
		}, {
			uIListLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			textBox1 = React.createElement(textBox, { value = description[1] }),
			imageBox = React.createElement(imageIcon, { value = description[2] }),
		}),
	})
end
