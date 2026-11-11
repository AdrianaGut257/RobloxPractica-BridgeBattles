-- Recibe las compras de la tienda y aplica la mejora de velocidad.
-- (Las demás mejoras se leen donde se usan: Mochila en Puentes, Cohete y Recarga en Cohetes.)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Datos = require(script.Parent.Datos)

local Tienda = {}

local function aplicarVelocidad(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.valorMejora("Velocidad", Datos.nivelMejora(player, "Velocidad"))
	end
end

local function prepararJugador(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 5)
		aplicarVelocidad(player)
	end)
	-- Cuando compra la mejora o terminan de cargar sus datos
	player:GetAttributeChangedSignal("Mejora_Velocidad"):Connect(function()
		aplicarVelocidad(player)
	end)
	aplicarVelocidad(player)
end

function Tienda.iniciar()
	local comprar = Instance.new("RemoteFunction")
	comprar.Name = "Comprar"
	comprar.Parent = ReplicatedStorage

	comprar.OnServerInvoke = function(player, id)
		-- El servidor revisa precio y monedas; el cliente solo pide
		return Datos.comprarMejora(player, id)
	end

	Players.PlayerAdded:Connect(prepararJugador)
	for _, player in ipairs(Players:GetPlayers()) do
		prepararJugador(player)
	end
end

return Tienda
