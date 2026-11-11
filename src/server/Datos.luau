-- Perfil de cada jugador: monedas, nivel, estadísticas y mejoras compradas. Se guarda con DataStore.
-- Los números se copian como atributos del jugador (player:GetAttribute("Monedas"), etc.)
-- para que su pantalla los pueda leer.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ayudantes = require(script.Parent.Ayudantes)

local Datos = {}

local CAMPOS = { "Monedas", "XP", "Nivel", "Victorias", "Partidas", "Bloques", "Eliminaciones", "Cofres" }
local EN_TABLA = { "Nivel", "Victorias", "Monedas" } -- los que se ven en la tabla de arriba a la derecha
local GUARDAR_CADA = 120 -- segundos

local perfiles = {} -- player -> perfil
local cargados = {} -- solo guardamos a quien se le cargó bien, para no borrar su progreso

local store
do
	local exito, resultado = pcall(function()
		return DataStoreService:GetDataStore(Config.NOMBRE_DATASTORE)
	end)
	if exito then
		store = resultado
	else
		warn("[Datos] No se puede guardar el progreso: " .. tostring(resultado))
	end
end

local recompensa = Instance.new("RemoteEvent")
recompensa.Name = "Recompensa"
recompensa.Parent = ReplicatedStorage

local function perfilNuevo()
	local perfil = { Mejoras = {} }
	for _, campo in ipairs(CAMPOS) do
		perfil[campo] = 0
	end
	perfil.Nivel = 1
	return perfil
end

local function clave(player)
	return "jugador_" .. player.UserId
end

-- Copia el perfil a los atributos y a la tabla de jugadores
local function publicar(player)
	local perfil = perfiles[player]
	if not perfil then
		return
	end
	for _, campo in ipairs(CAMPOS) do
		player:SetAttribute(campo, perfil[campo])
	end
	for _, mejora in ipairs(Config.MEJORAS) do
		player:SetAttribute("Mejora_" .. mejora.id, perfil.Mejoras[mejora.id] or 0)
	end

	local tabla = player:FindFirstChild("leaderstats")
	if tabla then
		for _, campo in ipairs(EN_TABLA) do
			local valor = tabla:FindFirstChild(campo)
			if valor then
				valor.Value = perfil[campo]
			end
		end
	end
end

local function revisarNivel(player, perfil)
	while perfil.XP >= Config.xpParaNivel(perfil.Nivel) do
		perfil.XP -= Config.xpParaNivel(perfil.Nivel)
		perfil.Nivel += 1
		perfil.Monedas += Config.MONEDAS_POR_NIVEL
		Ayudantes.avisar(
			player,
			"¡Subiste a nivel " .. perfil.Nivel .. "! +" .. Config.MONEDAS_POR_NIVEL .. " monedas",
			Color3.fromRGB(120, 255, 140)
		)
	end
end

-- ===== Lo que usan los demás scripts =====

-- Da monedas, experiencia y suma la estadística de Config.RECOMPENSAS[tipo]
function Datos.recompensar(player, tipo, cantidad)
	cantidad = cantidad or 1
	local datos = Config.RECOMPENSAS[tipo]
	local perfil = perfiles[player]
	if not datos or not perfil then
		return
	end

	if datos.estadistica then
		perfil[datos.estadistica] += cantidad
	end
	local monedas = datos.monedas * cantidad
	perfil.Monedas += monedas
	perfil.XP += datos.xp * cantidad
	revisarNivel(player, perfil)
	publicar(player)

	recompensa:FireClient(player, monedas, datos.texto)
end

function Datos.sumar(player, campo, cantidad)
	local perfil = perfiles[player]
	if perfil and perfil[campo] then
		perfil[campo] += cantidad
		publicar(player)
	end
end

function Datos.nivelMejora(player, id)
	local perfil = perfiles[player]
	return perfil and perfil.Mejoras[id] or 0
end

