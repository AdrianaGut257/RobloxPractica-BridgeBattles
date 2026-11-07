local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- En Studio sin acceso a la API esto falla: el juego sigue funcionando, solo que no guarda.
local exito, datastore = pcall(function()
	return DataStoreService:GetDataStore(Config.NOMBRE_DATASTORE)
end)
if not exito then
	warn("[PlayerData] No se puede guardar el progreso: " .. tostring(datastore))
	datastore = nil
end

-- Solo guardamos a los jugadores cuyos datos se cargaron bien,
-- para no borrar su progreso si la carga falló.
local cargados = {}

local function clave(player)
	return "jugador_" .. player.UserId
end

local function alEntrar(player)
	if player:FindFirstChild("leaderstats") then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local bloques = Instance.new("IntValue")
	bloques.Name = "Bloques"
	bloques.Parent = leaderstats

	local victorias = Instance.new("IntValue")
	victorias.Name = "Victorias"
	victorias.Parent = leaderstats

	leaderstats.Parent = player
	print(player.Name .. " se unió")

	if not datastore then
		return
	end

	local ok, datos = pcall(function()
		return datastore:GetAsync(clave(player))
	end)

	if not ok then
		warn("[PlayerData] No se pudieron cargar los datos de " .. player.Name .. ": " .. tostring(datos))
		return
	end

	if type(datos) == "table" then
		bloques.Value += datos.Bloques or 0
		victorias.Value += datos.Victorias or 0
	end
	cargados[player] = true
end

local function guardar(player)
	if not datastore or not cargados[player] then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local datos = {
		Bloques = leaderstats.Bloques.Value,
		Victorias = leaderstats.Victorias.Value,
	}

	local ok, err = pcall(function()
		datastore:SetAsync(clave(player), datos)
	end)
	if not ok then
		warn("[PlayerData] No se pudieron guardar los datos de " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(alEntrar)

-- Por si algún jugador entró antes de que este script empezara (pasa en Studio).
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(alEntrar, player)
end

Players.PlayerRemoving:Connect(function(player)
	guardar(player)
	cargados[player] = nil
end)

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
