local Players = game:GetService("Players")
local growingBlocks = workspace:WaitForChild("GrowingBlocks")

local siguienteColumna = 1
local maxColumnas = 12
local alturaPorColumna = {}

for i = 1, maxColumnas do
    local bloque = growingBlocks:FindFirstChild("BlockBlueA" .. i)
    if bloque then
        alturaPorColumna[i] = bloque.CFrame
    end
end

for _, bloque in ipairs(growingBlocks:GetChildren()) do
    if bloque:IsA("Part") then

        bloque.Touched:Connect(function(hit)

            local character = hit.Parent
            local player = Players:GetPlayerFromCharacter(character)
            if not player then return end

            local carriedBlock = character:FindFirstChild("CarriedBlock")
            if not carriedBlock then return end

            local referenciaCFrame = alturaPorColumna[siguienteColumna]

            local nuevoBloque = Instance.new("Part")
            nuevoBloque.Name = "BlockBlueA" .. siguienteColumna .. "_extra"
            nuevoBloque.Size = Vector3.new(2,2,2)
            nuevoBloque.Color = bloque.Color
            nuevoBloque.Anchored = true
            nuevoBloque.Parent = growingBlocks

            nuevoBloque.CFrame = referenciaCFrame * CFrame.new(2,0,0)

            alturaPorColumna[siguienteColumna] = nuevoBloque.CFrame

            carriedBlock:Destroy()

            siguienteColumna += 1
            if siguienteColumna > maxColumnas then
                siguienteColumna = 1
            end
        end)

    end
end