-- Devuelve (true, mensaje) si se compró, o (false, motivo) si no
function Datos.comprarMejora(player, id)
	local perfil = perfiles[player]
	local mejora = type(id) == "string" and Config.buscarMejora(id)
	if not perfil or not mejora then
		return false, "No se pudo comprar"
	end

	local nivel = perfil.Mejoras[id] or 0
	local precio = mejora.precios[nivel + 1]
	if not precio then
		return false, "Ya está al máximo"
	end
	if perfil.Monedas < precio then
		return false, "Te faltan " .. (precio - perfil.Monedas) .. " monedas"
	end

	perfil.Monedas -= precio
	perfil.Mejoras[id] = nivel + 1
	publicar(player)
	return true, mejora.nombre .. " nivel " .. (nivel + 1)
end

-- ===== Cargar y guardar =====

local function cargar(player)
	if not store then
		return
	end

	local exito, guardado
	for _ = 1, 3 do
		exito, guardado = pcall(function()
			return store:GetAsync(clave(player))
		end)
		if exito then
			break
		end
		task.wait(2)
	end

	if not player.Parent then
		return -- se fue mientras cargábamos
	end
	if not exito then
		warn("[Datos] No se pudieron cargar los datos de " .. player.Name .. ": " .. tostring(guardado))
		return
	end

	local perfil = perfiles[player]
	if type(guardado) == "table" then
		-- Sumamos lo guardado a lo que ganó mientras cargaba
		for _, campo in ipairs(CAMPOS) do
			if type(guardado[campo]) == "number" then
				if campo == "Nivel" then
					perfil.Nivel = guardado.Nivel + (perfil.Nivel - 1)
				else
					perfil[campo] += guardado[campo]
				end
			end
		end
		if type(guardado.Mejoras) == "table" then
			for id, nivel in pairs(guardado.Mejoras) do
				if type(nivel) == "number" then
					perfil.Mejoras[id] = math.max(perfil.Mejoras[id] or 0, nivel)
				end
			end
		end
		revisarNivel(player, perfil)
	end

	cargados[player] = true
	publicar(player)
end

local function guardar(player)
	local perfil = perfiles[player]
	if not store or not cargados[player] or not perfil then
		return
	end

	local copia = { Mejoras = table.clone(perfil.Mejoras) }
	for _, campo in ipairs(CAMPOS) do
		copia[campo] = perfil[campo]
	end

	local exito, err = pcall(function()
		store:SetAsync(clave(player), copia)
	end)
	if not exito then
		warn("[Datos] No se pudieron guardar los datos de " .. player.Name .. ": " .. tostring(err))
	end
end

local function alEntrar(player)
	if perfiles[player] then
		return
	end
	perfiles[player] = perfilNuevo()

	local tabla = Instance.new("Folder")
	tabla.Name = "leaderstats"
	for _, campo in ipairs(EN_TABLA) do
		local valor = Instance.new("IntValue")
		valor.Name = campo
		valor.Parent = tabla
	end
	tabla.Parent = player

	publicar(player)
	cargar(player)
end

function Datos.iniciar()
	Players.PlayerAdded:Connect(alEntrar)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(alEntrar, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		guardar(player)
		perfiles[player] = nil
		cargados[player] = nil
	end)

	-- Guardado automático por si el servidor se cae
	task.spawn(function()
		while true do
			task.wait(GUARDAR_CADA)
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(guardar, player)
			end
		end
	end)

	-- Al cerrar el servidor, guardar a todos antes de que se apague
	game:BindToClose(function()
		local pendientes = 0
		for _, player in ipairs(Players:GetPlayers()) do
			pendientes += 1
			task.spawn(function()
				guardar(player)
				pendientes -= 1
			end)
		end
		local inicio = os.clock()
		while pendientes > 0 and os.clock() - inicio < 25 do
			task.wait(0.1)
		end
	end)
end

return Datos
