-- Funciones pequeñas que usan varios scripts del servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ayudantes = {}

local COLOR_AVISO = Color3.fromRGB(255, 230, 90)

local mensaje = ReplicatedStorage:FindFirstChild("Mensaje")
if not mensaje then
	mensaje = Instance.new("RemoteEvent")
	mensaje.Name = "Mensaje"
	mensaje.Parent = ReplicatedStorage
end

-- Muestra un texto grande en la pantalla de todos
function Ayudantes.avisarTodos(texto, color)
	mensaje:FireAllClients(texto, color or COLOR_AVISO)
end

-- Muestra un texto grande solo a un jugador
function Ayudantes.avisar(player, texto, color)
	mensaje:FireClient(player, texto, color or COLOR_AVISO)
end

-- Dada una parte que tocó algo, devuelve el personaje y el jugador (solo si está vivo)
function Ayudantes.jugadorDe(parte)
	local character = parte:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return character, player
end

-- Nombre del equipo del jugador, o nil si no tiene
function Ayudantes.equipoDe(player)
	return player.Team and player.Team.Name or nil
end

return Ayudantes
