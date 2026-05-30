local Players = game:GetService("Players")

local block = workspace:WaitForChild("Block1")

local collected = false

block.Touched:Connect(function(hit)
	if collected then
		return
	end

	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)

	if not player then
		return
	end

	collected = true

	local hand = character:FindFirstChild("RightHand")

if hand then
	local part = Instance.new("Part")
	part.Name = "CarriedBlock"
	part.Size = Vector3.new(2,2,2)
	part.Color = Color3.fromRGB(0, 0, 255)
	part.Anchored = false
	part.CanCollide = false
	part.Parent = character

	part.CFrame = hand.CFrame * CFrame.new(0, 0, -1)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = part
	weld.Parent = part
end
end)