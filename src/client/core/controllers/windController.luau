-- CLASS
local WindService = {}
WindService.__index = WindService

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local sharedPackages = ReplicatedStorage.sharedPackages
local React = require(sharedPackages.React)
local ReactRoblox = require(sharedPackages.ReactRoblox)
local cache = require(sharedPackages.partcache)

local sharedPackages = ReplicatedStorage.sharedPackages
local Signal = require(sharedPackages.Signal)
local toggleWindSignal = Signal.new()
-- VARIABLES
local RNG = Random.new()

local Trove = require(sharedPackages.Trove)

-- FUNCTIONS
function WindService.new(setting)
	local Object = {}
	setmetatable(Object, WindService)

	Object.Location = game.Workspace.Camera
	Object.Randomized = setting.Randomized or false
	Object.Velocity = setting.Velocity or Vector3.new(0.45, 0, 0)
	Object.Amount = math.huge
	Object.Current = 0
	Object.Frequency = setting.Frequency or 0.5
	Object.Lifetime = 0.05
	Object.Amplitude = setting.Amplitude or 0.35
	Object.Range = setting.Range or 120
	Object.Part = ReplicatedStorage.assets:WaitForChild("Wind")
	Object.Time = 0.01

	Object.Trove = Trove.new()

	Object.target = { CFrame = CFrame.new() }

	return Object
end

-- METHODS
function WindService:Start()
	self.enabled = true
	self.viewportRef = React.createRef()
	local cameraRef = React.createRef()
	local container = ReactRoblox.createRoot(Instance.new("Folder"))
	self.windParts =
		cache.new(ReplicatedStorage.assets:WaitForChild("Wind"), 50, Instance.new("Folder", ReplicatedStorage))
	container:render(ReactRoblox.createPortal(
		React.createElement("ScreenGui", {
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			ResetOnSpawn = false,
			DisplayOrder = 1000,
			IgnoreGuiInset = true,
		}, {
			viewport = React.createElement("ViewportFrame", {
				Ambient = Color3.fromRGB(255, 255, 255),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				LightColor = Color3.fromRGB(255, 255, 255),
				Size = UDim2.fromScale(1, 1),
				ref = self.viewportRef,
				ImageTransparency = 0,
			}, {
				camera = React.createElement("Camera", {
					CFrame = CFrame.new(),
					ref = cameraRef,
				}),
			}),
		}),
		Players.LocalPlayer.PlayerGui,
		"speedlines"
	))
	task.spawn(function()
		repeat
			task.wait()
		until self.viewportRef:getValue()
		self.viewportRef:getValue().CurrentCamera = cameraRef:getValue()
	end)
	local LastUsed = tick()
	self.Trove:BindToRenderStep("stripes", Enum.RenderPriority.Last.Value, function()
		if (tick() - LastUsed) >= self.Time then
			LastUsed = tick()
			if self.Current < self.Amount then
				self:CreateWind()
			end
		end
	end)
	self.Trove:Add(container, "unmount")
	self.Trove:Add(self.windParts, "Dispose")
end

function WindService:Stop()
	self.enabled = false
	self.Trove:Destroy()
end

function WindService:GetRandomPosition()
	local targetPos = CFrame.new(self.target.CFrame.Position, (self.target.CFrame * CFrame.new(0, 0, 1)).Position)
	local vsx = workspace.CurrentCamera.ViewportSize.X
	local vsy = workspace.CurrentCamera.ViewportSize.Y
	local x = -vsx / (vsy + vsx) * self.Range + vsx / (vsy + vsx) * self.Range * math.random() * 2
	local y = -vsy / (vsy + vsx) * self.Range + vsy / (vsy + vsx) * self.Range * math.random() * 2
	if math.sqrt(math.pow(x, 2) + math.pow(x, 2)) < self.Range / 3 then
		x *= 3
		y *= 3
	end
	return (targetPos * CFrame.new(x, y, math.random(self.Range * 0.8, self.Range))).Position
end

function WindService:CalculateSineWave(amp, x, freq, phase)
	return amp * math.sin((x / freq) + phase)
end

function WindService:FadeWind(part)
	for i = 0, 1, 0.01 do
		wait(0.01)
		part.Trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, i),
			NumberSequenceKeypoint.new(0.6, i),
			NumberSequenceKeypoint.new(1, 1),
		})
	end
	wait(0.1)
end

function projection(v1, v2) -- project v1 onto v2
	local dot1 = v1:Dot(v2) -- v1·v2
	local dot2 = v2:Dot(v2) -- v2·v2
	return (dot1 / dot2) * v2
end

function WindService:CreateWind()
	local Part = self.windParts:GetPart()
	Part.Parent = self.viewportRef:getValue()
	Part.Position = self:GetRandomPosition()
	self.Current += 1

	Part.CFrame = CFrame.new(Part.Position, (self.target.CFrame * CFrame.new(0, 0, self.Range)).Position)

	-- CHECK RANDOM STATE:
	local Render = RunService.RenderStepped:Connect(function()
		Part.CFrame = Part.CFrame * CFrame.new(0, 0, -3)
	end)

	-- START ENDING:
	task.delay(self.Lifetime, function()
		Render:Disconnect()
		if not self.enabled then
			return
		end
		self.windParts:ReturnPart(Part)
		self.Current -= 1
	end)
end

function WindService.toggle(bool)
	toggleWindSignal:Fire(bool)
end

function WindService.start()
	local newservice = WindService.new({})
	toggleWindSignal:Connect(function(bool)
		if bool then
			newservice:Start()
		else
			newservice:Stop()
		end
	end)
end

return WindService
