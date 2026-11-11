-- Script principal: equipos, rondas y quién gana.
-- Publica el estado como atributos en ReplicatedStorage para que la pantalla (HUD) lo lea:
-- Estado, TiempoRestante, Ronda, TotalCofres y Cofres_<equipo>.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ayudantes = require(script.Parent.Ayudantes)
local Puentes = require(script.Parent.Puentes)
local Cofres = require(script.Parent.Cofres)
local Cohetes = require(script.Parent.Cohetes)
local Datos = require(script.Parent.Datos)
local Tienda = require(script.Parent.Tienda)

-- Perfiles y tienda primero, para que cada jugador tenga sus monedas desde que entra
Datos.iniciar()
Tienda.iniciar()

-- ===== Equipos =====
for _, datos in ipairs(Config.EQUIPOS) do
	if not Teams:FindFirstChild(datos.nombre) then
		local equipo = Instance.new("Team")
		equipo.Name = datos.nombre
		equipo.TeamColor = datos.color
		equipo.AutoAssignable = true -- Roblox reparte a los que entran
		equipo.Parent = Teams
	end
end

local function equipoConMenosJugadores()
	local mejor
	for _, equipo in ipairs(Teams:GetTeams()) do
		if not mejor or #equipo:GetPlayers() < #mejor:GetPlayers() then
			mejor = equipo
		end
	end
	return mejor
end

local function alEntrar(player)
	-- En Studio el jugador puede entrar antes de que existan los equipos
	if not player.Team then
		player.Team = equipoConMenosJugadores()
		player.Neutral = false
		if player.Character then
			player:LoadCharacter() -- que aparezca en la base de su equipo
		end
	end
end

-- ===== Mapa =====
-- Primero esperamos el mapa, para que los jugadores aparezcan en su base y no en el aire
local arena = workspace:WaitForChild("Arena")

-- Solo se aparece en las bases de la Arena. Cualquier otro SpawnLocation
-- (como el que trae abajo la plantilla de Roblox) se apaga.
local function apagarSpawnExtra(objeto)
	if objeto:IsA("SpawnLocation") and not objeto:IsDescendantOf(arena) then
		objeto.Enabled = false
	end
end
for _, objeto in ipairs(workspace:GetDescendants()) do
	apagarSpawnExtra(objeto)
end
workspace.DescendantAdded:Connect(apagarSpawnExtra)

Puentes.iniciar(arena)
Cofres.iniciar(arena)
Cohetes.iniciar()

Players.PlayerAdded:Connect(alEntrar)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(alEntrar, player)
end

-- ===== Caerse al vacío =====
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local raiz = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if raiz and humanoid and raiz.Position.Y < Config.ALTURA_VACIO then
				humanoid.Health = 0
			end
		end
	end
end)

-- ===== Marcador =====
local function publicar(nombre, valor)
	ReplicatedStorage:SetAttribute(nombre, valor)
end

local function actualizarMarcador()
	publicar("TotalCofres", Cofres.total())
	for _, datos in ipairs(Config.EQUIPOS) do
		publicar("Cofres_" .. datos.nombre, Cofres.contar(datos.nombre))
	end
end
Cofres.alCapturar = actualizarMarcador

-- Si un equipo tiene TODOS los cofres, gana al instante
local function equipoConTodos()
	if Cofres.total() == 0 then
		return nil
	end
	for _, datos in ipairs(Config.EQUIPOS) do
		if Cofres.contar(datos.nombre) == Cofres.total() then
			return datos.nombre
		end
	end
	return nil
end

-- Cuando se acaba el tiempo, gana el que tenga más cofres (nil si hay empate)
local function equipoConMas()
	local ganador, maximo, empate = nil, -1, false
	for _, datos in ipairs(Config.EQUIPOS) do
		local cantidad = Cofres.contar(datos.nombre)
		if cantidad > maximo then
			ganador, maximo, empate = datos.nombre, cantidad, false
		elseif cantidad == maximo then
			empate = true
		end
	end
	if empate or maximo == 0 then
		return nil
	end
	return ganador
end

-- ===== Rondas =====
local ronda = 0

while true do
	ronda += 1
	Puentes.reiniciar()
	Cofres.reiniciar()
	actualizarMarcador()

	publicar("Ronda", ronda)
	publicar("Estado", "Jugando")
	Puentes.activo = true
	Cofres.activo = true
	Ayudantes.avisarTodos("Ronda " .. ronda .. ": ¡construyan puentes y capturen los cofres!")

	local ganador
	for segundos = Config.TIEMPO_RONDA, 1, -1 do
		publicar("TiempoRestante", segundos)
		task.wait(1)
		ganador = equipoConTodos()
		if ganador then
			break
		end
	end
	publicar("TiempoRestante", 0)
	ganador = ganador or equipoConMas()

	Puentes.activo = false
	Cofres.activo = false
	publicar("Estado", "Fin")

	-- Premios: los ganadores reciben Victoria, los demás Participacion
	for _, player in ipairs(Players:GetPlayers()) do
		local equipo = Ayudantes.equipoDe(player)
		if equipo then
			Datos.sumar(player, "Partidas", 1)
			Datos.recompensar(player, equipo == ganador and "Victoria" or "Participacion")
		end
	end

	if ganador then
		Ayudantes.avisarTodos("¡Gana el equipo " .. ganador .. "!", Config.buscarEquipo(ganador).color.Color)
	else
		Ayudantes.avisarTodos("¡Empate!")
	end

	task.wait(Config.TIEMPO_ENTRE_RONDAS)

	-- Todos vuelven a su base
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
end
