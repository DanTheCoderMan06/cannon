local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local shared = ReplicatedStorage.shared
local sharedPackages = ReplicatedStorage.sharedPackages

local React = require(sharedPackages.React)
local ReactSpring = require(sharedPackages.ReactSpring)

local generics = ReplicatedStorage.client.reactComponents.generics

local button = require(generics.genericButton)

local dataController = require(ReplicatedStorage.client.controllers.dataController)

local isMobile = UserInputService.TouchEnabled

local function notificationSquare(props)
	local newAmount, setNewAmount = React.useBinding(0)
	React.useEffect(function()
		dataController.dataChanged:Connect(function(newData)
			if #newData.daysClaimed ~= newData.daysPlayed then
				setNewAmount(newData.daysPlayed - #newData.daysClaimed)
				return
			end
			setNewAmount(0)
		end)
		local newData = dataController.getData()
		print(newData.daysClaimed)
		print(newData.daysPlayed)
		if #newData.daysClaimed ~= newData.daysPlayed then
			setNewAmount(newData.daysPlayed - #newData.daysClaimed)
			return
		end
		setNewAmount(0)
	end,{})
	
	return React.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		Position = UDim2.fromScale(0.9, 0.1),
		Rotation = 15,
		Size = UDim2.fromScale(0.285943, 0.21114),
		Visible = newAmount:map(function(val)
			return val > 0
		end)
		}, {
		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),

		uICorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0.4, 0),
		}),

		uIStroke = React.createElement("UIStroke", {
			Color = Color3.fromRGB(202, 0, 0),
			Thickness = 1.5,
		}),

		amount = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			FontFace = Font.new(
			"rbxasset://fonts/families/FredokaOne.json",
			Enum.FontWeight.Bold,
			Enum.FontStyle.Normal
			),
			Position = UDim2.fromScale(0.45, 0.5),
			RichText = true,
			Size = UDim2.fromScale(1, 1),
			Text = newAmount,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
		}),
	})
end

return function(props)
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.04, 0.631),
		Size = UDim2.fromScale(0.035, 0.077),
	}, {
		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),

		uIListLayout = React.createElement("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		rewards = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(3.173, 0.5),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(5.822, 1.577),
		}, {
			content = React.createElement(button, {
				overlayImage = "rbxassetid://116797538593247",
				buttonText = "",
				image = "rbxassetid://109156736467684",
				onActivated = function()
					props.selectedUIEvent:Fire("rewards")
				end,
				buttonContent = {notificationSquare}
			}),
		}),

		uIPadding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0.8, 0),
		}),

		uIScale = React.createElement("UIScale", {
			Scale = isMobile and 1.3 or .9,
		}),
	})
end
