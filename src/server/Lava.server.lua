-- Cualquier parte llamada "Lava" en Workspace mata al jugador que la toca.
-- Funciona con la lava del mapa de ejemplo y con la que pongas tú en Studio.
local conectadas = {}

local function conectarLava(parte)
	if parte.Name ~= "Lava" or not parte:IsA("BasePart") or conectadas[parte] then
		return
	end
	conectadas[parte] = true

	parte.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end)
end

for _, parte in ipairs(workspace:GetDescendants()) do
	conectarLava(parte)
end
workspace.DescendantAdded:Connect(conectarLava)
