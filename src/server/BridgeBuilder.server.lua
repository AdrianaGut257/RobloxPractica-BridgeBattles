-- El estado del juego se publica como atributos en ReplicatedStorage para que el HUD lo lea:
-- Estado, Progreso, Objetivo, Ronda, TiempoRestante, HayMeta.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local growingBlocks = workspace:WaitForChild("GrowingBlocks")

local mensaje = ReplicatedStorage:FindFirstChild("Mensaje")
if not mensaje then
	mensaje = Instance.new("RemoteEvent")
	mensaje.Name = "Mensaje"
	mensaje.Parent = ReplicatedStorage
end

local COLOR_AVISO = Color3.fromRGB(255, 230, 90)
local COLOR_VICTORIA = Color3.fromRGB(120, 255, 140)

local function avisarTodos(texto, color)
	mensaje:FireAllClients(texto, color or COLOR_AVISO)
end

local function avisar(player, texto, color)
	mensaje:FireClient(player, texto, color or COLOR_AVISO)
end

local function sumar(player, nombre, cantidad)
	local leaderstats = player:FindFirstChild("leaderstats")
	local valor = leaderstats and leaderstats:FindFirstChild(nombre)
	if valor then
		valor.Value += cantidad
	end
end

local columnas = {}
for i = 1, Config.MAX_COLUMNAS do
	local base = growingBlocks:FindFirstChild(Config.PREFIJO_COLUMNA .. i)
	if base and base:IsA("BasePart") then
		table.insert(columnas, { base = base, ultimo = base.CFrame })
	end
end

if #columnas == 0 then
	warn("[BridgeBuilder] No hay bloques llamados " .. Config.PREFIJO_COLUMNA .. "1, "
		.. Config.PREFIJO_COLUMNA .. "2, ... dentro de GrowingBlocks.")
end

local estado = "Construyendo"
local progreso = 0
local objetivo = #columnas * Config.LARGO_PUENTE
local ronda = 1
local siguienteColumna = 1

local function publicarEstado()
	ReplicatedStorage:SetAttribute("Estado", estado)
	ReplicatedStorage:SetAttribute("Progreso", progreso)
	ReplicatedStorage:SetAttribute("Objetivo", objetivo)
	ReplicatedStorage:SetAttribute("Ronda", ronda)
end

local meta = workspace:FindFirstChild(Config.NOMBRE_META, true)
if meta and not meta:IsA("BasePart") then
	warn("[BridgeBuilder] '" .. Config.NOMBRE_META .. "' debe ser una Part para poder usarla como meta.")
	meta = nil
end
ReplicatedStorage:SetAttribute("HayMeta", meta ~= nil)

local ganadores = {}
local confeti
local colorMetaOriginal, materialMetaOriginal

if meta then
	colorMetaOriginal = meta.Color
	materialMetaOriginal = meta.Material

	confeti = Instance.new("ParticleEmitter")
	confeti.Enabled = false
	confeti.Rate = 120
	confeti.Lifetime = NumberRange.new(1.5, 2.5)
	confeti.Speed = NumberRange.new(25, 40)
	confeti.SpreadAngle = Vector2.new(35, 35)
	confeti.Acceleration = Vector3.new(0, -35, 0)
	confeti.Rotation = NumberRange.new(0, 360)
	confeti.RotSpeed = NumberRange.new(-200, 200)
	confeti.Size = NumberSequence.new(0.5)
	confeti.EmissionDirection = Enum.NormalId.Top
	confeti.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 85, 85)),
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 230, 120)),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 220)),
	})
	confeti.Parent = meta
end

local function activarMeta(activa)
	if not meta then
		return
	end
	if activa then
		meta.Color = Color3.fromRGB(255, 200, 40)
		meta.Material = Enum.Material.Neon
	else
		meta.Color = colorMetaOriginal
		meta.Material = materialMetaOriginal
	end
end

local function lanzarConfeti()
	if not confeti then
		return
	end
	confeti.Enabled = true
	task.delay(0.5, function()
		confeti.Enabled = false
	end)
end

local function todosLlegaron()
	local jugadores = Players:GetPlayers()
	if #jugadores == 0 then
		return false
	end
	for _, player in ipairs(jugadores) do
		if not ganadores[player] then
			return false
		end
	end
	return true
end

local ultimoAvisoMeta = {}

