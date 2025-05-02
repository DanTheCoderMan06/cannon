--!optimize 2
-- Client controller to handle friend reward block interactions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local zap = require(ReplicatedStorage.zap) -- Corrected path as per user feedback
local effectsController = require(ReplicatedStorage.client.controllers.effectsController)
local Trove = require(ReplicatedStorage.sharedPackages.Trove)

local reactUtil = require(ReplicatedStorage.shared.utilities.reactUtil)

local friendRewardController = {}

local activePrompts = {} -- Cache: [blockId] = { prompt = PromptInstance, connection = Connection, trove = Trove }

-- Function to set up interaction for a specific block
function friendRewardController.setupBlockInteraction(blockId: string, rewardAmount: number)
	-- Find the block in the workspace using the BlockId attribute
	-- This requires the server to have set the attribute correctly
	local blockModel = nil
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("BlockId") == blockId then
			blockModel = child
			break
		end
	end

	if not blockModel then
		warn(`[FriendRewardController] Could not find block model with ID {blockId} in workspace.`)
		return
	end

	local interactionPart = blockModel:FindFirstChild("InteractionPart") :: BasePart
	if not interactionPart then
		warn(`[FriendRewardController] InteractionPart not found in block model {blockId}`)
		return
	end

	-- Cleanup previous prompt if somehow this function is called again for the same block
	if activePrompts[blockId] then
		activePrompts[blockId].trove:Destroy()
		activePrompts[blockId] = nil
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Friend Reward"
	prompt.ActionText = "Claim"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = true
	prompt.Parent = interactionPart

	local claimed = false
	local promptTrove = Trove.new()
	promptTrove:Add(prompt)

	local function claimBlock()
		if claimed then
			return -- Prevent double claim or other players claiming
		end
		claimed = true
		prompt.Enabled = false -- Disable prompt immediately

		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
			`[FriendRewardController] Claiming block {blockId} for amount {rewardAmount}`
		)

		-- Play effects
		local claimSound = SoundService.effects:FindFirstChild("claim")
		if claimSound then
			claimSound:Play()
		end
		effectsController.rewardPopup(interactionPart.Position, "$" .. reactUtil.formatNumber(rewardAmount))

		-- Tell the server we claimed it
		zap.claimFriendReward.Fire({ blockId = blockId })

		-- Clean up the prompt and connection locally
		promptTrove:Destroy()
		activePrompts[blockId] = nil
	end

	local connection = prompt.Triggered:Connect(function(playerWhoTriggered)
		claimBlock()
	end)

	promptTrove:Add(connection)

	-- Also clean up if the block model is destroyed by the server
	local destroyingConn = blockModel.Destroying:Connect(function()
		if activePrompts[blockId] then
			activePrompts[blockId].trove:Destroy()
			activePrompts[blockId] = nil
		end
	end)

	promptTrove:Add(destroyingConn)

	activePrompts[blockId] = { prompt = prompt, trove = promptTrove }
	require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
		`[FriendRewardController] Setup interaction for block {blockId}`
	)

	if Players.LocalPlayer:GetAttribute("autoFarming") then
		claimBlock()
	end

	promptTrove:Add(Players.LocalPlayer:GetAttributeChangedSignal("autoFarming"):Connect(function()
		claimBlock()
	end))
end

function friendRewardController.start()
	zap.spawnFriendRewardBlock.SetCallback(function(data)
		-- The server sends this event only to the specific player who earned the reward
		require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log(
			`[FriendRewardController] Received spawn event for block {data.blockId}`
		)
		-- Wait a brief moment for the block to potentially replicate/be parented
		task.wait(0.1)
		friendRewardController.setupBlockInteraction(data.blockId, data.rewardAmount)
	end)

	require(game:GetService("ReplicatedStorage").shared.utilities.debugUtil).log("[FriendRewardController] Started.")
end

return friendRewardController
