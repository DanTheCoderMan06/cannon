local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)
local Sift = require(sharedPackages.Sift)
local components = ReplicatedStorage.client.reactComponents

return function(props)
	return React.createElement("ScrollingFrame", {
		Active = true,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(5 * (_G.isMobile and 1.3 or 1), 0),
		Position = props.Position,
		ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		ScrollBarThickness = 0,
		Size = UDim2.fromScale(0.918, 0.13 * (_G.isMobile and 1.3 or 1)),
	}, {
		uIGridLayout = React.createElement("UIGridLayout", {
			CellPadding = UDim2.fromScale(0, 0.1),
			CellSize = UDim2.fromScale(0.031, 1),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		React.createElement(React.Fragment, nil, props.elements),
	})
end
