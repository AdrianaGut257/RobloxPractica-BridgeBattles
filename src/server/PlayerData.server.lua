local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local blocks = Instance.new("IntValue")
	blocks.Name = "Blocks"
	blocks.Value = 0
	blocks.Parent = player

	print(player.Name .. " se unió")
end)