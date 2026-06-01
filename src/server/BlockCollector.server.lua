local Players = game:GetService("Players")
local cubitos = workspace:WaitForChild("Cubitos")

local recogido = false

for _, part in ipairs(cubitos:GetChildren()) do
	if part:IsA("Part") then

		part.Touched:Connect(function(hit)

			if recogido then
				return
			end

			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)

			if not player then
				return
			end

			recogido = true

			local hand = character:FindFirstChild("RightHand")

			if hand then
				local newPart = Instance.new("Part")
				newPart.Name = "CarriedBlock"
				newPart.Size = Vector3.new(2,2,2)
				newPart.Color = Color3.fromRGB(85,170,255)
				newPart.Anchored = false
				newPart.CanCollide = false
				newPart.Parent = character

				newPart.CFrame = hand.CFrame * CFrame.new(0,0,-1)

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = hand
				weld.Part1 = newPart
				weld.Parent = newPart
			end

		end)

	end
end