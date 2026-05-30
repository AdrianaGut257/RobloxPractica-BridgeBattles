local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local block = workspace:WaitForChild("Block1")

local collected = false

local function equipBlock(player)
	local character = player.Character
	if not character then return end

	local hand = character:FindFirstChild("RightHand")
	if not hand then return end

	local newBlock = ServerStorage.BlockTemplate:Clone()
	newBlock.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = newBlock
	weld.Parent = newBlock

	newBlock.CFrame = hand.CFrame * CFrame.new(0, 0, -1)
end

block.Touched:Connect(function(hit)
	if collected then return end

	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	collected = true

	equipBlock(player)

	block:Destroy()
end)