if meta then
	meta.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		if estado ~= "Cruzando" then
			-- Llegó antes de terminar el puente (por ejemplo, saltando)
			local ahora = os.clock()
			if not ultimoAvisoMeta[player] or ahora - ultimoAvisoMeta[player] > 4 then
				ultimoAvisoMeta[player] = ahora
				avisar(player, "¡Primero hay que terminar el puente!")
			end
			return
		end

		if ganadores[player] then
			return
		end
		ganadores[player] = true

		sumar(player, "Victorias", 1)
		lanzarConfeti()
		avisarTodos("¡" .. player.DisplayName .. " llegó a la meta!", COLOR_VICTORIA)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	ganadores[player] = nil
	ultimoAvisoMeta[player] = nil
end)

local function reiniciarRonda()
	estado = "Reiniciando"
	publicarEstado()

	for _, parte in ipairs(growingBlocks:GetChildren()) do
		if parte:GetAttribute("Extra") then
			parte:Destroy()
		end
	end
	for _, columna in ipairs(columnas) do
		columna.ultimo = columna.base.CFrame
	end

	siguienteColumna = 1
	progreso = 0
	ganadores = {}
	activarMeta(false)

	-- Todos vuelven al inicio (los que estaban del otro lado se quedarían atrapados)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			player:LoadCharacter()
		end)
	end

	ronda += 1
	estado = "Construyendo"
	publicarEstado()
	avisarTodos("Ronda " .. ronda .. ": ¡a construir el puente otra vez!")
end

local function cuentaRegresiva(segundos, terminarAntes)
	for t = segundos, 1, -1 do
		ReplicatedStorage:SetAttribute("TiempoRestante", t)
		if terminarAntes and terminarAntes() then
			task.wait(2) -- un momento para celebrar
			break
		end
		task.wait(1)
	end
	ReplicatedStorage:SetAttribute("TiempoRestante", 0)
end

local function puenteTerminado()
	estado = "Cruzando"
	publicarEstado()

	if meta then
		activarMeta(true)
		avisarTodos("¡Puente terminado! Crucen hasta la META", COLOR_VICTORIA)
		cuentaRegresiva(Config.TIEMPO_PARA_CRUZAR, todosLlegaron)
	else
		for _, player in ipairs(Players:GetPlayers()) do
			sumar(player, "Victorias", 1)
		end
		avisarTodos("¡Puente terminado! +1 victoria para todos", COLOR_VICTORIA)
		cuentaRegresiva(Config.TIEMPO_CELEBRACION)
	end

	reiniciarRonda()
end

local entregar -- se define más abajo; agregarBloque la necesita antes

local function agregarBloque(columna)
	local base = columna.base
	local destino = columna.ultimo * CFrame.new(base.Size.X, 0, 0)

	local nuevo = Instance.new("Part")
	nuevo.Name = base.Name .. "_extra"
	nuevo.Size = base.Size
	nuevo.Color = base.Color
	nuevo.Material = base.Material
	nuevo.Anchored = true
	nuevo.TopSurface = Enum.SurfaceType.Smooth
	nuevo.BottomSurface = Enum.SurfaceType.Smooth
	nuevo:SetAttribute("Extra", true)

	nuevo.CFrame = destino * CFrame.new(0, 4, 0)
	nuevo.Transparency = 0.6
	nuevo.Parent = growingBlocks
	TweenService:Create(nuevo, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = destino,
		Transparency = base.Transparency,
	}):Play()

	nuevo.Touched:Connect(entregar)
	columna.ultimo = destino
end

entregar = function(hit)
	if estado ~= "Construyendo" or #columnas == 0 then
		return
	end

	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local carriedBlock = character:FindFirstChild("CarriedBlock")
	if not carriedBlock then
		return
	end
	carriedBlock:Destroy()

	agregarBloque(columnas[siguienteColumna])
	siguienteColumna += 1
	if siguienteColumna > #columnas then
		siguienteColumna = 1
	end

	progreso += 1
	sumar(player, "Bloques", 1)
	publicarEstado()

	if progreso >= objetivo then
		task.spawn(puenteTerminado)
	end
end

for _, bloque in ipairs(growingBlocks:GetChildren()) do
	if bloque:IsA("BasePart") then
		bloque.Touched:Connect(entregar)
	end
end

publicarEstado()
