local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local cubitos = workspace:WaitForChild("Cubitos")

local function darBloque(character, color)
	-- R15 tiene "RightHand"; R6 tiene "Right Arm"
	local mano = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not mano then
		return false
	end

	local bloque = Instance.new("Part")
	bloque.Name = "CarriedBlock"
	bloque.Size = Vector3.new(2, 2, 2)
	bloque.Color = color
	bloque.Material = Enum.Material.SmoothPlastic
	bloque.Anchored = false
	bloque.CanCollide = false
	bloque.Massless = true -- para que no haga más lento ni desequilibre al jugador
	bloque.CFrame = mano.CFrame * CFrame.new(0, 0, -1)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = mano
	weld.Part1 = bloque
	weld.Parent = bloque

	bloque.Parent = character
	return true
end

local conectados = {}

local function conectarCubito(cubito)
	if not cubito:IsA("BasePart") or conectados[cubito] then
		return
	end
	conectados[cubito] = true

	local cframeOriginal = cubito.CFrame
	local disponible = true

	cubito.Touched:Connect(function(hit)
		if not disponible then
			return
		end

		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		if character:FindFirstChild("CarriedBlock") then
			return
		end

		if not darBloque(character, cubito.Color) then
			return
		end

		disponible = false
		cubito.Parent = nil

		task.delay(Config.TIEMPO_REAPARICION_CUBITO, function()
			cubito.CFrame = cframeOriginal
			cubito.Parent = cubitos
			disponible = true
		end)
	end)
end

for _, cubito in ipairs(cubitos:GetChildren()) do
	conectarCubito(cubito)
end
cubitos.ChildAdded:Connect(conectarCubito)
